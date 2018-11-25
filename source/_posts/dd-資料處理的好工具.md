---
title: dd - 資料處理的好工具
date: 2018-11-25 18:27:45
categories:
- tools
tags:
---
# 簡介
dd全名叫做data duplicator，這個工具最主要的功能是對資料作複製、修改、備份，是一個很方便的小工具。通常Linux中預設都會有，不需要額外安裝。

# 使用教學
## 基本
* 輸入輸出參數
  - if=FILE：輸入名稱
  - of=FILE：輸出名稱

```
dd if=[input_file] of=[output_file]
```

## 轉換
* 做相對應的轉換`conv=CONVS`
  - lcase：大寫字母換小寫
  - ucase：小寫字母換大寫
  - nocreat：不要建立輸出檔案
  - notrunc：input小於output時，仍維持output大小
  - fdatasync：讓資料同步寫入硬碟

```
# 轉為小寫
dd if=[input_file] of=[output_file] conv=lcase
```

## 區塊
* bs=[bytes]：等同於同時設定ibs和obs，一次讀或寫的block size。
  - ibs=[bytes]：指定每次讀取的block size(default 512 bytes)
  - obs=[bytes]：指定每次寫入的block size(default 512 bytes)
* count=[number]：只處理前[number]輸入區塊，block size要參考ibs。
* seek=[number]：輸出檔案跳過前[number]個區塊，block size要參考obs。
* skip=[number]：輸入檔案跳過前[number]個區塊，block size要參考ibs。

# 常用指令
* 大小寫轉換
```
# 換大寫
dd if=[input] of=[output] conv=ucase
# 換小寫
dd if=[input] of=[output] conv=lcase
```
* 產生一個特定大小的檔案
```
# 內容為空的1KB檔案
dd if=/dev/zero of=[output] bs=1024 count=1
# 內容為亂數的1MB檔案
dd if=/dev/urandom of=[output] bs=1m count=1
```
* 把特定檔案的開頭512 byte清空
```
dd if=/dev/zero of=[output] bs=512 count=1 conv=notrunc
```
* 備份硬碟
```
dd if=[來源] of=[目標]
# 例如從/dev/sda備份到/dev/sdb
dd if=/dev/sda of=/dev/sdb
```
* 備份光碟，可參考[Create an ISO Image from a source CD or DVD under Linux](https://www.thomas-krenn.com/en/wiki/Create_an_ISO_Image_from_a_source_CD_or_DVD_under_Linux)
  1. 先觀察/dev/cdrom
```
isoinfo -d -i /dev/cdrom | grep -i -E 'block size|volume size'
```
  2. 然後應該會出現類似如下內容
```
Logical block size is: 2048
Volume size is: 327867
```
  3. 接著參考上面的數字使用dd指令(bs大部分都是2048，而count其實有加沒加都沒差)
```
dd if=/dev/cdrom of=test.iso bs=<block size from above> count=<volume size from above>
# 以上述例子
dd if=/dev/cdrom of=outputCD.iso bs=2048 count=327867
```
* 拆分&合併檔案，可參考[Splitting and Merging files using dd](https://www.linuxquestions.org/linux/answers/applications_gui_multimedia/splitting_and_merging_files_using_dd)
  - 拆分檔案，例如把檔案切成好幾個1G
```
dd if=[大檔案] of=[part1] bs=1m count=1024
dd if=[大檔案] of=[part2] bs=1m count=1024
....
```
  - 合併檔案，例如好幾個1G合併起來
```
dd if=[part1] of=大檔案 bs=1m count=1024
dd if=[part2] of=大檔案 bs=1m count=1024 seek=1024
....
```

# 參考
* [dd 指令教學與實用範例，備份與回復資料的小工具](https://blog.gtwang.org/linux/dd-command-examples/)