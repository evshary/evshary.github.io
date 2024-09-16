---
title: ARM CortexM3/4權限切換
date: 2018-12-02 15:04:44
categories:
- 技術
tags:
- ARM
---
# 簡介
最近我在研究怎麼在ARM Cortex M3/4上面跑一個自己寫的OS，最主要是參考jserv的[mini-arm-os](https://github.com/jserv/mini-arm-os)和[pikoRT](https://github.com/PikoRT/pikoRT)，相關程式碼放在[arm-os-4fun](https://github.com/evshary/arm-os-4fun)。
最近發現自己遇到了些問題，想說再研究怎麼解決的過程中順便把細節紀錄下，供自己未來可以參考。

這邊首先要探討的是Cortex M3/4上面有的權限模式，以及它們是怎麼進行切換等細節。
原本我是在qemu上面跑[STM32虛擬機](http://beckus.github.io/qemu_stm32/)，但是後來發現好像跟真實硬體有點不一致，所以後來我都在STM32F429的硬體上面來測試了。

# Cortex M權限設計
首先我們先了解Cortex上面有哪些權限模式，處理器上面有兩種Operation Modes：Thread mode和Handler mode。

* Thread Mode：一般程式運行的狀態。
* Handler Mode：處理exception的狀態。

然而除了這個以外，還有不同的Privilege Levels，避免一般使用者可以存取敏感資源。

* Privileged：可以存取所有資源，在CPU reset之後就是privileged。
* Unprivileged：通常是讓OS中userspace的程式運行用的，在幾個方面存取資源是受限的。
  - MSR、MRS指令存取上會有限制。
  - 無法存取system timer、NVIC。
  - 有些memory無法存取。

Operation Modes和Privilege Levels的關係如下所示，Unprivileged不能進入Handler Mode的。

| - | Privileged Level | Unprivileged Level |
| --- | --- | --- |
| Handler Mode | O(state1) | X |
| Thread Mode | O(state2) | O(state3) |

* 上面標註的state 1-3是為了方便我們後面講解而標的。

# 如何切換權限與模式
關於切換的部分可參考下圖，圖片來源[A tour of the Cortex-M3 Core](https://community.arm.com/processors/b/blog/posts/a-tour-of-the-cortex-m3-core)

![模式切換](https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-21-42/6470.handler_2D00_thread.PNG)

下面我們先看怎麼樣從state2,state3進入state1，也就是發生exception，然後再從state1回來。

## Exception Entry
進入exception有兩種情況：

1. 目前我們在thread mode
2. preempts：發生的exception比目前我們所在的exception權限還高

發生exception時，ARM會自動把當前的register的資訊存起來，順序為xPSR, PC, LR, R12, R3, R2, R1, R0。儲存的方式就是push到當前的stack中，可能是main stack(SP=MSP)，也可能是process stack(SP=PSP)。

| address | register |
| --- | --- |
| SP+00 | R0 <- SP after exception |
| SP+0x04 | R1 |
| SP+0x08 | R2 |
| SP+0x0C | R3 |
| SP+0x10 | R12 |
| SP+0x14 | LR |
| SP+0x18 | PC |
| SP+0x1C | xPSR |
| SP+0x20 | xxx <- SP before exception |

完成後接著會開始執行exception handler，並且把EXC_RETURN寫入LR。

## Exception Return
要從exception跳還必須要符合兩個條件：

1. 目前正在Handler Mode。
2. PC的值是合法的EXC_RETURN。

關於EXC_RETURN的值，其實代表了ARM從handler mode回去的路徑，有三種可能：

1. 目前是nested exception，回去上層還是handler mode。
2. 是由privileged thread mode呼叫的，也就是要回到state2。
3. 是由unprivileged thread mode呼叫的，也就是要回到state3。

因此EXC_RETURN有三個可能的值

| EXC_RETURN | Description |
| --- | --- |
| 0xFFFFFFF1 | Return to Handler mode.<br>Exception return gets state from the main stack.<br>Execution uses MSP after return. |
| 0xFFFFFFF9 | Return to Thread mode.<br>Exception Return get state from the main stack.<br>Execution uses MSP after return. |
| 0xFFFFFFFD | Return to Thread mode.<br>Exception return gets state from the process stack.<br>Execution uses PSP after return. |

## Privileged to Unprivileged
接著我們要來探討怎麼從Privileged進入Unprivileged，也就是state2進入state3的部分。

如果要進入Unprivileged，那必須使用到特殊register - control。

| bit | Description |
| --- | --- |
| CONTROL[1] | 0：Use MSP, 1: Use PSP |
| CONTROL[0] | 0：Privileged thread mode, 1：Unprivileged thread mode |

要特別注意操作control register一定要用MRS和MSR register
```
# CONTROL值搬到R0
MRS R0, CONTROL
# R0的值放入CONTROL
MSR CONTROL, R0
```
進入Unprivileged Thread Mode的操作
```
MOV R0, 3
MSR CONTROL, R0
```

# ARM在切換上面的設計
ARM在處理nested exception上有自己的一套做法來加快速度，確保高優先權的exception能更快被執行到，達到更高的即時性(real-time)。

下面介紹兩種在Cortex M上面的機制：

* tail-chained：
  - 情況：如果發生exception1的時候又發生exception2，但是exception2的優先權沒有高於exception1，必須等待。
  - 原本：一般來說exception1結束的時候會先pop stack，然後再push stack進入處理exception2。
  - 改進：exception1到exception2中間的pop&push其實是沒意義的，所以ARM Cortex M會在exception1結束後直接執行exception2，減少了中間的浪費。
* late-arriving
  - 情況：如果發生exception1並且執行state saving(上面說的push register)，這時候有更高優先權的exception2進來，發生preempts。
  - 原本：會中斷exception1的state saving，優先讓給exception2。
  - 改進：exception2其實也是需要state saving，所以繼續維持state saving，然後直接執行exception2。當exception2結束後，就又可以使用tail-chained的模式來執行exception1。

# 參考
關於Cortex M相關的資料非常推薦下面兩本書籍，都有中文的翻譯。JosephYiu有參與ARM Cortex M的設計，比較有權威性。

* [ARM Cortex-M3權威指南](https://www.books.com.tw/products/CN11146482)
* [ARM Cortex-M3與Cortex-M4權威指南, 3/e ARM Cortex-M3与Cortex-M4权威指南](https://www.tenlong.com.tw/products/9787302402923)

可參考jserv老師和學生撰寫的rtenv+簡介，裡面也有提到ARM CM3權限的部分。

* [rtenv+](http://wiki.csie.ncku.edu.tw/embedded/rtenv)