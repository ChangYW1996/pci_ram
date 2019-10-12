 pci_ram
 =======
 ------
 > 自动测试及接口技术作业
 ------
# 1.问题：
---
> 简单的PCI总线设计，实现总线与存储器的数据写与读，并通过软件仿真展示最终的实现结果。
---
# 2.分析与解决：
---
## 2.1.
> 实现简单的PCI总线时序，因此存储器不是设计的主要部分，在设计中直接选择使用QUARTUS II自带的单口RAM ip核实现。写/读操作在时钟上升沿执行，各参数如下：
```
 	input	[7:0]  address;		//RAM深度8bit
	input	  clock;           	//RAM时钟，与PCI总线所用的时钟一致
	input	[31:0]  data;		//RAM写入数据端，数据位宽32bit
	input	  rden;	   		//RAM写入信号使能端，高有效
	input	  wren;            	//RAM写出信号使能端，高有效
	output	[31:0]  q; 		// RAM写出数据端

```
---
### 写时序：
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/write.jpg)
### 写到读的过渡时序：
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/write_to_read.jpg)
### 读时序：从开始地址读：
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/read_init.jpg)
### 读时序：从指定地址读：
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/read_start_change.jpg)
