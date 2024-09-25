`timescale 1ns / 1ps
`include "include.v"

module Weight_Memory #(parameter numWeight = 3, neuronNo=5,layerNo=1,addressWidth=10,dataWidth=16,weightFile="w_1_15.mif") 
    ( 
    input clk,
    input wen,
    input ren,
    input [addressWidth-1:0] wadd,
    input [addressWidth-1:0] radd,
    input [dataWidth-1:0] win,
    output reg [dataWidth-1:0] wout);
    
    reg [dataWidth-1:0] mem [numWeight-1:0];

    `ifdef pretrained //acts as rom because it is predefined, otherwise it would act as a RAM, so ifdef makes sure its defined
        initial
		begin
	        $readmemb(weightFile, mem);// transfers weights to mem
	    end
	`else
		always @(posedge clk)//this stores it as a normal RAM
		begin
			if (wen)
			begin
				mem[wadd] <= win;// writed the weight value into the array memory stored at wadd
			end
		end 
    `endif
    
    always @(posedge clk) 
    begin
        if (ren)
        begin
            wout <= mem[radd];// reads and outputs this memory to wout
        end
    end 
endmodule