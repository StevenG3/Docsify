# Markdown语法

# 图片
![avatar](images/vxlan-format.png "VXLAN报文格式")

```markdown
![avatar](images/vxlan-format.png "VXLAN报文格式")
```

默认左对齐


# 表格
## 样式
|  组合键  | 功能 | 备注 |
| :----: | :---- | ----: |
| Ctrl-a | 回到行首 | 超级有用 |
| Ctrl-e | 回到行尾 |  |

```markdown
|  组合键  | 功能 | 备注 |
| :----: | :---- | ----: |
| Ctrl-a | 回到行首 | 超级有用 |
| Ctrl-e | 回到行尾 |  |
```

# 链接
```markdown
[name](link)

<link>
```

[NUMA影响程序延迟](https://draveness.me/whys-the-design-numa-performance/)

<https://draveness.me/whys-the-design-numa-performance/>

# 引用
## 样式
```markdown
> 这是一个引用
```

> 这是一个引用

如果需要在引用块中分段，则应该在分段空行前加上`>`

```markdown
> 这是段落一
>
> 这是段落二
```

> 这是段落一
>
> 这是段落二
