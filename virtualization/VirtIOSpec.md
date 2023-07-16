# VirtIO协议详解

# 5 设备类型
在队列、配置空间和特性协商功能之外，还定义了多种设备类型。

以下设备类型用于表示不同类型的VirtIO设备

总线可以根据BDF号发现设备类型（如VirtIO设备），再根据以下Subsystem ID决定VirtIO设备类型。

| Device ID | VirtIO Device |
| :---- | :----: |
| 0 | reserved(invalid) |
| 1 | network card |
| 2 | block device |

## 5.1 网络设备


### 5.1.6 设备选项
```c
struct virtio_net_hdr {
#define VIRTIO_NET_HDR_F_NEEDS_CSUM 1
	u8 flags;
#define VIRTIO_NET_HDR_GSO_NONE 0
#define VIRTIO_NET_HDR_GSO_TCPV4 1
#define VIRTIO_NET_HDR_GSO_UDP 3
#define VIRTIO_NET_HDR_GSO_TCPV6 4
#define VIRTIO_NET_HDR_GSO_ECN 0x80
	u8 gso_type;
	le16 hdr_len;
	le16 gso_size;
	le16 csum_start;
	le16 csum_offset;
	le16 num_buffers;
};
```

#### 5.1.6.2 Pkt传输
##### 5.1.6.2.1 驱动要求

##### 5.1.6.2.2 设备要求
- 设备必须忽略它无法识别的*flag*位
- 如果没有设置VIRTIO_NET_HDR_F_NEEDS_CSUM，那么设备不能使用*csum_start*和*csum_offset*
- 如果VIRTIO_NET_F_HOST_TSO4, TSO6或UFO选项有一个被协商，那么设备可以使用*hdr_len*作为传输头部大小的提示（也就是说**不能根据hdr_len确定头部长度的确切值**）。设备不能确信*hdr_len*是正确的。
- 如果VIRTIO_NET_HDR_F_NEEDS_CSUM没有被设置，那么设备不能确信pkt的checksum是正确的。

##### 5.1.6.2.3 传输中断
驱动利用VIRTQ_AVAIL_F_NO_INTERRUPT标志位抑制传输中断，并检查后续数据包的传输路径中是否有已使用的数据包。

此中断处理程序的正常行为是从`used ring`中检索新的描述符，并释放相应的报头和分组。

#### 5.1.6.3 设置接收Buff
通常，最好尽可能地填充接收virtqueue：如果它耗尽，网络性能将受到影响。

如果使用VIRTIO_NET_F_GUEST_TSO4、VIRTIO_NET_F_GUEST_TSO6或VIRTIO_NET_F_GUEST_UFO功能，则最大传入数据包长度为65550字节（TCP/UDP数据包的最大长度加上14字节的以太网报头），否则为1514字节。12字节的结构`virtio_net_hdr`被前置到以太网报头前，总计65562字节或者1526字节。

##### 5.1.6.3.1 驱动要求
- 如果VIRTIO_NET_F_MRG_RXBUF没有被协商：
	- 如果VIRTIO_NET_F_GUEST_TSO4,VIRTIO_NET_F_GUEST_TSO6或者VIRTIO_NET_F_GUEST_UFO被协商，那么驱动应使用至少65562字节的缓冲区填充接收队列。（这些标志被协商，说明可以将分片功能交给硬件完成，软件可以不用分片）
	- 否则，驱动应该用至少1526字节的缓冲区填充接收队列
- 如果协商了VIRTIO_NET_F_MRG_RXBUF，则每个缓冲区的大小必须大于结构体`virtio_net_hdr`的大小（<font color=red>为什么此处只需要大于结构体的大小就可以？</font>）

如果协商了VIRTIO_NET_F_MQ，那么每个接受队列都将被使用，应该用缓冲区填充。

##### 5.1.6.3.2 设备要求
- 设备必须将*num_buffers*设置为用于保存传入数据包的描述符的数量。
- 如果未协商VIRTIO_NET_F_MRG_RXBUF，设备必须只使用单个描述符（<font color=red>什么是单个描述符，是指与链式描述符相反么？</font>）

#### 5.1.6.4 接收数据包的处理
当一个数据包被拷贝进接收队列的buff中，最高效的处理方式是禁用接收队列的中断并处理数据包，直到没有更多的数据包，再使能中断。（**此处是指中断触发（或通知机制）应该在没有更多数据包进入接收队列时发生，而非每个包都使能中断，好的解决方法是设置定时器，每当有新的数据到来时重置定时器，当定时器超时时，触发中断**）

