


module FFT(input sys_clk,rst,PCLK,VS,HS,MISO,
           input [7:0] OV7670_In_data,
			  output xclk,SCL,ov7670_reset, 
			  inout SDA,
			  output D_C,CS,Reset,MOSI,SCK);


wire [7:0] read_data,red_pixel,green_pixel,blue_pixel;
wire Init_Comp,clk_50M,clk_10M;
//wire [15:0] colour_data;
wire [23:0] colour_data;
wire colour_ready,colour_load_comp;



/////////// instanciate TFT Display Controller  //////////////////
//TFT_Display_Controller2 TFT_Display (clk_50M,rst,MISO,VS,colour_ready,colour_data,D_C,CS,Reset,MOSI,SCK,colour_load_comp);
  TFT_Display_Controller2 TFT_Display (clk_50M,rst,MISO,VS,colour_ready,colour_data,D_C,CS,Reset,MOSI,SCK,colour_load_comp);

///////// instinciate the SCCB controller ////////
SCCB_Controller SCCB_init(sccb_clk2,rst,sccb_clk1,SCL,Init_Comp,ov7670_reset,SDA,read_data);

///////// instatnciate the OV7670_Pixel_Read ////
//Pixel_Capture(clk_50M,clk_10M,rst,HS,colour_load_comp,Init_Comp,PCLK,OV7670_In_data,colour_data,colour_ready,xclk);
Convolute2 (clk_50M,clk_10M,rst,HS,colour_load_comp,Init_Comp,PCLK,OV7670_In_data,red_pixel,green_pixel,blue_pixel,colour_ready,xclk);

//////////  PLL //////////////
PLL1 Clocks(sys_clk,sccb_clk1,sccb_clk2);
PLL2 clock50(sys_clk,clk_10M,clk_50M);

assign colour_data = {red_pixel,green_pixel,blue_pixel};

endmodule