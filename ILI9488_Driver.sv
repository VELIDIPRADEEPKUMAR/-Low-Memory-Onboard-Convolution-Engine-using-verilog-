




module ILI9488_Driver(input clk,rst,Load,Imd_read,data_cmd,MISO, 
                          input [7:0] in_data, 
                          output reg D_C,Write_comp,Read_comp,CS,
                          output Reset,MOSI,SCK,load_comp,
                          output reg [7:0] Data_read);

localparam reset = 2'd0;
localparam load = 2'd1;
localparam write = 2'd3;
localparam read = 2'd2;

reg [7:0] Data_write;
reg R; // regester to store imediate read comand
reg [1:0] state; // state regester
reg [2:0] cnt;
wire Read;

assign Read = (state==read)||(state==load);
//assign Write_comp = (state==load);
assign Reset = !(state==reset);
assign MOSI = Data_write[7];
assign SCK = clk&&(!CS);
assign load_comp = (state==write);

always@(posedge clk, negedge rst) begin        // read data from MISO data line;
    if(!rst) Data_read <= 0;
    else if(Read) Data_read <= {Data_read[6:0],MISO};
end

always@(negedge clk, negedge rst) begin 
if(!rst) begin 
             Data_write <= 0;
             R <= 0;
             state <= reset;
             D_C <= 0; 
             cnt <= 0;
             Write_comp <= 0;
             Read_comp <= 0;
             CS <= 1;
          end 
else      begin 
    case(state) 
    reset: begin 
             Data_write <= 0;
             R <= 0;
             state <= load;
             D_C <= 0;
             cnt <= 0;
             Write_comp <= 0;
             Read_comp <= 0;
             CS <= 1;
           end    
    load: begin 
             if(Load) begin 
                        Data_write <= in_data;
                        D_C <= data_cmd;
                        state <= write;
                        R <= Imd_read;
                        cnt <= 0;
                        Write_comp <= 0;
                        Read_comp <= 0;
                        CS <= 0;
                      end
              else    begin 
                        state <= load;
                        cnt <= 0;
                        Write_comp <= 1;
                        CS <= 1;
                      end
          end
    write: begin 
             CS <= 0;
             if(cnt==3'd6) begin
                             Read_comp <= 0;
                             Write_comp <= 1;
                             Data_write <= {Data_write[6:0],1'b0};
                             if(R) begin  
                                    state <= read;
                                    cnt <= 0;
                                   end 
                              else begin 
                                    state <= load;
                                    cnt <= 0;
                                   end
                           end
             else if(cnt==3'd5) begin 
                                  Read_comp <= 0;
                                  Write_comp <= 1;
                                  state <= write;
                                  cnt <= cnt + 1;
                                  Data_write <= {Data_write[6:0],1'b0};
                                end
             else          begin 
                             Read_comp <= 0;
                             Write_comp <= 0;
                             state <= write;
                             cnt <= cnt + 1;
                             Data_write <= {Data_write[6:0],1'b0};
                           end
           end 
    read: begin 
           CS <= 0;
           if(cnt==3'd7) begin 
                           state <= load;
                           cnt <= 0;
                           R <= 0;
                           Write_comp <= 1;
                           Read_comp <= 1;
                         end
           else if(cnt===3'd6) begin
                                state <= read;
                                cnt <= cnt + 1;
                                Write_comp <= 1;
                                Read_comp <= 1;
                               end
           else          begin 
                           state <= read;
                           cnt <= cnt + 1;
                           Write_comp <= 1;
                           Read_comp <= 0;
                         end
          end 
    
    default:  state <= reset;
    endcase

         end
end

endmodule
