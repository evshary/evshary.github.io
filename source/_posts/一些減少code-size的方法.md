---
title: 一些減少code size的方法
date: 2019-08-03 16:39:40
categories:
- 技術
tags:
- 系統程式
---
# 前言
在開發嵌入式系統的時候，很常遇到需要在資源緊張的環境上進行開發，所謂的資源緊張大概不外乎memory不夠使用、flash不夠大，但是老闆或PM仍然希望RD在產品上面新增feature，這時候就只能針對code size進行優化了。我自己待的部門剛好就是遇到這種產品已經維護10年以上，可是又希望加新feature的狀況，因此開始尋找減少code size的方法，這邊分享一些我自己的心得。

# Compile Optimization
首先我們可以看一下compiler是不是已經做過優化了，大家都知道gcc在編譯的時候可以選擇optimization的level，從0-3。0代表的是default，而隨著數字越高，對code size和execution time的優化就越高。

大部分的人都會建議使用-O2，在code size和execution time取平衡，但是如果真的對code size十分在意的話，其實也可以使用-Os，代表的是-O2但是不包含部分會影響code size的優化。

到底每個optimization的level是做了那些優化，可參考[GCC的官方文件](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html)

# strip
strip算是最基本的降低code size工具，他會移除debug資訊(可供gdb使用的資訊)以及symbol table，因此size會降低許多。

這邊簡單做個實驗：

* 我們先寫個簡單程式：
```c
#include <stdio.h>
void func() {
    printf("func\n");
}

int main() {
    func();
    return 0;
}
```
* 接著來編譯，為了凸顯strip的效果，我們加上-g來加上gdb debug訊息
```
gcc -g test.c -o test
```
* 接著我們可以用`nm -a test`來看到他的symbol table
```
0000000000000000 a
0000000000201030 b .bss
0000000000201030 B __bss_start
0000000000000000 n .comment
....
```
* 以及用`objdump -h test`來看到有哪些section header，可以發現有許多debug資訊
```
...
 27 .debug_aranges 00000030  0000000000000000  0000000000000000  0000105d  2**0
                  CONTENTS, READONLY, DEBUGGING
 28 .debug_info   0000033a  0000000000000000  0000000000000000  0000108d  2**0
                  CONTENTS, READONLY, DEBUGGING
 29 .debug_abbrev 000000f6  0000000000000000  0000000000000000  000013c7  2**0
                  CONTENTS, READONLY, DEBUGGING
 30 .debug_line   000000d4  0000000000000000  0000000000000000  000014bd  2**0
                  CONTENTS, READONLY, DEBUGGING
 31 .debug_str    0000028a  0000000000000000  0000000000000000  00001591  2**0
                  CONTENTS, READONLY, DEBUGGING
...
```
* 接著執行`strip test`後，會發現symbol table已經消失了(無法使用nm)，以及沒有debug的section header。兩者size有極大差異。
```
> ls -al
-rwxrwxrwx 1 evshary evshary 11152 Aug  4 11:34 test
> strip test
> ls -al
-rwxrwxrwx 1 evshary evshary 6304 Aug  4 11:39 test
```

# objcopy
strip可以減少極大部分的code size，但是如果這樣還不夠的話，我們可以用objcopy把一些沒用到的section header移除掉，但是要提醒一下，這個移除幾乎不會影響太大，大概就幾百byte而已。

```
> objcopy -R .comment -R .note.ABI-tag -R .gnu.version test small_test
-> ls -al
-rwxrwxrwx 1 evshary evshary 6304 Aug  4 11:39 test
-rwxrwxrwx 1 evshary evshary 6024 Aug  4 11:45 small_test
```

