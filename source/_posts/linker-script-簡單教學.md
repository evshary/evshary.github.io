---
title: linker script 簡單教學
date: 2018-06-02 15:56:33
categories:
- 軟體開發
tags:
- GNU tool
---
# 簡介
最近由於工作常常會用到，所以打算來談談如何來撰寫 linker script，也可以當作未來自己參考用途。

linker的作用就是把輸入檔(object file)的 section 整理到輸出檔的 section。除此之外也會定下每個object file 中尚未確定的符號位址，所以如果有 object file 用到不存在的symbol，就會出現常看到的 `undefined reference error`。

而 linker script 就是提供給 linker 參考的文件，它告訴 linker 我想要怎麼擺放這些 section，甚至也可以定義程式的起始點在哪邊。

# 簡單範例
最簡單的 linker script 是用`SECTIONS`指令去定義 section 的分佈。

test.ld
```
SECTIONS
{
. = 0x10000;
.text : { *(.text) }
. = 0x8000000;
.data : { *(.data) }
.bss : { *(.bss) }
}
```
在上例，`.`被稱作 location counter，代表的是指向現在的位址，我們可以讀取或是移動它 (我覺得可以想像成我們在打電腦文件時的游標，代表現在要處理這個位置)。

這段 script 主要做的事是，先把 location counter 移到 0x10000，在這裡寫入所有輸入檔的`.text section`後，再來移到0x8000000放所有輸入檔的`.data section`跟`.bss section`。

當然，最重要的還是去嘗試，所以讓我們來試試看，結果是不是真的像我們所想的。

main.c
```
void test(void);

int global_bss;
int global_data = 123;

int main()
{
    global_bss = 0;
    test();
    global_data++;
    return 0;
}
```

test.c
```
void test(void)
{
    int i;
    // do nothing.
    for (i = 0; i < 10000; i++);
}
```

嘗試編譯並看結果
```
$ gcc -c main.c test.c
$ ld -T test.ld main.o test.o
$ objdump -h a.out

a.out:     file format elf64-x86-64

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text         00000046  0000000000010000  0000000000010000  00010000  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .eh_frame     00000058  0000000000010048  0000000000010048  00010048  2**3
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  2 .data         00000004  0000000008000000  0000000008000000  00200000  2**2
                  CONTENTS, ALLOC, LOAD, DATA
  3 .bss          00000004  0000000008000004  0000000008000004  00200004  2**2
                  ALLOC
  4 .comment      00000011  0000000000000000  0000000000000000  00200004  2**0
                  CONTENTS, READONLY
```

我們可以看到在VMA和LMA的地方，text是從0x10000開始，data和bss則是從0x8000000開始放，跟我們所安排的結果一樣。

這邊說明一下，一定會有人覺得奇怪，為什麼編譯出來的檔案無法執行，這個是因為我們並沒有符合 Linux 可執行的格式來 link，如果你想要知道一般我們下 gcc 是使用什麼 linker script 的話，可以使用如下方式：

```
gcc -Wl,-verbose main.c test.c
```

這樣就可以看到所使用的 linker script 了。

