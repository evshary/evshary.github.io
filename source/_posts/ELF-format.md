---
title: 關於ELF的兩三事
date: 2018-05-06 15:22:27
categories:
- 軟體開發
tags:
- GNU tool
---
# 簡介
程式設計師很大的機率是脫離不了Linux，而如果我們要在Linux上compile，大概一定會接觸到ELF這個格式。底下來簡單介紹一下ELF的格式是什麼，我們要怎麼從它獲得資訊。

ELF全名是Executable and Linking Format，在Linux中是編譯後的binary、object檔規範，也就是說我們從source code編譯後產生的檔案格式就是ELF了。

ELF的格式可以從兩種角度來看，第一種是Link的時候，第二種是執行的時候。兩者都一樣會有ELF header，但是底下的組成概念就完全不一樣。

Link的時候：

| ELF header |
| - |
| Program Header Table(Optional) |
| Section 1 |
| Section 2 |
| ... |
| Section N |
| Section Header Table |

執行的時候：

| ELF header |
| - |
| Program Header Table |
| Segment 1 |
| Segment 2 |
| ... |
| Segment N |
| Section Header Table(Optional) |

兩者最大的差異是Link的時候是以Section為觀點，用Section Header Table來當索引，指向各個Section。執行的時候則是用Segment為觀點，一個Segment可能是多個Section所組成，然後再用Program Header Table指向各個Segment。

# 觀察ELF的方法
那要如何觀察ELF呢？如果你嘗試用記事本打開應該只會看到一團不知所云的亂碼，所以我們底下會透過各種工具的使用教學來解釋ELF格式。

## 查看執行檔 - od
首先我們可以試著使用od這個指令來看檔案內容。od全名是octal dump，顧名思義就是用八進制來印內容，但他並不僅僅如此而已。

od指令的格式：`od -t [顯示格式] -A [偏移量使用的基數] [filename]`

* -t：後面可接型態(d, o, x...)、一次顯示的byte數(數字)、是否顯示ASCII code(z)
* -A：偏移量有(d, o, x, n)，n代表不顯示偏移量
* -v：不省略重複的內容

我們最常用格式：
* `od -t x1 -A x [filename]`：代表用16進制來顯示檔案，偏移量是16的倍數
* `od -t x1z -A x [filename]`：同上，但是多加上顯示ASCII code

那我們來看看ELF檔長什麼樣子，這邊以大家最常用的ls為例
```
$ od -t x1z -A x /bin/ls | less
000000 7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00  >.ELF............<
000010 02 00 3e 00 01 00 00 00 90 48 40 00 00 00 00 00  >..>......H@.....<
000020 40 00 00 00 00 00 00 00 00 a7 01 00 00 00 00 00  >@...............<
....
```

可以看到前面有個`7f 45 4c 46`開頭，ASCII是`.ELF`(.代表非可見字元，這邊是0x7f也就是\177)，這個就是傳說中的ELF magic code了。不過這邊先停一下，如果我們要繼續用hex來看其實有點累，所以先換個工具來試試吧！

## 使用readelf來觀察ELF資訊
readelf很明顯就是觀察ELF檔案的專門工具，使用方式如下

* 格式：`readelf [選項] [filename]`
* 讀取標頭選項
  - -h：印 ELF header
  - -l：印 Program Header Table
  - -S：印 Section Header Table
  - -e：三者都印
* 讀取資訊選項
  - -s：符號表
  - -r：蟲定位資訊
* 特別：
  - -a：所有標頭資訊全部印出
  - -xn：先用-S看要查看的Section數字，然後n填上該數字就可以hexdump那個section

那我們來看看ls的ELF header長什麼樣。從下面可以看到，除了剛剛看到的Magic code外，還有版本、適用哪個OS/ABI、在哪個機器平台運行、entry point adddress等等。

值得注意的是這邊有紀錄Program Header、Section Header的開始位址、大小、數量，所以我們可以用這個資訊找到Program/Section Header。
```
$ readelf -h /bin/ls
ELF 檔頭：
  魔術位元組：   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
  類別:                              ELF64
  資料:                              2 的補數，小尾序(little endian)
  版本:                              1 (current)
  OS/ABI:                            UNIX - System V
  ABI 版本:                          0
  類型:                              EXEC (可執行檔案)
  系統架構:                          Advanced Micro Devices X86-64
  版本:                              0x1
  進入點位址：               0x404890
  程式標頭起點：          64 (檔案內之位元組)
  區段標頭起點：          108288 (檔案內之位元組)
  旗標：             0x0
  此標頭的大小：       64 (位元組)
  程式標頭大小：       56 (位元組)
  Number of program headers:         9
  區段標頭大小：         64 (位元組)
  區段標頭數量：         28
  字串表索引區段標頭： 27
```

