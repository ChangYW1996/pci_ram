module pci_ram(
clk,rst,//时钟，复位信号

frame,//帧信号，低电平有效，在其有效的第一个周期是传输地址

c_be,//寻址与响应命令：0010 IO读；0011 IO写；0110 存储器读；0111 存储器写

adbus,//地址/数据复用总线

address,//地址，由adbus得到，读出单独显示

wrdata,//向存储器写数据

rden,//存储器读出使能

wren,//存储器写入使能

rddata//从存储器读到的数据

);
/******例化RAM参数*******
	input	[7:0]  address;
	input	  clock;
	input	[31:0]  data;
	input	  rden;
	input	  wren;
	output	[31:0]  q;
***********************/
input clk,rst;
input frame;
input [3:0]c_be;

inout [31:0]adbus;
reg adbus_z;//控制adbus三态门
reg [31:0]adbus_reg;//用adbus_reg对adbus置高低电平

output reg [31:0]address;
output reg rden;
output reg wren;

output reg [31:0]wrdata;

output  [31:0]rddata;

/**********状态寄存器定义***************/
reg[3:0]cstate;//current state
reg[3:0]nstate;//next state

wire [31:0]add_reg1;
wire [31:0]add_reg2;

/**********状态寄存器描述***************/
//0000：等待；1000：操作地址读取
//0001：读数据等待状态；0010：读第一个数据；0011：持续读数据；0100：读数据结束
//1001：写第一个数据； 	1010：持续写数据；1011：写数据结束
//default：等待
parameter IDLE = 4'b0000;
parameter WAIT = 4'b1000;
parameter RDS0 = 4'b0001;
parameter RDS1 = 4'b0010;
parameter RDS2 = 4'b0011;
parameter RDS3 = 4'b0100;
parameter WRS0 = 4'b1001;
parameter WRS1 = 4'b1010;
parameter WRS2 = 4'b1011;


/***********状态寄存器****************/
//时序电路
always@(posedge clk or negedge rst)
begin
	if(!rst)
		cstate <= IDLE;
	else
		cstate <= nstate;
end

