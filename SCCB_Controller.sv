





module SCCB_Controller(input clk,rst,sccb_clk,
                       output SCL, Init_Comp,
							  output reg reset,
							  inout SDA,
							  output reg [7:0] read_data
							  /*output reg [1:0] state,
							  output [2:0] cnt_wire*/);

localparam RESET = 0;
localparam LOAD  = 1;
localparam WAIT  = 3;
localparam STOP  = 2;

//// init rom size 
localparam init_rom_size = 73;
reg [16:0] OV7670_init_rom [init_rom_size-1:0];    
initial $readmemh("V:/VLSI/FPGA/FPGA_Image_processing/camera/OV7670_Camera_Module/OV7670_init.txt",OV7670_init_rom);    // initilize the rom from the given rom file 

reg [1:0] state;
reg [$clog2(init_rom_size)-1:0] cnt;
reg RW;

reg [9:0] rst_cnt;
wire [7:0] data_read;
wire task_comp,load_comp,start,r_w;
wire [15:0] in_data;
wire [16:0] rom_data;


/////////////////    SCCB Driver    ///////////////
I2C_DRIVER SCCB_Driver( clk,rst,start,r_w,sccb_clk,
                        in_data, 
                        task_comp,load_comp, 
                        data_read, 
                        SDA,
                        SCL);
/////////////////////////////////////////////  //


assign start = (state==LOAD);               // Load data to I2C Driver 
assign rom_data = OV7670_init_rom[cnt];    // 17 bit ROM data
assign r_w = rom_data[16];                // Read or Write bit
assign in_data = rom_data[15:0];         // data from ROM " in_data[15:8] --> Reg addr, in_data[7:0] --> Data; "
//assign cnt_wire = cnt;             
assign Init_Comp = state==STOP;        // initilization complete signal


always@(negedge clk, negedge rst) begin 
if(!rst) begin
           state <= 0; 
           cnt <= 0;
           RW <= 0;
           rst_cnt <= 0;
			  reset <= 0;
         end
else     begin 
            case(state) 
            RESET: begin 
                     if(rst_cnt == 1000) state <= LOAD;
                     else state <= RESET;
                     if(rst_cnt == 5) reset <= 1;
                     rst_cnt <= rst_cnt + 1;
                     cnt <= 0;
                     RW <= 0;
                   end
            LOAD:  begin 
                     if(load_comp) begin 
                                     state <= WAIT;
                                     cnt <= cnt + 1;
                                     RW <= r_w;
                                   end
                   end
            WAIT:  begin 
                      if(task_comp) begin 
                                     if(cnt == init_rom_size ) state <= STOP;
                                     else state <= LOAD;
                                    end
                      if(RW) read_data <= data_read;
							
                   end
            STOP:  state <= STOP;
            default: state <= RESET;
            endcase
         end
end


endmodule

