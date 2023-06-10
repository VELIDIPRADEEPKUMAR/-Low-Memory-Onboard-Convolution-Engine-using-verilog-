





module Convolute2(input clk_50M,clk_10M,rst,HS,Load_Comp,Init_Comp,PCLK,
                  input [7:0] In_Data, 
						output [7:0] red_pixel,green_pixel,blue_pixel,
						output Load,
						output XCLK);
	 
	 localparam RESET = 0;
	 localparam CAPTURE = 1;
	 localparam WAIT = 3;
	 localparam LOAD = 2;
	 localparam HS_HOLD = 6;
	 
	 
	 //////////////////////////////////// Filter coefficients ////////////////////////////////////////
   // parameter logic [4:0] Filter_coef[2:0][2:0] =  '{'{ 5'd0,  -5'd1,   5'd0},'{-5'd1,   5'd5,  -5'd1},'{ 5'd0,  -5'd1,   5'd0}};
	 localparam [2:0] Div_coef = 0; //
	 
	 reg [2:0] state;
	 reg [15:0] Pixel_Data;
	 reg L; // Odd or Even pixel data 
	 reg reg_clk;
	 wire [15:0] conv_matrix_R1,conv_matrix_R2,conv_matrix_R3;
	 wire [15:0] frame_buff_data_0,frame_buff_data_1,frame_buff_data_2;
	 reg [8:0] addr; /////// memory adress 
	 wire wr0,wr1,wr2,rd0,rd1,rd2;
	 
	 /////////// Memory for buffering 3 rows of Image frame ////////////
	 row_ram frame_buff0(clk_50M,wr0,rd0,Pixel_Data,addr,addr,frame_buff_data_0);
	 row_ram frame_buff1(clk_50M,wr1,rd1,Pixel_Data,addr,addr,frame_buff_data_1);
	 row_ram frame_buff2(clk_50M,wr2,rd2,Pixel_Data,addr,addr,frame_buff_data_2);
	 
	 ///////// Buffer for storing the Pixel Data for Computing convolution ////////
	 reg [15:0] conv_matrix_3x3 [2:0][2:0];
	 
	 //////////// Buffer index //////////
	 reg [1:0] buff_index;   // indexing which buffer to load into convolue matrix buffer
	 
	 
	 
	 
	 ///////////////// logic for multiplixing image frame buffer to convolve matrix buffer //////////
	 always@(*) begin 
	 case(buff_index) 
	 0: begin 
	       conv_matrix_R1 = frame_buff_data_1; wr1 = 0; rd1 = 1&(state==LOAD);
			 conv_matrix_R2 = frame_buff_data_2; wr2 = 0; rd2 = 1&(state==LOAD);
			 conv_matrix_R3 = Pixel_Data;        wr0 = 1&(state==LOAD); rd0 = 0;
		 end
	 1: begin 
	       conv_matrix_R1 = frame_buff_data_2; wr2 = 0; rd2 = 1&(state==LOAD);
			 conv_matrix_R2 = frame_buff_data_0; wr0 = 0; rd0 = 1&(state==LOAD);
			 conv_matrix_R3 = Pixel_Data;        wr1 = 1&(state==LOAD); rd1 = 0;
		 end
	 2: begin 
	       conv_matrix_R1 = frame_buff_data_0; wr0 = 0; rd0 = 1&(state==LOAD);
			 conv_matrix_R2 = frame_buff_data_1; wr1 = 0; rd1 = 1&(state==LOAD);
			 conv_matrix_R3 = Pixel_Data;        wr2 = 1&(state==LOAD); rd2 = 0;
		 end
	 default: begin 
	           conv_matrix_R1 = 0; wr0 = 0; rd0 = 0;
			     conv_matrix_R2 = 0; wr1 = 0; rd1 = 0;
			     conv_matrix_R3 = 0; wr2 = 0; rd2 = 0;
	          end
	 endcase
	 end
	 //////////////////////////////////////////////////////////
	 
	 assign Load = (state==LOAD);
	 assign XCLK = ((state==RESET)||(state==HS_HOLD))?clk_10M:reg_clk;
	 
	 conv2 #(0) Red_conv(conv_matrix_3x3,red_pixel); // Red colour conv
	 conv2 #(2) Blue_conv(conv_matrix_3x3,blue_pixel); // blue colour conv
	 conv2 #(1) Green_conv(conv_matrix_3x3,green_pixel); // green colour conv
	 
	 

	/////////// state meachine //////////////// 
	 always@(posedge clk_50M) begin 
		if(!rst) begin 
						L <= 0;
						state <= 0;
						reg_clk <= 1;
						addr <= 0;
						buff_index <= 2;
	            end
	   else 
			case(state) 
			RESET: begin L <= 0; state <= (Init_Comp)?CAPTURE:RESET; reg_clk <= 1; addr <= 0;buff_index <= 2;end
			CAPTURE: begin 
							if(!HS) begin 
										state <= HS_HOLD;
										L <= 0;
										buff_index <= (buff_index==2)?0:((buff_index==1)?2:((buff_index==0)?1:2));
									  end
							else begin      
												 L <= ~L;
												 state <= (L)?LOAD:WAIT;
												 Pixel_Data <= {In_Data,Pixel_Data[15:8]};
												 reg_clk <= 0;
							     end
			         end
			WAIT:    begin 
			            if(HS) begin state <= CAPTURE; reg_clk <= 1;  end
					  	   else begin state <= HS_HOLD; buff_index <= (buff_index==2)?0:((buff_index==1)?2:((buff_index==0)?1:2)); end
				      end 
			LOAD:    begin  
						  if(Load_Comp) begin 
						                  state <= WAIT;
												//frame_buff[addr][buff_index] <= Pixel_Data;
											   addr <= addr + 1;
											   conv_matrix_3x3[0][0] <= conv_matrix_R1; conv_matrix_3x3[0][1] <= conv_matrix_3x3[0][0]; conv_matrix_3x3[0][2] <= conv_matrix_3x3[0][1];
												conv_matrix_3x3[1][0] <= conv_matrix_R2; conv_matrix_3x3[1][1] <= conv_matrix_3x3[1][0]; conv_matrix_3x3[1][2] <= conv_matrix_3x3[1][1];
												conv_matrix_3x3[2][0] <= conv_matrix_R3; conv_matrix_3x3[2][1] <= conv_matrix_3x3[2][0]; conv_matrix_3x3[2][2] <= conv_matrix_3x3[2][1];
						                end 
						end 
			HS_HOLD: begin 
			           state <= (HS&&(!clk_10M))?WAIT:HS_HOLD;
						  L <= 0; 
						  addr <= 0;
						  end 
			default: state <= RESET;
			endcase
	 end 
	 
	 
