







module I2C_DRIVER(input clk,rst,start,r_w,sccb_clk,
                  input [15:0] in_data, 
                  output task_comp,load_comp, 
                  output [7:0] data_read, 
                  inout SDA,
                  output SCL);
                  
                  
/// states of state meachine 
localparam RESET = 0;
localparam START = 1;
localparam WRITE = 3;
localparam READ  = 2;
localparam DELAY = 6;
localparam STOP  = 7;

//// write and read adress of the device 
localparam write_adress = 8'h42; //42
localparam read_adress = 8'h43;


reg [2:0] state;
reg [3:0] cnt;
reg RW,D_C,SDA_reg,stop;
reg [7:0] write_data;
reg [7:0] read_data;
reg [15:0] data;
wire SCL_wire,SDA_wire;


assign SCL_wire = (state==START)?1:sccb_clk;
assign SDA_wire = (state==READ)?1'b1:SDA_reg;
assign task_comp = (state==STOP);
assign load_comp = (state == WRITE);
assign data_read = read_data;
assign SCL = (SCL_wire)?1'bz:1'b0;
assign SDA = (SDA_wire)?1'bz:1'b0;


//// state meachine of the driver 

always@(negedge clk, negedge rst) 
if(!rst) begin 
state<=0;
RW <= 1;
D_C = 0;
write_data <= 0;
read_data <= 0;
SDA_reg <= 1;
cnt <= 0;
stop <= 0;
data <= 0;
end
else 
case(state) 
RESET: begin
        state<=START;
        RW <= 1;
        D_C = 0;
        write_data <= 0;
        read_data <= 0;
        SDA_reg <= 1;
        cnt <= 0;
        stop <= 0;
        data <= 0;
       end
START: begin 
        cnt <= 0;
        stop <= 0;
        if(start&&sccb_clk) begin  // change state only when SCL is low and start = 1
                    state <= WRITE;
                    SDA_reg <= 0;
                    write_data <= (r_w)?read_adress:write_adress;
                    RW <= r_w;
                    D_C = 0;    
                    data <= in_data;
						  
                  end
        else      begin 
                    state <= START;
                    SDA_reg <= 1;
                    write_data <= {write_adress,1'b0};
                    RW <= 0;
                    D_C = 0;
                  end
       end
WRITE: begin 
        if(!sccb_clk) begin  // change stste only when SCL is low
                        if(cnt==8) begin  
                                     state <= DELAY; 
                                     cnt <= 0;  
												 SDA_reg <= 1;//RW;
                                   end 
                        else begin 
                                state <= WRITE;
                                cnt <= cnt + 1;
                                SDA_reg <= write_data[7];
                                write_data <= write_data<<1; 
                             end
                      end 
        else          state <= WRITE;
       end
DELAY: begin 
        cnt <= 0;
		  if(RW) begin 
		  if(!sccb_clk) begin state <= READ; read_data <= 8'hF1; stop <= 0; end
		  end
		  else begin 
        if(sccb_clk) begin        // change state only when SCL is high
        if(stop) begin state <= STOP; stop <= 0; end
        else begin
              if((!D_C)) begin state <= WRITE; D_C <= 1; write_data <= data[15:8]; stop <= 0; end
              else begin state <= WRITE; write_data <= data[7:0]; stop <= 1'b1; end
             end
       end 
                      end
							 end
READ: begin 
        if(sccb_clk) begin 
                      state <= READ;
                      read_data <= {read_data,SDA};
                      cnt <= cnt + 1;
                     end 
        else if(cnt==8) begin 
                          state <= DELAY;
                          cnt <= 0;
                          stop <= 1;
								  RW <= 0;
								  ///SDA_reg <= 0;
                        end
      end
STOP: if(sccb_clk) begin state <= START; SDA_reg <= 1; stop <= 0;end
      else SDA_reg <= 0; 

default: state <= RESET;
endcase

endmodule
