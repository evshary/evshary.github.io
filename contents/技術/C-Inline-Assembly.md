---
title: C語言的行內組譯
date: 2018-05-20 15:02:39
categories:
- 技術
tags:
- 程式語言
- C
- GNU tool
---
## 簡介

有時候我們會在C的程式碼內看到`asm{...}`的結構，這代表的是行內組譯的概念，也就是在C語言中為了效率等目的直接要求compiler加入我們所指定組合語言。

舉個最簡單的範例，如果我們要求加入nop的指令，那就會變成如下：

```c
/* 一個nop指令 */
asm("nop");

/* 多行要用\n隔開 */
__asm__("nop\n"
        "nop\n");
```

不管是`asm`還是`__asm__`都是合法的，只要不要跟自己的symbol有衝突即可。

聰明的你可能發覺一件事，剛剛的例子只有指令而已，那如果假設我們要跟自己設定的變數互動那要怎麼辦呢？這時候就要用比較複雜的格式

```asm
asm ( assembler template               /* 組合語言內容 */
    : output operands                  /* 輸出的參數 */
    : input operands                   /* 輸入的參數 */
    : list of clobbered registers      /* 組合語言執行後會改變的項目 */
    );
```

## 範例

我們還是直接來看看程式比較有感覺

### 範例一

我們寫一個簡單的test.c，只負責做加法。

```c
#include <stdio.h>

int main()
{
    int sum, num1, num2;
    num1 = 1;
    num2 = 2;
    sum = num1 + num2;
    printf("sum=%d\r\n", sum);
    return 0;
}
```

編譯並且看一下組語的內容

```bash
$ gcc test.c -s test.s
$ cat test.s
        .file   "test.c"
        .text
        .section        .rodata
.LC0:
        .string "sum=%d\r\n"
        .text
        .globl  main
        .type   main, @function
main:
.LFB0:
        .cfi_startproc
        pushq   %rbp
        .cfi_def_cfa_offset 16
        .cfi_offset 6, -16
        movq    %rsp, %rbp
        .cfi_def_cfa_register 6
        subq    $16, %rsp
        movl    $1, -4(%rbp)
        movl    $2, -8(%rbp)
        movl    -4(%rbp), %edx
        movl    -8(%rbp), %eax
        addl    %edx, %eax
        movl    %eax, -12(%rbp)
        movl    -12(%rbp), %eax
        movl    %eax, %esi
        movl    $.LC0, %edi
        movl    $0, %eax
        call    printf
        movl    $0, %eax
        leave
        .cfi_def_cfa 7, 8
        ret
        .cfi_endproc
.LFE0:
        .size   main, .-main
        .ident  "GCC: (GNU) 8.1.0"
        .section        .note.GNU-stack,"",@progbits
```

先不管其他細節，可以看到中間有兩行`addl    %edx, %eax`和`movl    %eax, -12(%rbp)`，對應的也就是`sum = num1 + num2;`，那我們來改寫一下吧！

test.c

```c
#include <stdio.h>

int main()
{
    int sum, num1, num2;
    num1 = 1;
    num2 = 2;
    sum = num1 + num2;
    asm(
        "addl    %%edx, %%eax\n"
        :"=a"(sum)
        :"a"(num1), "d"(num2)
       );
    printf("sum=%d\r\n", sum);
    return 0;
}
```

編譯並執行後就會發現結果是一樣的。不過到這邊我想大部分的人心中一定充滿了三個小朋友，所以還是在稍微解釋一下。

如前面所提，我們最主要執行的是`addl    %%edx, %%eax\n`，這邊跟前面不一樣的是%另有用途(後面會提)，所以要表示暫存器%eax時，我們要用%%來取代%字元。
然後第二行的`"=a"(sum)`中，`=`代表執行結束後我們要把某個值填到某個變數內(這邊指的就是括號中的sum)，可是某個值又是怎麼決定的呢？這個就是a的概念，也就是「規範條件」，要求編譯器只能對應到符合條件的register。

如果以x86的架構為例(這邊要注意每個CPU架構的規範條件都不同)：

| 規範條件 | Register(s) |
| - | - |
| a |   %eax, %ax, %al   |
| b |   %ebx, %bx, %bl   |
| c |   %ecx, %cx, %cl   |
| d |   %edx, %dx, %dl   |
| S |   %esi, %si        |
| D |   %edi, %di        |
| f |   fp               |

由此可知就是要把%eax的結果填入sum中。同理，第三行的input部分`"a"(num1), "d"(num2)`分別也代表在執行組合語言前為num1和num2選擇register(這邊的例子是num1填入%eax、num2填入%edx)。

回頭看一下如果編成組合語言會是什麼樣子

```asm
...
        movl    $1, -4(%rbp)
        movl    $2, -8(%rbp)
        movl    -4(%rbp), %eax
        movl    -8(%rbp), %edx
#APP
# 8 "test.c" 1
        addl    %edx, %eax

# 0 "" 2
#NO_APP
        movl    %eax, -12(%rbp)
        movl    -12(%rbp), %eax
        movl    %eax, %esi
        movl    $.LC0, %edi
        movl    $0, %eax
        call    printf
....
```

在#APP和#NO_APP間就是我們的組語部分，看起來蠻符合我們的預期。

### 範例二

可是我們難道都一定要自行決定register嗎？我們想要交由compiler決定。這時候其實可以用比較寬鬆的限制條件。一樣是x86的架構才能用：

| 規範條件 | Register(s) |
| - | - |
| r | %eax, %ebx, %ecx, %edx, %esi, %edi |
| q | %eax, %ebx, %ecx, %edx |
| 0,1,2.. | %0, %1, %2...(代表第幾個參數) |

那就修改程式吧！

test.c

```c
...
    asm(
        "addl    %2, %0\n"
        :"=r"(sum)
        :"0"(num1), "r"(num2)
       );
...
```

在這裡，我們input使用sum和num2使用`r`，代表交由compiler決定要用哪個register。但是num1為什麼是0呢？這個意思是我們要num1的值所放入的register要跟sum同樣。
0,1,2分別代表我們所決定的register順序，也就是%0=>之後要輸出到sum的register，%1=>num1放入的register，%2=>num2放入的register。

當然最後執行結果也會和範例一一樣。

## 參考

* [BINARY HACKS：駭客秘傳技巧一百招](http://www.books.com.tw/products/0010587783)
* [在 C 語言當中內嵌 GNU 的組合語言](http://sp1.wikidot.com/gnuinlineassembly)
* [關於GNU Inline Assembly](http://wen00072.github.io/blog/2015/12/10/about-inline-asm/)
* [ARM GCC Inline Assembler Cookbook](http://www.ethernut.de/en/documents/arm-inline-asm.html)
* [GCC-Inline-Assembly-HOWTO](https://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html)