/***********下一状态描述****************/
//组合电路
always@(cstate or frame or c_be)
begin
	case(cstate)
		IDLE : //空闲状态
				if(!frame) 	nstate = WAIT;
				else		   nstate = IDLE;
		WAIT ://空闲状态，ad总线输出操作地址
				if(c_be==4'b0110)//存储器读,总线写出
								nstate = WRS0;			
				else if(c_be==4'b0111)//存储器写，总线读入
								nstate = RDS0;
				else 
								nstate = WAIT;
		WRS0 ://写入第一个数据状态
				if(frame)
								nstate = WRS2;
				else
								nstate = WRS1;
		WRS1 ://持续写数据状态
				if(frame)
								nstate = WRS2;
				else
								nstate = WRS1;
		WRS2 ://写最后一个数据状态
				if(frame)
								nstate = IDLE;//FRAME 一旦置无效，在一个完整传输阶段不能置有效，因此只有if
		RDS0 ://读时序的等待状态
				if(frame)
								nstate = RDS3;
				else 
								nstate = RDS1;
		RDS1 ://读第一个数状态
				if(frame)
								nstate = RDS3;
				else 
								nstate = RDS2;
		RDS2 ://持续读状态
				if(frame)
								nstate = RDS3;
				else 
								nstate = RDS2;
		RDS3 ://读最后一个数状态
				if(frame)
								nstate = IDLE;//FRAME 一旦置无效，在一个完整传输阶段不能置有效，因此只有if
		default:
				if(!frame) 	nstate = WAIT;
				else		   nstate = IDLE;
		endcase
end

/*******************输出逻辑************************/
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		address<=32'b0;
	end
	else
	begin
		case(nstate)
			IDLE://空闲状态		
			begin
					//adbus<=32'bz;
					address<=32'b0;
					//wrdata<=32'b0;
					//rden<=1'b0;
					//wren<=1'b0;
			end
			WAIT://取操作数据的地址
			begin
					address<=adbus;
					//wrdata<=32'b0;
					//rden<=1'b0;
					//wren<=1'b0;
			end
			WRS0://写第一个数据
			begin
					//wrdata<=adbus;
					address<=address;
					//wren<=1'b1;
					//rden<=1'b0;
			end
			WRS1://持续写状态
			begin
					//wrdata<=adbus;
					address<=address+1;
					//wren<=1'b1;
					//rden<=1'b0;
			end
			WRS2://写最后一个数状态
			begin
					//wrdata<=adbus;
					//wren<=1'b0;
					//rden<=1'b0;
					address<=address+1;
			end
			RDS0://读数据等待状态，保存地址
			begin
					//adbus<=32'bz;
					address<=address;
					//wren<=1'b0;
					//rden<=1'b1;
			end
			RDS1://读第一个数据
			begin
					//adbus<=rddata;
					address<=address;
					//wren<=1'b0;
					//rden<=1'b1;
			end
			RDS2://持续读状态
			begin
					//adbus<=rddata;
					//wren<=1'b0;
					//rden<=1'b0;
					address<=address+1;
			end
			RDS3://读最后一个数状态
			begin
					//adbus<=rddata;
					//wren<=1'b0;
					//rden<=1'b0;
					address<=address;
			end
			default:
			begin
					//adbus<=32'bz;
					address<=32'b0;
					//wrdata<=32'b0;
					//rden<=1'b0;
					//wren<=1'b0;
			end
		endcase
	end
end
always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		//frame<=1'b1;
		//c_be<=4'b0000;
		adbus_z<=1'b0;
		//address<=32'b0;
		wrdata<=32'b0;
		rden<=1'b0;
		wren<=1'b0;
	end
	else
	begin
		case(nstate)
			IDLE://等待状态		
			begin
					adbus_z<=1'b0;
					//address<=32'b0;
					wrdata<=32'b0;
					rden<=1'b0;
					wren<=1'b0;
			end
			WAIT:
			begin
					//address<=adbus;
					adbus_z<=1'b0;
					wrdata<=32'b0;
					rden<=1'b0;
					wren<=1'b0;
			end
			WRS0:
			begin
					adbus_z<=1'b0;
					wrdata<=adbus;
					//address<=address+1;
					wren<=1'b1;
					rden<=1'b0;
			end
			WRS1:
			begin
					adbus_z<=1'b0;
					wrdata<=adbus;
					//address<=address+1;
					wren<=1'b1;
					rden<=1'b0;
			end
			WRS2:
			begin
					adbus_z<=1'b0;
					wrdata<=adbus;
					wren<=1'b1;
					rden<=1'b0;
			end
			RDS0:
			begin
					adbus_z<=1'b0;
					//address<=address+1;
					wren<=1'b0;
					rden<=1'b0;
			end
			RDS1:
			begin
					adbus_z<=1'b1;
					adbus_reg<=rddata;
					//address<=address+1;
					wren<=1'b0;
					rden<=1'b1;
			end
			RDS2:
			begin
					adbus_z<=1'b1;
					adbus_reg<=rddata;
					//address<=address+1;
					wren<=1'b0;
					rden<=1'b1;
			end
			RDS3:
			begin
					adbus_z<=1'b1;
					adbus_reg<=rddata;
					wren<=1'b0;
					rden<=1'b1;
			end
			default:
			begin
					adbus_z<=1'b0;
					//address<=32'b0;
					wrdata<=32'b0;
					rden<=1'b0;
					wren<=1'b0;
			end
		endcase
	end
end

assign adbus=adbus_z?adbus_reg:32'bz;
assign add_reg1=~address;
assign add_reg2=~add_reg1;
RAM	RAM_init (
	.address (add_reg2[7:0]),   
	.clock (clk),  
	.data (wrdata), 
	.rden (rden),	 
	.wren (wren),    
	.q (rddata)    
	);
endmodule