這邊所謂的沒用到section header主要是一些環境的版本資訊，到底這些header代表什麼意思，可以參考[Linux Standard Base PDA Specification 3.0RC1 - Chapter 5. Special Sections](http://refspecs.linuxbase.org/LSB_3.0.0/LSB-PDA/LSB-PDA/specialsections.html)

# 利用 compile option 來移除沒用到的 symbol
我們知道程式裡面常常會有些程式碼(function/data)並沒有被人使用到，不論是因為長久maintain被修修改改，還是因為本身就有預留給未來使用。但是這些沒用到的功能如果都被編進去程式中其實是很浪費的，我們這邊可以用一些小手段來移除。

在gcc的編譯過程中我們可以加上特別的編譯參數`-fdata-sections`和`-ffunction-sections`，這兩個的意思是把每個symbol(function或data)獨立成不同的section。為什麼要這樣做呢？當然是為了後面在link的時候我們可以直接移除沒用到的section，在link的時候多加上`--gc-sections`參數即可。

細節可以參考[How to remove unused C/C++ symbols with GCC and ld?](https://stackoverflow.com/questions/6687630/how-to-remove-unused-c-c-symbols-with-gcc-and-ld)。

# 觀察 map file
map file是我們在編譯過程中很重要的一個工具，他可以用來檢視目前symbol的size有多大，我們可以用nm來取得symbol table，甚至根據symbol的size大小來排序(指令是`nm --size-sort -r -S [執行檔]`)。透過觀察map file，我們可以瞭解程式內部每個功能佔的大小為何，進一步思考有沒有優化的空間，甚至發現該功能根本是沒有在使用的。

我自己也曾經有遇過code size的問題，那時候我一樣是用nm來讀取map file，忽然發現某個變數大到不可思議，觀察了一下發現那個變數是直接用global的方式宣告，並不是要用的時候才malloc，導致在一般firmware運作的過程中那塊記憶體完全沒辦法被使用。更重要的是那個功能並不常被使用，而且還會隨著硬體平台有不一樣的大小，結果RD為了方便，直接保留可能會用到的最大值，造成空間的極度浪費。

# Remove debug message
其實RD在開發的過程中，或多或少都會留一些debug訊息，雖然少少的，但是累積起來量也是很驚人，畢竟一個debug訊息就是一個字串。在code size緊張的情況下，應該可以審視一下，看能不能把debug訊息移除。

值得注意的是有些embedded的firmware確實是會有關閉debug資訊的方式，但是這個有可能只是不顯示(例如關閉console顯示)，並不是真的移除，要仔細確認自己的狀況是哪種。

不過如果真的到了一定要移除debug訊息程式才能夠被使用的情況，這樣也挺危險的了，因為未來如果要maintain，必要的debug訊息還是逃不了。我會建議程式開發的過程中每個功能都可以自行決定要不要把debug的程式碼編進去，至少遇到bug還可以只開啟相關功能的debug訊息，而不是全部訊息都全開。

# 移除沒用到的功能(library)、檔案
在我們的embedded firmware裡面有些會需要使用SSL或SSH這種非常龐大的library，可能佔firmware的size超過1/3。像是這種library其實有很多功能是我們沒有用到的，以SSL、SSH來說，其實我們只會用到其中少部分的加密cipher，而不是全部。如果真要使用，建議要對library本身功能機制足夠熟悉，在編譯的時候只開用到的option即可。

除了library外，一個產品經過長時間的maintain，中間一定會有許多功能是後來沒用到，卻沒被移除的。如果只是程式碼倒還好，可以用前面提到的gc-section來排除，但是如果是file system的檔案，那就要靠自己來處理了。我個人的經驗是，有很多功能是過去產品有的，但是因為後來時代不符合被移除，結果相關檔案就都一直遺留下來，例如可在browser上面運作的java plugin等等，這些的size是也很可觀的。

# Compression
壓縮也是減少code size的其中一個方法，除了啟動的程式外，我們可以把runtime過程才要load的東西進行壓縮。通常這類的角色可以是kernel啟動完成後另外加載的AP，或是filesystem。不過壓縮要考慮的點就是壓縮率、解壓的程式碼的大小以及速度，最好可以在這其中之間取得平衡。壓縮率對我們來說就是可以把程式縮小到什麼地步，如果縮小不大就沒有意義了，然後解壓的部分也很重要，要是有很高壓縮率，但是解壓程式很大，那整體來說並沒有得到多高的效益。而如果壓縮率高，但解壓速度過慢，也會影響到使用者體驗，這些都需要考慮到。

filesystem的部分有點可以稍微注意一下，大部分的應用都是web居多，而web其實是有壓縮的空間，且不需另外解壓的。我們知道一般web都是由html、CSS、javascript所組成，而這些內容丟給browser的時候並不需要是人眼比較好閱讀的方式，例如說不需要換行、縮排等等。這麼一來我們就有可以動手腳的空間，可以在編譯過程中，把原始的檔案做壓縮，最後才變成file system，這樣的壓縮率是很可觀的。除了減少size外，這還帶來另外一個很大的好處就是減少網路流量的傳輸，特別在embedded system中系統效能其實都不快。提醒一下，記得開發過程使用git追蹤的web檔案最好是原始檔案(人眼好讀的)，編譯過程才壓縮，不然這只是給自己帶來開發的困擾而已。

web壓縮的方式網路上有很多，有些甚至提供online的服務，例如[HTMLCompressor](https://htmlcompressor.com/compressor/)或是[textfixer](https://www.textfixer.com/html/compress-html-compression.php)等等，可以自己尋找適合的工具。

# 結語
上面分享了許多方法，但最後我要先澄清一下，自己需要搞清楚到底不夠的是flash還是memory，上面的方法並不是做了兩個都一定會減少。舉個例子來說，移除沒有必要用到的大變數通常只會影響memory的使用率，因為compile出來firmware的size並沒有包括大變數(因為是bss section，未初始化區段)，而file system的壓縮通常也只會影響flash的使用率，除非firmware有把檔案預先從flash讀出來放在memory中。我想強調的是使用這些方法時，還是要有必備的系統觀以及對你的系統有一定熟悉程度。

老實說軟體開發者最討厭的大概就是被各種硬體條件所限制，然而這些在embedded的世界中還是有很大的機會會遇到，特別是考量到成本的時候。雖然很討厭這類的問題，但是解決後其實還是蠻有成就感的。以上分享希望能夠幫助大家解決code size issue。

# 參考
* [程式減肥三步走](http://linux.vbird.org/somepaper/20050117-jianfei.pdf)