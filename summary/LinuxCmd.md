# Linux常用命令

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
-s # 创建服务器端
-D # 作为后台进程
-c # 作为客户端
-i # 设置每多少秒统计一次
-t # 设置总计时长
-P # 设置同时工作的线程数
-u # 默认使用TCP发包，该选项可以变更为UDP发包
-b # 设置UDP模式的带宽，配合-u选项使用
```

## iptables
Linux常用的防火墙命令

[iptables的使用](https://wangchujiang.com/linux-command/c/iptables.html)

# 文本处理
## grep
Linux grep (global regular expression) 命令用于查找文件里符合条件的字符串或正则表达式。
```bash
-l # --files-with-matches 只打印匹配的文件名
-r # --recursive          递归查找子目录中的文件
-v # --invert-match       显示不被 pattern 匹配到的行，类似于反向匹配
-w # --word-regexp        匹配整个单词
-q # --quiet              不显示任何信息

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

## wc
查看一个文件的行、单词或字节数
### 常用选项
```bash
-c # 打印字节数
-m # 打印字符数
-l # 打印行数
-w # 打印单词数
```
### 举例
```bash
lspci | grep Virtio | wc -l # 统计命令`lspci | grep Virtio`的行数
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
lspci -xxx -s [bdf_id] # 显示指定BDF号的PCI配置空间的映像
```

## lscpu
显示CPU架构相关的信息
### 显示内容
架构、大小端、逻辑CPU个数、虚拟化类型支持、Cache相关信息、NUMA相关信息

# 其他命令
## watch
周期性地执行程序，并将输出显示在屏幕上
### 命令格式
```bash
watch [options] command
```
### 常用选项
```bash
-d # 高亮更新内容的变化
-n # 指定更新间隔
```
### 举例
```bash
watch -d -n 1 "./fpga_agent -s -x 2 -r" # 双引号中为需要执行的命令
```

## screen
Linux命令行远程屏幕共享工具

### 常用命令
```bash
screen -ls # 显示目前所有的screen作业
screen -wipe # 检查目前所有的screen作业，并删除已经无法使用的screen作业
# 如果出现已经detach并且不使用的screen作业，可以使用kill杀掉
```

## rpm
Red Hat Linux发行版上用来管理Linux各项套件的程序

### 常用选项
```bash
-i # 显示套件的相关信息
-v # 显示指令执行过程
-h # 套件安装时列出标记
-e # 删除指定的套件
-a # 查询所有套件
-q # 使用询问模式，遇到问题时先询问用户

-qa # 查看安装的软件
-ivh # 安装命令
--nodeps # 不验证套件档的相互关联性。
```

### 举例
```bash
rpm -ivh dpdk-g4-fpga-19.11.1-186.0.adb4e7f.x86_64.rpm
rpm -e openvswitch-g4-fpga
```

## mail

命令行下发送和接收电子邮件

### 常用选项
```bash
-s # 指定邮件主题
-
```

### 常用命令
```bash
# 直接使用shell当编辑器
mail -s "Hello from jsdig.com by shell" admin@jsdig.com
# => input
# Hello, this is the content of mail.
# Welcome to www.jsdig.com

# 将mail.txt文件中的内容作为邮件内容发送给admin@jsdig.com
mail -s "Hello from jsdig.com by file" admin@jsdig.com < mail.txt

# 使用管道进行发送
echo "Hello, this is the content of mail. Welcome to www.jsdig.com" | mail -s "Hello from jsdig.com by pipe" admin@jsdig.com
```