而Program Header的部分，我們可以看到有9個Segement，以及實際的位址在哪。另外有個「區段到節區映射中」(Section to Segment mapping)，這就是多個Section如何組成一個Segment的對應。

```
$ readelf -l /bin/ls
Elf 檔案類型為 EXEC (可執行檔案)
進入點 0x404890
共有 9 個程式標頭，開始於偏移量 64

程式標頭：
  類型           偏移量             虛擬位址           實體位址
                 檔案大小          記憶大小              旗標   對齊
  PHDR           0x0000000000000040 0x0000000000400040 0x0000000000400040
                 0x00000000000001f8 0x00000000000001f8  R E    8
  INTERP         0x0000000000000238 0x0000000000400238 0x0000000000400238
                 0x000000000000001c 0x000000000000001c  R      1
      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
  LOAD           0x0000000000000000 0x0000000000400000 0x0000000000400000
                 0x0000000000019d44 0x0000000000019d44  R E    200000
  LOAD           0x0000000000019df0 0x0000000000619df0 0x0000000000619df0
                 0x0000000000000804 0x0000000000001570  RW     200000
  DYNAMIC        0x0000000000019e08 0x0000000000619e08 0x0000000000619e08
                 0x00000000000001f0 0x00000000000001f0  RW     8
  NOTE           0x0000000000000254 0x0000000000400254 0x0000000000400254
                 0x0000000000000044 0x0000000000000044  R      4
  GNU_EH_FRAME   0x000000000001701c 0x000000000041701c 0x000000000041701c
                 0x000000000000072c 0x000000000000072c  R      4
  GNU_STACK      0x0000000000000000 0x0000000000000000 0x0000000000000000
                 0x0000000000000000 0x0000000000000000  RW     10
  GNU_RELRO      0x0000000000019df0 0x0000000000619df0 0x0000000000619df0
                 0x0000000000000210 0x0000000000000210  R      1

 區段到節區映射中:
  節區段...
   00
   01     .interp
   02     .interp .note.ABI-tag .note.gnu.build-id .gnu.hash .dynsym .dynstr .gn                                   u.version .gnu.version_r .rela.dyn .rela.plt .init .plt .text .fini .rodata .eh_                                   frame_hdr .eh_frame
   03     .init_array .fini_array .jcr .dynamic .got .got.plt .data .bss
   04     .dynamic
   05     .note.ABI-tag .note.gnu.build-id
   06     .eh_frame_hdr
   07
   08     .init_array .fini_array .jcr .dynamic .got
```

Section Header的話會仔細列出這個ELF所包含的所有Section以及位址。

```
$ readelf -S /bin/ls

共有 28 個區段標頭，從偏移量 0x1a700 開始：

區段標頭：
  [號] 名稱              類型             位址              偏移量
       大小              全體大小         旗標   連結  資訊  對齊
  [ 0]                   NULL             0000000000000000  00000000
       0000000000000000  0000000000000000           0     0     0
  [ 1] .interp           PROGBITS         0000000000400238  00000238
       000000000000001c  0000000000000000   A       0     0     1
  [ 2] .note.ABI-tag     NOTE             0000000000400254  00000254
       0000000000000020  0000000000000000   A       0     0     4
  [ 3] .note.gnu.build-i NOTE             0000000000400274  00000274
       0000000000000024  0000000000000000   A       0     0     4
  [ 4] .gnu.hash         GNU_HASH         0000000000400298  00000298
       0000000000000068  0000000000000000   A       5     0     8
...
  [24] .data             PROGBITS         000000000061a3a0  0001a3a0
       0000000000000254  0000000000000000  WA       0     0     32
  [25] .bss              NOBITS           000000000061a600  0001a5f4
       0000000000000d60  0000000000000000  WA       0     0     32
  [26] .gnu_debuglink    PROGBITS         0000000000000000  0001a5f4
       0000000000000008  0000000000000000           0     0     1
  [27] .shstrtab         STRTAB           0000000000000000  0001a5fc
       00000000000000fe  0000000000000000           0     0     1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), l (large)
  I (info), L (link order), G (group), T (TLS), E (exclude), x (unknown)
  O (extra OS processing required) o (OS specific), p (processor specific)
```

## objdump取得ELF內容
除了看ELF內的資訊外，我們可以進一步得到更細的資訊，包括dump內容和反組譯程式，這時候就要用objdump了

* `objdump -s -j [section] [filename]`：把特定section dump出來
* `objdump -h [filename]`：看有哪些section，跟readelf功用類似
* `objdump -x [filename]`：把所有section都顯示出來
* `objdump -d [filename]`：反組譯程式
* `objdump -d -S [filename]`：反組譯程式加上行數
* `objdump -d -l [filename]`：反組譯程式加上source code

