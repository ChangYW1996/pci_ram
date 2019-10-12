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
## 2.1.存储器
> 实现简单的PCI总线时序，因此存储器不是设计的主要部分，在设计中直接选择使用QUARTUS II自带的单口RAM ip核实现。写/读操作在时钟上升沿执行，各参数如下：
```
 	input	[7:0]  address;		//RAM深度8bit
	input	  clock;           	//RAM时钟，与PCI总线所用的时钟一致
	input	[31:0]  data;		//RAM写入数据端，数据位宽32bit
	input	  rden;	   		//RAM写入信号使能端，高有效
	input	  wren;            	//RAM写出信号使能端，高有效
	output	[31:0]  q; 		// RAM写出数据端

```
## 2.2.PCI总线信号选择
> PCI总线的信号选择ADBUS（地址/数据复用总线，32bit）、FRAME（帧传输信号，低有效）、CB/E（控制读/写/总线命令信号，4bit）。
## 2.3.状态机的设计
> 状态机可以很直观的描述PCI总线时序数据传输的各个状态，本次设计中简单的将时序分为：IDLE（空闲状态）、WAIT（等待状态）、WRSx（总线写状态）、RDSx（总线读状态）。其中，为了符合PPT读写时序图中分别对于总线写和总线读状态的不同描述，WRx和RSx会取若干个。描述如下：

* IDLE空闲状态:FRAME无效，CB/E总线命令状态。PCI总线此时既不读，也不写，ADBUS置高阻态；
* WAIT等待状态：FRAME有效，CB/E总线命令状态。PCI总线准备读/写，ADBUS向RAM传送操作数据的起始地址；
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/write_flow.png)
* WRS0写入第一个数据状态：FRAME有效，CB/E总线写状态。起始地址为WAIT状态写入的数据，连接到RAM的address，ADBUS向RAM的data传送写入数据，此时rden=0,wren=1;
* WRS1持续写数据状态：FRAME有效，CB/E总线写状态。在上一个数据写完毕之后地址数据自加1，然后ADBUS向RAM的data传送写入下一个数据，此时rden=0,wren=1;
* WRS2写最后一个数据状态：FRAME无效，CB/E总线写状态。rden=0,wren=1，在上一个数据写完毕之后地址数据自加1，然后ADBUS向RAM的data传送写入最后一个数据；
* WRS3写最后一个数据状态：FRAME无效，CB/E总线写状态。rden=0,wren=1，在上一个数据写完毕之后地址数据不变， ADBUS向RAM的data仍传送写入最后一个数据;
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/read_flow.png)
* RDS0读数据的等待状态：FRAME有效，CB/E总线读状态。rden=1,wren=0， ADBUS为等待状态，设置为高阻态；
* RDS1读第一个数据状态：FRAME有效，CB/E总线读状态。rden=1,wren=0，起始地址为WAIT状态写入的地址，传送到RAM的address，RAM的q读出地址对应的存储数据并通过ADBUS传出；
* RDS2持续读数据状态：FRAME有效，CB/E总线读状态。rden=1,wren=0，地址数据自加1，传送到RAM的address，RAM的q读出地址对应的存储数据并通过ADBUS传出；
* RDS3读最后一个数据状态：FRAME无效，CB/E总线读状态。rden=1,wren=0，地址数据不变，RAM的q读出地址对应的存储数据并通过ADBUS传出。
> 状态转换图如下:

![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/flow_chart.jpg)
---
### 写时序：
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/write.jpg)
### 写到读的过渡时序：
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/write_to_read.jpg)
### 读时序：从开始地址读：
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/read_init.jpg)
### 读时序：从指定地址读：
![homework]( https://github.com/ChangYW1996/pci_ram/blob/master/read_start_change.jpg)