接收数据包的处理涉及：

1. *num_buffers*表示数据包分布在多少个描述符上：如果未协商VIRTIO_NET_F_MRG_RXBUF，那么该值始终为1。这允许在不必分配大缓冲区的情况下接收大分组。在这种情况下，在 used_ring 中至少存在num_buffers个缓冲区，并且设备将它们链接在一起形成单个分组。其他buff不会以 virtio_net_hdr 结构体开始。（<font color=red>不知道在说些什么，猜测是说可能存在链式的描述符，当一个描述符是链式描述符时，只有第一个buff会以 virtio_net_hdr 结构体开始，其他buff都不会以该结构体开始。</font>）
2. 如果 num_buffers 是1，那么整个数据包将包含在这个buff中，头部以virtio_net_hdr 结构体开始。
3. 如果协商了VIRTIO_NET_F_GUEST_CSUM功能，则可以设置标志中的VIRTIO_NET_HDR_F_DATA_VALID位：如果是，则设备已经验证了分组校验和。在多个封装协议的情况下，校验和的一个级别已被验证。（<font color=red>什么是"one level of checksums" 以及 "multiple encapsulated protocols"？</font>）

此外，VIRTIO_NET_F_GUEST_CSUM、TSO4、TSO6、UDP和ECN功能分别使能接收校验和、大接收卸载和ECN支持，这些功能相当于传输校验和、传输分段卸载和ECN功能的输入。
1. 如果协商了VIRTIO_NET_F_GUEST_CSUM功能，则可以设置标志中的 VIRTIO_NET_HDR_F_NEEDS_CSUM 位：如果是，则已经验证了从csum_start偏移csum_offset处的分组校验和以及任何先前的校验和。数据包上的校验和不完整，csum_start和csum_offset指示如何计算它。（<font color=red>是否可以表示如果VIRTIO_NET_HDR_F_NEEDS_CSUM没有被设置，则后端应该校验该checksum是否正确？</font>）
2. 如果协商了VIRTIO_NET_F_GUEST_TSO4、TSO6或UFO选项，则gso_type可能不是VIRTIO_NET_HDR_GSO_NONE，并且gso_size字段指示所需的MSS。（**MSS = MTU - (IP Header + TCP Header)**）

##### 5.1.6.4.1 设备要求
- 如果 VIRTIO_NET_F_MRG_RXBUF 没有被协商，则设备必须将*num_buffers*设置为1
- 如果 VIRTIO_NET_F_MRG_RXBUF 被协商，则设备必须设置*num_buffers*指示数据包（包括报头）的描述符的数量
- 如果 VIRTIO_NET_F_GUEST_CSUM 没有被协商，设备必须将标志设置为零，并且应该向驱动程序提供一个已经经过校验和校验的数据包。
- 如果未协商VIRTIO_NET_F_GUEST_TSO4，则设备不得将gso_type设置为VIRTIO_NET_HDR_GSO_TCPV4。
- 如果未协商VIRTIO_NET_F_GUEST_UDP，则设备不得将gso_type设置为VIRTIO_NET_HDR_GSO_UDP。
- 如果未协商VIRTIO_NET_F_GUEST_TSO6，则设备不得将gso_type设置为VIRTIO_NET_HDR_GSO_TCPV6。
- 设备不应向驱动发送需要分段卸载且设置了显式拥塞通知位的TCP数据包，除非协商了VIRTIO_NET_F_GUEST_ECN功能，在这种情况下，设备必须设置gso_type中的VIRTIO_NET_HDR_GSO_ECN位。（<font color=red>什么是"Explicit Congestion Notification"？</font>）
- 如果已协商VIRTIO_NET_F_GUEST_CSUM功能，则设备可以在标志中设置VIRTIO_NET_HDR_F_NEEDS_CSUM位，并且：
	1. 设备必须在距csum_start的偏移csum_offset以及所有先前偏移处验证分组校验和；（<font color=red>什么是"as well as all proceding offsets"？</font>）
	2. 设备必须将存储在接收缓冲区中的数据包校验和设置为TCP/UDP伪报头；（**伪头部：包含Src IP、Dst IP、padding、protocol和TCP/UDP header的虚构数据结构，可以同时校验IP和TCP/UDP首部的正确性**）
	3. 设备必须设置csum_start和csum_offset，使得从csum_start直到分组结束计算一的补码校验和，并将结果存储在从csum_start的偏移csum_offset处，将形成一个完全校验和的分组；（**"ones' complement checksum"即为反码**）
