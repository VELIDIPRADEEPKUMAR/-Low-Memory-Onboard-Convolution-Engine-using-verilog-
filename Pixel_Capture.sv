




module Pixel_Capture(input clk_50M,clk_10M,rst,HS,Load_Comp,Init_Comp,PCLK,
                  input [7:0] In_Data, 
						output reg [15:0] Pixel_Data,
						output Load,
						output XCLK);
	 
	 localparam RESET = 0;
	 localparam CAPTURE = 1;
	 localparam WAIT = 3;
	 localparam LOAD = 2;
	 localparam HS_HOLD = 6;
	 
	 reg [2:0] state;
	 reg L; // Odd or Even pixel data 
	 reg reg_clk;
	 
	 
	 assign Load = (state==LOAD);
	 assign XCLK = ((state==RESET)||(state==HS_HOLD))?clk_10M:reg_clk;

	 
	 always@(posedge clk_50M) begin 
		if(!rst) begin 
						L <= 0;
						state <= 0;
						reg_clk <= 1;
	            end
	   else 
			case(state) 
			RESET: begin L <= 0; state <= (Init_Comp)?CAPTURE:RESET; reg_clk <= 1; end
			
			CAPTURE: begin 
							if(!HS) begin 
										state <= HS_HOLD;
										L <= 0;
									  end
							else begin      
							       //if(PCLK) begin 
												 L <= ~L;
												 state <= (L)?LOAD:WAIT;
												 Pixel_Data <= {In_Data,Pixel_Data[15:8]};
												 reg_clk <= 0;
												// end
							     end
			         end
			WAIT:    begin 
			            if(HS) begin state <= CAPTURE; reg_clk <= 1;  end
					  	   else begin state <= HS_HOLD; end
				      end 
			LOAD:    begin state <= (Load_Comp)?WAIT:LOAD; end 
			HS_HOLD: begin state <= (HS&&(!clk_10M))?WAIT:HS_HOLD; L <= 0; end 
			default: state <= RESET;
			endcase
	 end 
	 
	 
endmodule 