同樣以ls為例，可以看到我們把text section的內容印出來了

```
$ objdump -s -j .text /bin/ls

/bin/ls：     檔案格式 elf64-x86-64

Contents of section .text:
 4028a0 50b9882c 4100baa6 0e0000be 36374100  P..,A.......67A.
 4028b0 bf983c41 00e896fb ffff660f 1f440000  ..<A......f..D..
 4028c0 41574156 41554154 554889f5 5389fb48  AWAVAUATUH..S..H
....
```

## objcopy/strip修改ELF檔案
objcopy最主要的功能就是可以把文件作轉換，一部份或全部的內容copy另一個文件中

* `objcopy -S -R .comment -R .note [input filename] [output filename]`：把編譯出來的symbol移除不必要的section(-S代表去掉symbol, relocation的訊息)
* `objcopy -O binary -j [section] [input filename] [output filename]`：也可以把某個section拿出來

關於移除不必要的section部分，其實strip就可以做到了，只要用`strip [filename]`即可。

### objcopy進階用法
objcopy可以做到把檔案變成ELF格式，提供給我們linking，這樣我們就可以避免檔案的讀取。

這邊用個簡單的範例，假設我們想要把某個文字檔包在程式內部(其實可以用圖片比較有感覺，只是我不想寫太複雜的程式)

先創立text.txt
```
This is test txt.
```

然後把text.txt變成object file
```
objcopy -I binary -O elf64-x86-64 -B i386:x86-64 text.txt text.o
```

如果這時候show object資訊的話
```
$ objdump -x text.o

text.o：     檔案格式 elf64-x86-64
text.o
系統架構：i386:x86-64， 旗標 0x00000010：
HAS_SYMS
起始位址 0x0000000000000000

區段：
索引名稱          大小      VMA               LMA               檔案關閉 對齊
  0 .data         00000012  0000000000000000  0000000000000000  00000040  2**0
                  CONTENTS, ALLOC, LOAD, DATA
SYMBOL TABLE:
0000000000000000 l    d  .data  0000000000000000 .data
0000000000000000 g       .data  0000000000000000 _binary_test_txt_start
0000000000000012 g       .data  0000000000000000 _binary_test_txt_end
0000000000000012 g       *ABS*  0000000000000000 _binary_test_txt_size
```

symsymbola把下面那些symbol放入test.c內，即可使用
```
#include <stdlib.h>

extern char _binary_text_txt_start[];
extern char _binary_text_txt_end[];
extern char _binary_text_txt_size[];

int main()
{
    char *ptr = _binary_text_txt_start;
    printf("text.txt=%s\r\n", ptr);
    return 0;
}
```

編譯並執行
```
$ gcc test.o test.o -o a.out
% ./a.out
text.txt=This is test txt.

```

## nm觀察symbol
剛剛提了那麼多都是以ELF內的各種section為主，但是我們實際開發程式其實還是比較重視symbol，那我們有簡單方式可以看symbol嗎？這時候就要用到nm了。

* `nm [filename]`：可以顯示symbol的數值、型態、名稱
* `nm --size-sort -r -S [filename]`：由大到小顯示symbol的數值、大小、型態、名稱

舉個例子，我們可以看到下面執行結果symbol由大到小排序
```
$ nm --size-sort -r -S test
00008464 00000064 T __libc_csu_init
00008444 00000020 T main
000084c8 00000004 T __libc_csu_fini
000084d4 00000004 R _IO_stdin_used
00011028 00000001 b completed.9228

```

關於常見型態的部分可參考下表：

| Section | 類型(大寫代表global、小寫是local) |
| - | - |
| text section | T/t |
| data section | D/d |
| Read only | R/r |
| BSS | B/b |
| 未定義(如extern) | U |

# addr2line從位址轉成symbol
有時候我們執行程式會只知道位址，但是想要從位址得到到底是在程式哪行掛掉

* `addr2line -f -e [filename] [address]`：-f代表要顯示是哪個function，-e代表address是來自該執行檔

# 總結
本篇文章主要簡單介紹ELF的結構，然後我們可以用 od、readelf、objdump、objcopy/strip、nm, addr2line 幾個工具觀察ELF的格式。如果想要有進一步的認識，建議可以研究參考的連結。

# 參考
* [BINARY HACKS：駭客秘傳技巧一百招](http://www.books.com.tw/products/0010587783)
* [陳鍾誠的網站 - 目的檔格式 (ELF)](http://ccckmit.wikidot.com/lk:elf)
* [ELF 格式解析](https://paper.seebug.org/papers/Archive/refs/elf/Understanding_ELF.pdf)
* [objcopy给目标文件设计一个段](https://blog.csdn.net/xzongyuan/article/details/21082959)