endmodule 



////////////////// Convolutation module ///////////////////////

module conv2#(parameter colour = 0)(input [15:0] conv_matrix[2:0][2:0], output reg [7:0] convolue_3x3);


parameter integer filter_coef[2:0][2:0] =  '{'{ 5'd0,  -5'd1,   5'd0},'{-5'd1,   5'd5,  -5'd1},'{ 5'd0,  -5'd1,   5'd0}};
				 

	 integer matrix_pixel_data[2:0][2:0];
	 integer mult_pixel_data[2:0][2:0];
	 integer accumulated_mult_data;
	 reg [15:0] current_pixel_data;
	 
always @(*) begin 
	 //////////// Assigning Pixel  Data from colour data ////////////
	 for(integer i=0;i<3;i=i+1) begin
		for(integer j=0;j<3;j=j+1) 
			begin 
			   current_pixel_data = conv_matrix[i][j];
				case(colour)
						0: matrix_pixel_data[i][j] = {current_pixel_data[7:3],current_pixel_data[5:3]}; // reg
						1: matrix_pixel_data[i][j] = {current_pixel_data[2:0],current_pixel_data[15:13],current_pixel_data[14:13]}; // green
						2: matrix_pixel_data[i][j] = {current_pixel_data[12:8],current_pixel_data[10:8]}; // blue
						default: matrix_pixel_data[i][j] = 0;
				endcase 
			end
			end
	  //////////////////////////////////////////////////////////////////
	  
	  /////////// Computing multliplication with the fulter coeff ////////////
	  for(integer i=0;i<3;i=i+1)  begin 
		  for(integer j=0;j<3;j=j+1)  begin 
				 mult_pixel_data[i][j] =  matrix_pixel_data[i][j]*filter_coef[i][j];
				                      end 
											   end
     /////////////////////////////////////////////////////////////////////////
	  
	  ////////// Accumulating the multlipllied data //////////////////////
	  accumulated_mult_data = ((mult_pixel_data[0][0] + mult_pixel_data[0][1]) + (mult_pixel_data[0][2] + mult_pixel_data[1][0])) + 
	                          ((mult_pixel_data[1][1] + mult_pixel_data[1][2]) + (mult_pixel_data[2][0] + mult_pixel_data[2][1])) + 
									  mult_pixel_data[2][2];
	  ///////////////////////////////////////////////////////////////////		  
							
	  convolue_3x3 = (|accumulated_mult_data[31:15])?-accumulated_mult_data:accumulated_mult_data;
end
				 
endmodule 






////////// Ram module for storing row data of the frame ////////////

module row_ram (input clk,wr,rd, input [15:0] wdata, input [8:0] waddr, input [8:0] raddr, output reg [15:0] odata);


reg [15:0] ram[319:0];  

always@(posedge clk) begin 
if(wr) ram[waddr] <= wdata;
if(rd) odata <= ram[raddr];
end

endmodule 