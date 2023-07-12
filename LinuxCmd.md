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