# 常用的功能
接著我們來談談在linker script中常見到的功能，這邊我們可以參考 jserv 帶領成大同學開發的 rtenv 中的 [linker script](https://github.com/southernbear/rtenv/blob/master/main.ld)

那我們就一一了解每個符號的意義吧！

## ENTRY
用 ENTRY 可以指定程式進入點的符號，不設定的話 linker 會試圖用預設`.text`的起始點，或者用位址0的地方。

以 x86 為例，預設進入點是`ENTRY(_start)`，而 rtenv 則是設定為 `ENTRY(main)`

## MEMORY
Linker 預設會取用全部的記憶體，我們可以用 MEMORY 指令指定記憶體大小，在 rtenv 的例子中，指定了 FLASH 跟 RAM 兩種的輸出位置與大小

ORIGIN代表起始位置，LENGTH為長度
```
MEMORY
{
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 128K
  RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 20K
}
```
接下來SECTION部分，就能用 > 符號把資料寫到指定的位置
```
.bss : {
        _sbss = .;
        *(.bss)         /* Zero-filled run time allocate data memory */
        _ebss = .;
    } >RAM
```

## KEEP
KEEP 指令保留某個符號不要被 garbage collection ，例如我們不希望 ARM 的 ISR vector 會被優化掉。

```
.text :
    {
        KEEP(*(.isr_vector))
...
    }
```

## section 的本體
section 的指定方式是 linker script 中的重點，其中也有許多設定。

我們可以參考[官方文件](https://sourceware.org/binutils/docs/ld/Output-Section-Attributes.html#Output-Section-Attributes)先對 section 的功能做一個快速了解。

```
section [address] [(type)] :
  [AT(lma)]
  [ALIGN(section_align) | ALIGN_WITH_INPUT]
  [SUBALIGN(subsection_align)]
  [constraint]
  {
      output-section-command
      output-section-command
      ...
  } [>region] [AT>lma_region] [:phdr :phdr ...] [=fillexp]
```

output-section-command 代表的就是我們要怎麼擺放每個 section。

在這個例子裡可以看到有許多 LMA，除了 LMA 外，其實還有 VMA，它們兩個究竟有什麼不同呢？

### LMA/VMA 的概念
這裡大概是最重要的部分，也是之前我一直搞不清楚的地方。

link script 中設計了兩種位址：VMA 和 LMA

| | LMA (Load Memory Address) | VMA (Virtual Memory Address) |
| - | - | - |
| 位置 | ROM/Flash | RAM |
| 意義 | 程式碼保存的位置 | 程式碼執行的位址 |

也就是 LMA 是 output file 的位置，VMA 是載入 section 到 RAM 時的位置，但是在大多數情況下兩者會是一樣的。

我們再看看上例是怎如何指定 LMA 和 VMA 的

* LMA 是用`AT`或`AT>`來決定位址，為可選，沒指定就用VMA當LMA
  - `AT(LMA)`：告訴 linker 這個 section 應該要去哪個 LMA 載入資料到 VMA，要填 address
  - `AT>lma_region`：為 LMA 所在區域，需事先定義
* `>region`：為 VMA 所在區域，region需事先定義
* 在 linker script 的寫法基本上是這個架構`[VMA] : [AT(LMA)]`

繼續以 rtenv 為例，當指定了`_sidata`的 symbol 位置後，AT 就是要求載入到 FLASH 時要在`.text`的後面，換句話說`.data`的 LMA 要在`.text`後

```
/* Initialized data will initially be loaded in FLASH at the end of the .text section. */
.data : AT (_sidata)
{
  _sdata = .;
  *(.data)        /* Initialized data */
  *(.data*)
  _edata = .;
} >RAM
```

## 取得 section 的位置
在程式中，有時候可能還是會需要取得每個 section 的所在位址，我們可以用如下的方式取得
```
.text :
    {
        KEEP(*(.isr_vector))
         *(.text)
         *(.text.*)
        *(.rodata)
        *(.rodata*)
        _smodule = .;
        *(.module)
        _emodule = .;
        _sprogram = .;
        *(.program)
        _eprogram = .;
        _sromdev = .;
        *(.rom.*)
        _eromdev = .;
        _sidata = .;
    } >FLASH
```
上面的7個 symbol 分別代表開始和結束，例如`_smodule`代表 module 的開始，而`_emodule`則代表 module 的結束。

這樣的好處是 symbol 的部分我們可以在主程式這樣使用
```
extern uint32_t _sidata;
extern uint32_t _sdata;
extern uint32_t _edata;

uint32_t *idata_begin = &_sidata; 
uint32_t *data_begin = &_sdata; 
uint32_t *data_end = &_edata; 
while (data_begin < data_end) *data_begin++ = *idata_begin++;
```

值得注意的是，如果 C 已經有用到該變數`_sidata`，那就要用`PROVIDE(_sdata = .)`來避免 linker 出現重複定義的錯誤

## Stack 的位址
通常 stack 位址我們都會放在 RAM 的最下方讓他往上長，所以我們可以用下面表示方式：
```
_estack = ORIGIN(RAM) + LENGTH(RAM);
```
代表 stack 的放置位址是在 RAM 的最下方。


# 常見問題
## 如果section重複被使用，會發生什麼事？
每個輸入檔的 section 只能在出現在 SECTIONS 中出現一次。什麼意思呢？讓我們看個例子

```
SECTIONS {
.data : { *(.data) }
.data1 : { data.o(.data) }
}
```

我們可以看到`data.o`中的`.data section`應該在第一個 OUTPUT-SECTION-COMMAND (也就是`.data : { *(.data) }`)被用掉了，所以在`.data1 : { data.o(.data) }`將不會再次出現，代表的就是`.data1 section`會是空的。

## 如果只想要把某個library的.o放入的話
可用`*xxx.a:*yyy.o (.bss*)`的方式，舉例來說：
```
.bss_RAM2 : ALIGN(4)
    {
    	*libmytest.a:*.o (.bss*)
    	*(.bss.$RAM2*)
    	*(.bss.$RamLoc64*)
       . = ALIGN(4) ;
    } > RamLoc64
```

## 如果我不想要把特定檔案的section放入
可以使用`EXCLUDE_FILE`，例如我想放除了 foo.o、bar.o 外，所有的`.bss section`，可以這麼做：

```
(*(EXCLUDE_FILE (*foo.o *bar.o) .bss))
```

詳細可參考下方連結

* [linker script之EXCLUDE_FILE語法](http://forum.andestech.com/viewtopic.php?f=16&t=600)
* [Linker Script: Put a particular file at a later position](https://stackoverflow.com/questions/21418593/linker-script-put-a-particular-file-at-a-later-position)

# 參考
* [ld 官方文件](https://sourceware.org/binutils/docs/ld/)
* [Linker script 簡介](http://yodalee.blogspot.tw/2015/04/linker-script.html)
* [嵌入式系統建構：開發運作於STM32的韌體程式](http://wiki.csie.ncku.edu.tw/embedded/Lab19/stm32-prog.pdf)
* [Linker Script初探 - GNU Linker Ld手冊略讀](http://wen00072.github.io/blog/2014/03/14/study-on-the-linker-script/)
* [GNU ld的linker script簡介](https://www.slideshare.net/zzz00072/gnu-ldlinker-script)
* [Rtenv的linker Script解釋](http://wen00072.github.io/blog/2014/12/22/rtenv-linker-script-explained/)
* [stm32f429 Linker Script簡介](http://opass.logdown.com/posts/255812-introduction-to-stm32f429-linker-script)
