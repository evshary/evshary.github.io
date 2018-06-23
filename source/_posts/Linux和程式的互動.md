---
title: Linux和程式的互動
date: 2018-06-12 19:37:27
categories:
- 軟體開發
tags:
- GNU tool
---
# 簡介
這篇我們想要來探討 Linux 是怎麼和程式互動的，這邊包括兩個部分：Linux 如何執行程式以及程式如何讓 Linux 做系統操作。

# 程式如何執行main
一般要呼叫程式來執行的，我們知道的是只要在 shell 下類似`./a.out`的指令，程式就會執行我們程式中的 main，但是這其中的原理是什麼呢？讓我們看看到執行 main 前做了哪些事。

下面例子我們以Kernel v4.17為例

1. 首先 shell 會 fork 一個 process，然後再呼叫 exec 系列函數把該 process 置換成指定的程式
2. execve 會呼叫 do_execve ，然後再呼叫 do_execveat_common，可參考[fs/exec.c的1856行](https://elixir.bootlin.com/linux/v4.17/source/fs/exec.c#L1856)
```c
int do_execve(struct filename *filename,
	const char __user *const __user *__argv,
	const char __user *const __user *__envp)
{
	struct user_arg_ptr argv = { .ptr.native = __argv };
	struct user_arg_ptr envp = { .ptr.native = __envp };
	return do_execveat_common(AT_FDCWD, filename, argv, envp, 0);
}
```
3. 接著do_execveat_common會讀取struct linux_binprm，並且根據檔案格式尋找適合的binary header
```c
static int do_execveat_common(int fd, struct filename *filename,
			      struct user_arg_ptr argv,
			      struct user_arg_ptr envp,
			      int flags)
{
...
    // 重要的structure，保留執行檔的相關訊息
	struct linux_binprm *bprm;
...
    // 打開要執行的ELF檔
	file = do_open_execat(fd, filename, flags);
...
    // 生成mm_struct，供執行檔使用
	retval = bprm_mm_init(bprm);
	if (retval)
		goto out_unmark;
    // 計算帶入的參數
	bprm->argc = count(argv, MAX_ARG_STRINGS);
	if ((retval = bprm->argc) < 0)
		goto out;
...
    // 讀取 header
	retval = prepare_binprm(bprm);
...
    // 裡面會呼叫 search_binary_handler，根據檔案格式呼叫適合的binary_handler
	retval = exec_binprm(bprm);
...
}
```
4. ELF的binary handler位在[fs/binfmt_elf.c的690行](https://elixir.bootlin.com/linux/v4.17/source/fs/binfmt_elf.c#L690)，做了header確認後會load program header和設定並執行elf_interpreter
```c
static int load_elf_binary(struct linux_binprm *bprm)
{
...
    // 讀取program header
	elf_phdata = load_elf_phdrs(&loc->elf_ex, bprm->file);
...
    // 讀取elf_interpreter
    retval = kernel_read(bprm->file, elf_interpreter,
                    elf_ppnt->p_filesz, &pos);
    // 把當前程式資訊清除並換上新的程式
    retval = flush_old_exec(bprm);
...
    current->mm->end_code = end_code;
	current->mm->start_code = start_code;
	current->mm->start_data = start_data;
	current->mm->end_data = end_data;
	current->mm->start_stack = bprm->p;
...
    // 執行elf_interpreter
    start_thread(regs, elf_entry, bprm->p);
...
}
```
5. 經過Context Switch後，應該會從elf_interpreter執行，通常應該會是/lib/ld-x.x.so。ld-x.x.so的進入點是_start，最後會連結到[glibc/elf/rtld.c](https://code.woboq.org/userspace/glibc/elf/rtld.c.html)的_dl_start，針對環境變數做處理。
  - 我們常見的LD_PRELOAD也是在這邊進行處理的
6. 當上述工作都做完後，就會進入 ELF binary 的`_start`，其中會呼叫 glibc 的[__libc_start_main](https://code.woboq.org/userspace/glibc/csu/libc-start.c.html)進行初始設定，最後就會呼叫main()
```c
result = main (argc, argv, __environ MAIN_AUXVEC_PARAM);
```

# 使用 system call
通常AP在Linux要跟kernel層互動大概只能透過system call，然而system call的使用大多數已經被包裝起來，所以幾乎不會看到，這邊我們來探討一下要怎麼在Linux直接呼叫system call。以下範例皆來自[BINARY HACKS：駭客秘傳技巧一百招](http://www.books.com.tw/products/0010587783)

## syscall
最簡單的呼叫system call方法是syscall。

syscall.c
```c
#include <stdio.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>

int main(void)
{
    int ret;
    ret = syscall(__NR_getpid);
    printf("ret=%d pid=%d\n", ret, getpid());
    return 0;
}
```
執行結果如下
```
$ make syscall
$ ./syscall
ret=18 pid=18
```
看起來是很順利取得PID。我們可以把__NR_getpid換成其他的system call數字，也可以達到同樣效果。

## int 0x80
當然我們也可以用`int 0x80`來做到同樣的事情，但是要注意的是這樣的效率不會比較好，可參考[What is better “int 0x80” or “syscall”?](https://stackoverflow.com/questions/12806584/what-is-better-int-0x80-or-syscall)

另外這個做法在x64的架構是無法被使用的，可參考[What happens if you use the 32-bit int 0x80 Linux ABI in 64-bit code?](https://stackoverflow.com/questions/46087730/what-happens-if-you-use-the-32-bit-int-0x80-linux-abi-in-64-bit-code)

syscall2.c
```
#include <stdio.h>
#include <sys/syscall.h>
#include <unistd.h>

int main(void)
{
    int ret;
    asm volatile ("int $0x80":"=a"(ret):"0"(__NR_getpid));
    printf("ret=%d pid=%d\n", ret, getpid());
    return 0;
}
```

## sysenter
這部分也是只能在x86的平台上使用，會出現這個機制的理由是int 0x80的效率實在太差了。這邊的使用方式有點複雜，就不列出來了。

## 比較
這三種方式的比較簡單統整一下

syscall：現在主流，能在x64運行
int 0x80：只能在x86，效率差，已被捨棄
sysenter：只能在x86，用來替代int 0x80

詳情可以參考[Linux系统调用机制int 0x80、sysenter/sysexit、syscall/sysret的原理与代码分析](https://www.jianshu.com/p/f4c04cf8e406)，寫得非常詳細。

# 參考
* [BINARY HACKS：駭客秘傳技巧一百招](http://www.books.com.tw/products/0010587783)
* [Linux系统ELF程序的执行过程](https://blog.csdn.net/eleven_xiy/article/details/77876702)
* [_dl_start源码分析](https://blog.csdn.net/conansonic/article/details/54236335)
* [Linux系统调用机制int 0x80、sysenter/sysexit、syscall/sysret的原理与代码分析](https://www.jianshu.com/p/f4c04cf8e406)