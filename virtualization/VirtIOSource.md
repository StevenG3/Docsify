# VirtIO源码分析
以Linux-3.10版本为例
# 网络设备
## 注册
1. virtio总线注册

```c
// drivers/virtio/virtio.c
static struct bus_type virtio_bus = {
	.name  = "virtio",
	.match = virtio_dev_match,
	.dev_attrs = virtio_dev_attrs,
	.uevent = virtio_uevent,
	.probe = virtio_dev_probe,
	.remove = virtio_dev_remove,
};

static int virtio_init(void)
{
	if (bus_register(&virtio_bus) != 0)
		panic("virtio bus registration failed");
	return 0;
}

core_initcall(virtio_init);
```

**TODO: 内核初始化调用顺序**

可以在`/sys/bus/`下检查virtio总线

2. virtio-net驱动注册

```c
// drivers/net/virtio_net.c
static struct virtio_driver virtio_net_driver = {
	.feature_table = features,
	.feature_table_size = ARRAY_SIZE(features),
	.driver.name =	KBUILD_MODNAME,
	.driver.owner =	THIS_MODULE,
	.id_table =	id_table,
	.probe =	virtnet_probe,
	.remove =	virtnet_remove,
	.config_changed = virtnet_config_changed,
#ifdef CONFIG_PM
	.freeze =	virtnet_freeze,
	.restore =	virtnet_restore,
#endif
};

module_virtio_driver(virtio_net_driver);
#define module_virtio_driver(__virtio_driver) \
	module_driver(__virtio_driver, register_virtio_driver, \
			unregister_virtio_driver)

int register_virtio_driver(struct virtio_driver *driver)
{
	/* Catch this early. */
	BUG_ON(driver->feature_table_size && !driver->feature_table);
	driver->driver.bus = &virtio_bus;
	return driver_register(&driver->driver);
}
```

在`/sys/bus/virtio/drivers/`下查看注册的驱动

## 发送

```
virtio_net_driver
| virtnet_probe
| | virtnet_netdev
| | | start_xmit
| | | | free_old_xmit_skbs
| | | | xmit_skb
| | | | | virtqueue_add_outbuf
| | | | | | virtqueue_add
| | | | virtqueue_kick
```

**xmit_skb**

入参：
1. struct send_queue *sq：发送队列
2. struct sk_buff *skb：管理和控制接收或发送数据包的结构体
    - vnet的头部信息存储在 skb->cb 中
    - 需要发送的数据头指针在 skb->data 的位置

流程分析：
1. 从skb中取出vnet头部，其头部的结构体形式为

```c
struct skb_vnet_hdr {
	union {
		struct virtio_net_hdr hdr;
		struct virtio_net_hdr_mrg_rxbuf mhdr;
	};
};

struct virtio_net_hdr {
#define VIRTIO_NET_HDR_F_NEEDS_CSUM	1	// Use csum_start, csum_offset
#define VIRTIO_NET_HDR_F_DATA_VALID	2	// Csum is valid
	__u8 flags;
#define VIRTIO_NET_HDR_GSO_NONE		0	// Not a GSO frame
#define VIRTIO_NET_HDR_GSO_TCPV4	1	// GSO frame, IPv4 TCP (TSO)
#define VIRTIO_NET_HDR_GSO_UDP		3	// GSO frame, IPv4 UDP (UFO)
#define VIRTIO_NET_HDR_GSO_TCPV6	4	// GSO frame, IPv6 TCP
#define VIRTIO_NET_HDR_GSO_ECN		0x80	// TCP has ECN set
	__u8 gso_type;
	__u16 hdr_len;		/* Ethernet + IP + tcp/udp hdrs */
	__u16 gso_size;		/* Bytes to append to hdr_len per frame */
	__u16 csum_start;	/* Position to start checksumming from */
	__u16 csum_offset;	/* Offset after that to place checksum */
};

struct virtio_net_hdr_mrg_rxbuf {
	struct virtio_net_hdr hdr;
	__u16 num_buffers;	/* Number of merged rx buffers */
};
```

后续会根据取出的头部对照标志位，进入不同的处理分支

2. 从 skb 中取出目的 MAC。skb->data 指向需要发送的数据帧的头部位置，该数据帧已经打上了MAC header、IP header 和 TCP/UDP header。

![avatar](/images/sk_buff-layout.png "sk_buff结构")

3. 从 struct send_queue *sq 中取出 struct virtnet_info *vi

`struct virtnet_info`是一个私有数据结构，其保存了virtio设备的所有信息，结构如下：

```c
struct virtnet_info {
	struct virtio_device *vdev;
	struct virtqueue *cvq;
	struct net_device *dev;
	struct send_queue *sq;
	struct receive_queue *rq;
	unsigned int status;

	...

	/* Host will merge rx buffers for big packets (shake it! shake it!) */
	bool mergeable_rx_bufs;

	...
};
```

可以使用该结构体获取对应virtnet设备的信息，包括相关联的队列（控制、发送、接收）、virtio及网络设备信息。每一个virtqueue会关联到某个virtio设备下，该设备的priv指向`struct virtnet_info *vi`，因此使用`sq->vq->vdev->priv`这样的方法进行索引。

4. 判断ip_summed的值和CHECKSUM_PARTIAL之间的关系，如果`ip_summed == CHECKSUM_PARTIAL`，表示协议栈并没有计算完校验和，只计算了伪头，将传输层的数据部分留给了硬件进行计算。如果底层不支持CSUM，则skb_checksum_help完成校验和。

> "CHECKSUM_PARTIAL" 特性一般用于计算传输层头部的校验和，主要包括源端口、目标端口、数据包长度、校验和字段等。这些字段的校验和计算通常由 VirtIO 驱动完成，而不是由虚拟机的操作系统或网络协议栈来处理。
>
> 在计算部分校验和时，VirtIO 驱动只涉及到数据包头部的相关字段，而不涉及数据包的有效负载。数据包的有效负载（例如上层应用传输的数据）的校验和计算由底层的网络设备（例如物理网卡）在宿主机上完成。
>
> 需要注意的是，VirtIO 可能在不同的场景和实现中有所不同。在某些情况下，可能会涉及到网络层（L3）头部的校验和计算，但一般情况下，"CHECKSUM_PARTIAL" 特性主要用于传输层头部的校验和。

5. XXX

# 参考

[Linux内核中sk_buff结构详解](https://www.jianshu.com/p/3738da62f5f6)

[从Linux设备驱动模型看virtio初始化](http://blog.chinaunix.net/uid-28541347-id-5820032.html)

[Linux内核中的校验和](https://hustcat.github.io/checksum-in-kernel/)