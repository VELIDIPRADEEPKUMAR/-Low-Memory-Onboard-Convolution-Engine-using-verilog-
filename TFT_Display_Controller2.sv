



module TFT_Display_Controller2#(parameter row = 480, parameter column = 320)
                              (input clk,rst,MISO,VS,colour_ready,input [23:0] colour_data, 
                               output D_C,CS,Reset,MOSI,SCK,
										 output reg colour_load_comp); 

localparam reset = 0;
localparam init_load = 1;
localparam init_wait = 3;
localparam delay = 2;
localparam setup_ram = 6;
localparam load_colour = 7;
localparam load_pixel = 4;
localparam write_wait = 5;

localparam N_init = 63;

localparam load_ram = 8'h2C;

reg [8:0] init_rom[N_init-1:0];
initial $readmemh("V:/VLSI/FPGA/FPGA_Image_processing/TFT_display/TFT_Display_controller_Vivado/init_data.txt",init_rom);

reg [2:0] state;
reg [1:0] PIXEL_CNT;
reg [23:0] delay_cnt;
reg imr;
reg [$clog2(N_init)-1:0] cnt;
wire[7:0] Pixel_Data;           // pixel info extracted from colour data info 
reg [23:0] colour_reg;
wire [7:0] in_data;
wire [8:0] init_rom_data;
wire Load,Imd_read,data_cmd,controller_state,Write_comp,Read_comp,load_comp;
wire [7:0] Data_read; 

////////////////////////// instanciate Driver module ///////////////////
ILI9488_Driver Driver (clk,rst,Load,Imd_read,data_cmd,MISO,
                       in_data, 
                       D_C,Write_comp,Read_comp,CS,
                       Reset,MOSI,SCK,load_comp,
                       Data_read);

////////////////////////////////////////////////////////////////////////
// Loading Pixel Data from colour data info from OV7670 Camaera module /
////////////////////////////////////////////////////////////////////////
//////// First Byte /////////////// Second Byte  ///////////////////////
////////------------///////////////--------------///////////////////////
//////// D7 --> R4  ///////////////  D7 --> G2   ///////////////////////
//////// D6 --> R3  ///////////////  D7 --> G1   ///////////////////////
//////// D5 --> R2  ///////////////  D7 --> G0   ///////////////////////
//////// D4 --> R1  ///////////////  D7 --> B4   ///////////////////////
//////// D3 --> R0  ///////////////  D7 --> B3   ///////////////////////
//////// D2 --> G5  ///////////////  D7 --> B2   ///////////////////////
//////// D1 --> G4  ///////////////  D7 --> B1   ///////////////////////
//////// D0 --> G3  ///////////////  D7 --> B0   ///////////////////////
////////////////////////////////////////////////////////////////////////
always@(*) begin 
             case(PIXEL_CNT)
				 0:  Pixel_Data = colour_reg[23:16];//{colour_reg[7:3],colour_reg[5:3]};                      // Red
				 1:  Pixel_Data = colour_reg[15:8];//{colour_reg[2:0],colour_reg[15:13],colour_reg[14:13]};  // Green
				 2:  Pixel_Data = colour_reg[7:0];//{colour_reg[12:8],colour_reg[10:8]};                    // Blue
				 default: Pixel_Data = 8'b0;
				 endcase
           end
/////////////////////////////////////////////////////////////////////////			  
			  

assign init_rom_data = init_rom[cnt[$clog2(N_init)-1:0]];
assign Load = (state==init_load)||(state==load_pixel)||(state==setup_ram);
assign in_data = (state==setup_ram)?load_ram:((controller_state)?(Pixel_Data):(init_rom_data[7:0])); // input data to be loaded
assign controller_state = (state==load_pixel)||(state==write_wait);
assign Imd_read = imr;
assign data_cmd = (state==setup_ram)?1'b0:((controller_state)?(1'b1):(init_rom_data[8])); // data sent was a command or data


////////////////////////////////////////////////////////////////////////
///////////////////// controller state meachine  ///////////////////////
////////////////////////////////////////////////////////////////////////
always@(negedge clk, negedge rst) begin 
if(!rst) begin 
             state <= reset;
             imr <= 0;
             cnt <= 0;
             delay_cnt <= 0;
				 colour_reg <= 0;
				 PIXEL_CNT <= 0;
				 colour_load_comp <= 0;
         end 
else begin 
    case(state) 
    reset: begin 
             state <= delay;
             imr <= 0;
             cnt <= 0;
             delay_cnt <= 0;
				 colour_reg <= 0;
				 PIXEL_CNT <= 0;
				 colour_load_comp <= 0;
           end 
    init_load: begin
                if(load_comp) begin 
                    state <= init_wait;
                    imr <= 0;
                    cnt <= cnt + 1;
                    delay_cnt <= 0;
                end 
                else state <= init_load;
               end 
    init_wait: begin 
                if(Write_comp) begin 
                    if(cnt==N_init-1) state <= delay;
                    else if(cnt>=N_init)  state <= setup_ram;
                    else state <= init_load;
                               end
                else state <= init_wait;    
               end  
    delay: begin 
                  if(delay_cnt>4000000) begin state <= init_load; delay_cnt <= 0; end 
                  else begin state <= delay; delay_cnt <= delay_cnt + 1; end
               end
    setup_ram: begin 
                 if(load_comp&Write_comp) begin 
                    state <= load_colour;
                    imr <= 0;
                 end
                 else begin state <= setup_ram; imr <= 0; end
               end  
    load_colour: begin 
	                 if(VS) begin state <= setup_ram; imr <= 0; end
						  else if(colour_ready)  begin 
						                            state <= load_pixel; 
										                imr <= 0; 
															 colour_reg <= colour_data;
															 PIXEL_CNT <= 0;
															 colour_load_comp <= 1;
														 end 
                 end 
    load_pixel: begin 
	                 imr <= 0;
						  state <= (load_comp)?write_wait:load_pixel;
						  PIXEL_CNT <= (load_comp)?PIXEL_CNT + 1:PIXEL_CNT;
                end   
    write_wait: begin 
	                colour_load_comp <= 0;
                   if(Write_comp) begin 
                        if(PIXEL_CNT == 3) state <= load_colour;
                        else state <= load_pixel;
                   end
                   else state <= write_wait;
                end  
    default: state <= reset;        
    endcase
end
end

endmodule