- 如果未协商VIRTIO_NET_F_GUEST_TSO4、TSO6或UFO选项，则器械必须将gso_type设置为VIRTIO_NET_HDR_GSO_NONE。
- 如果gso_type与VIRTIO_NET_HDR_GSO_NONE不同，则设备还必须设置标志中的VIRTIO_NET_HDR_F_NEEDS_CSUM位，必须设置gso_size以指示所需MSS。
- 如果已协商VIRTIO_NET_F_GUEST_TSO4、TSO6或UFO选项之一，则设备应将*hdr_len*设置为不小于报头（包括传输报头）长度的值。（<font color=red>这里是为什么？</font>）
- 如果已协商VIRTIO_NET_F_GUEST_CSUM功能，则设备可设置标志中的VIRTIO_NET_HDR_F_DATA_VALID位，如果是，则设备必须验证数据包校验和（如果有多个封装协议，则验证一级校验和）。

##### 5.1.6.4.2 驱动要求
- 驱动必须忽略*flag*中无法识别的标志位
- 如果未设置标志中的VIRTIO_NET_HDR_F_NEEDS_CSUM位，则驱动程序不得使用csum_start和csum_offset。
- 如果已经协商了VIRTIO_NET_F_GUEST_TSO4、TSO6或UFO选项之一，则驱动程序可以仅使用*hdr_len*作为关于传输报头大小的提示。驱动程序不能依赖*hdr_len*来判断是否正确。
- 如果既未设置VIRTIO_NET_HDR_F_NEEDS_CSUM也未设置VIRTIO_NET_HDR_F_DATA_VALID，则驱动程序不得依赖于数据包校验和是否正确。（<font color=red>是否说明驱动需要校验校验和</font>）

#### 5.1.6.5 控制队列
驱动使用控制队列（如果 VIRTIO_NET_F_CTRL_VQ 被协商）发送命令，以操作设备的各种功能，这些功能不容易映射到配置空间

所有命令的格式如下：
```c
struct virtio_net_ctrl {
	u8 class;
	u8 command;
	u8 command-specific-data[];
	u8 ack;
};
/* ack values */
#define VIRTIO_NET_OK 0
#define VIRTIO_NET_ERR 1
```

*class*、*command*和*command-specific-data*由驱动程序设置，设备设置ack字节。如果ack不是VIRTIO_NET_OK，它除了发出诊断信息外，几乎无能为力。

##### 5.1.6.5.1 数据包接收过滤
如果协商了 VIRTIO_NET_F_CTRL_RX 和 VIRTIO_NET_F_CTRL_RX_EXTRA ，驱动可以发送用于混杂模式、多播、单播和广播接收的控制命令。

注意：这些命令一般都是尽力而为的：不需要的分组仍然可能到达

```c
#define VIRTIO_NET_CTRL_RX 0
  #define VIRTIO_NET_CTRL_RX_PROMISC 0
  #define VIRTIO_NET_CTRL_RX_ALLMULTI 1
  #define VIRTIO_NET_CTRL_RX_ALLUNI 2
  #define VIRTIO_NET_CTRL_RX_NOMULTI 3
  #define VIRTIO_NET_CTRL_RX_NOUNI 4
  #define VIRTIO_NET_CTRL_RX_NOBCAST 5
```

###### 5.1.6.5.1.1 设备需求
如果 VIRTIO_NET_F_CTRL_RX 没有被协商，设备必须支持以下 VIRTIO_NET_CTRL_RX 类的命令：
- VIRTIO_NET_CTRL_RX_PROMISC 打开和关闭混杂模式。command-specific-data 是一个包含0（关）或者1（开）的一个字节。如果混合模式开启，设备应该接收所有传输的数据包。即使 VIRTIO_NET_CTRL_RX 类命令设置的其他模式之一处于打开状态，这也应该生效。（**只要打开promiscuous就接收所有传输的数据包**）
- VIRTIO_NET_CTRL_RX_ALLMULTI 打开或者关闭所有多播接收。command-specific-data 是一个包含0（关闭）或者1（打开）的字节。当所有多播接收在设备上时，应该允许所有传入的多播数据包。

如果已协商VIRTIO_NET_F_CTRL_RX_EXTRA功能，则设备必须支持以下VIRTIO_NET_CTRL_RX类命令：
- VIRTIO_NET_CTRL_RX_ALLUNI 
- VIRTIO_NET_CTRL_RX_NOMULTI