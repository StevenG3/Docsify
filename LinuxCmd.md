# 网络命令
## ping
### 常用选项
```shell
-s # packetsize
   # Specifies the number of data bytes to be sent. The default is 56, 
   # which translates into 64 ICMP data bytes when combined with 
   # the 8 bytes of ICMP header data.

```

## ip
### link
ip-link - network device configuration

ip link add - add virtual link
```shell
ip link add link eth0 name eth0.10 type vlan id 10 # 在设备eth0上创建新的vlan设备eth0.10
```
ip link set - change device attributes
```shell

```

### netns
ip netns - process network namespace management

ip netns exec [ NAME ] cmd ... - Run cmd in the named network namespace
```shell
ip netns exec ns2 ifconfig # 在ns2中执行ifconfig命令
```

## iperf
### 常用选项
```shell
-s 
-D
-c
-i
-t
-P
```


# 文本处理
## grep
Linux grep (global regular expression) 命令用于查找文件里符合条件的字符串或正则表达式。
```bash
-l # --files-with-matches 只打印匹配的文件名
-r # --recursive          递归查找子目录中的文件
-v # --invert-match       显示不被 pattern 匹配到的行，类似于反向匹配
-w # --word-regexp        匹配整个单词


-B NUM # --before-context=NUM 除了显示被匹配的行之外，再显示该行之前的 NUM 行内容
```

## awk
```bash

```

## sed
### 命令格式
```bash
sed [-hnV] [-e<script>] [-f<script>] [file]
```

### 常用选项
```bash
-n # --quiet, --silent 
   # 默认情况下，sed 会在所有的脚本指定执行完毕后，会自动输出处理后的内容，而该选项会屏蔽启动输出，需使用 print 命令来完成输出
```

### 举例
```bash
# -n 选项会禁止 sed 输出，但 p 标记会输出修改过的行，将二者匹配使用的效果就是只输出被替换命令修改过的行
sed -n '1p' example.txt # 打印example.txt文件的第1行
sed -n '1,3p' example.txt # 打印example.txt从第1行开始的3行
sed -n '1~3p' example.txt # 从第1行开始每3行打印1行
```

# 管道命令
## xargs
在 Unix 系统中大多数命令都不接受标准输入作为参数，只能直接在命令行输入参数，这导致无法用管道命令传递参数。xargs 命令的作用，就是将标准输入转为命令行参数。

### 常用选项
```bash
-n # max-args 命令在执行时一次用得最多的参数的个数，默认是所有
-d # delim    使用定界符分割字符串
```

### 举例
```bash
echo abcd ef ghi jklmn opq | xargs -n3
# =>
# abcd ef ghi
# jklmn opq

echo hello,this,is,xargs | xargs -d,
# =>
# hello this is xargs
#

```


# 硬件命令
## lspci
用于显示Linux 系统上的设备和驱动程序
### 安装
```bash
apt-get install pciutils
```
### 常用选项
```bash
-s # Show only devices in the specified domain
-v # Be verbose and display detailed information about all devices
-xxx # Show hexadecimal dump of the whole PCI configuration space
```

### 举例
```bash
lspci # list all PCI devices
lspci | grep Virtio | sed -n '1p' | awk '{print $1}' # 获取第一行(`sed -n '1p'`) virtio-pci 设备(`grep Virtio`)的PCIe设备号(`awk '{print $1}'`)
lspci 
```