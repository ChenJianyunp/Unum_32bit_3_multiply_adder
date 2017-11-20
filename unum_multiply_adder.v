//32-bit multiply-adder (a*b+c) Universal number(unum)-Type III with 3-bit exponent bit in pipeline structure
//Dased on the document in http://superfri.org/superfri/article/view/137/232
//LZC(leading zero counter) module is designed based on "MODULAR DESIGN OF FAST LEADING ZEROS COUNTING CIRCUIT" (http://iris.elf.stuba.sk/JEEEC/data/pdf/6_115-05.pdf)
//LZA(leading zero anticipator) module is based on "Leading-zero anticipator (LZA) in the IBIVI RISC System/6000 floating-point execution unit"(http://ieeexplore.ieee.org/document/5389860/)
//Designed by Jianyu CHEN, in Delft, the Netherlands, in 20th Spt, 2017
//Email of designer: chenjy0046@gmail.com


module unum_multiply_adder(
	input clk,
	input[31:0] unum1,
	input[31:0] unum2,
	input[31:0] unum3,
	
	output[31:0] unum_o,
	output NaN
					);
					
					
//1st: check whether the input number is special situations: zero and Inf
//If the number is nagative, change it from 2's complement to original  
reg[1:0] isZero_1;   //isZero[1]: unum1   [0]: unum2    =0 if value is zero
reg isZero3_1;
reg[1:0] isInf_1;	 //isInf[1]: unum1    [0]: unum2    =1 if value is Inf
reg isInf3_1;
reg[31:0] temp1,temp2,temp3;  //store changed or unchange input numbers
reg[4:0] unum1_shift,unum2_shift,unum3_shift; //result of zero/one counting
wire[4:0] n1,n2,n3;//result of leading zero count
wire[30:0] unum1_2s,unum2_2s,unum3_2s;
assign unum1_2s=~unum1[30:0]+31'b1;
assign unum2_2s=~unum2[30:0]+31'b1;
assign unum3_2s=~unum3[30:0]+31'b1;
always@(posedge clk)begin  ////////1st
	if(unum1[30:0]==31'b0)begin isZero_1[1]<=unum1[31]; isInf_1[1]<=unum1[31]; end
	else begin isZero_1[1]<=1'b1; isInf_1[1]<=1'b0;end 
	
	if(unum2[30:0]==31'b0)begin isZero_1[0]<=unum2[31]; isInf_1[0]<=unum2[31]; end
	else begin isZero_1[0]<=1'b1; isInf_1[0]<=1'b0; end
	
	if(unum1[31])begin temp1<=unum1_2s; end  /// change unum from 2nd complement to original
	else begin temp1<=unum1[31:0]; end
	if(unum2[31])begin temp2<=unum2_2s; end
	else begin temp2<=unum2[31:0]; end
	
	unum1_shift<=n1;
	unum2_shift<=n2;
	
	temp1[31]<=unum1[31];
	temp2[31]<=unum2[31];
	////////
	if(unum3[30:0]==31'b0)begin isZero3_1<=unum3[31]; isInf3_1<=unum3[31]; end
	else begin isZero3_1<=1'b1; isInf3_1<=1'b0; end
	
	if(unum3[31])begin temp3<=unum3_2s; end  /// change unum from 2nd complement to original
	else begin temp3<=unum3[31:0]; end
	
	unum3_shift<=n3;
	
	temp3[31]<=unum3[31];
end
LZC lzc1(.x1(unum1_2s),.n(n1));
LZC lzc2(.x1(unum2_2s),.n(n2));
LZC lzc3(.x1(unum3_2s),.n(n3));

//2nd: Left shift the temp so that the exponent bits, sign bit and fraction bits will in the certain positions.
//change regime bits and exponent bits into exponent value in 2's complement format
reg isInf_2;  //if one of the input numbers is Inf, this bit will be 1
reg[31:0] temp1_2,temp2_2,temp3_2;  //[31]:sign bit   [30]: ==1 if component value is negative, ==0 if zero or positive. Useless here      [29:27]:exponent bits [26:1]:fraction bit [0]:Do not care
reg[8:3] expo_num1, expo_num2, expo_num3; //store exponent values
reg NaN_2;
reg isZero_2;
reg isZero3_2;
always@(posedge clk)begin        ///2nd
	temp1_2[30:0]<=temp1[30:0]<<unum1_shift;
	temp2_2[30:0]<=temp2[30:0]<<unum2_shift;
	temp1_2[31]<=temp1[31];
	temp2_2[31]<=temp2[31];	
	
	if(temp1[30]) begin expo_num1[8]<=1'b0; expo_num1[7:3]<=unum1_shift; end
	else begin expo_num1[8]<=1'b1; expo_num1[7:3]<=~unum1_shift; end
	
	if(temp2[30]) begin expo_num2[8]<=1'b0; expo_num2[7:3]<=unum2_shift; end
	else begin expo_num2[8]<=1'b1; expo_num2[7:3]<=~unum2_shift; end

	isInf_2<=isInf_1[1]|isInf_1[0]|isInf3_1;
	NaN_2<=(isInf_1[1]&~isZero_1[0])|(~isZero_1[1]&isInf_1[0]);
	
	isZero_2<=isZero_1[1]&isZero_1[0]&~(isInf_1[1]|isInf_1[0]);   ////caculation of results of Inf and Zero are very similar, so regard Inf as Zero here
	
	////////
	temp3_2[30:0]<=temp3[30:0]<<unum3_shift;
	temp3_2[31]<=temp3[31];
	
	if(temp3[30]) begin expo_num3[8]<=1'b0; expo_num3[7:3]<=unum3_shift; end
	else begin expo_num3[8]<=1'b1; expo_num3[7:3]<=~unum3_shift; end
	
	isZero3_2<=isZero3_1;

end

///3rd: multiple two fractions, add two exponent values
reg isInf_3;  //if one of the input numbers is Inf, this bit will be 1
reg[54:0] frac_numo_3; //[54]:sign bit   [53]:for carry on 			[52]:1.   	[51:0]fraction bits
reg[1:0] expo_sign_3; //[1]: sign value of unum1     [0]: sign value of unum2
reg[8:0] expo_numo_3; //store exponent values
reg NaN_3;
reg[8:0] expo_diff;
reg[27:0] frac_num3_3; //[27]: sign bit      [26]: 1   [25:0]: fraction
reg[8:0] expo_num3_3;
wire[8:0] expo_sum;
wire[53:0] mult_result;
assign expo_sum={expo_num1,temp1_2[28:26]}+{expo_num2,temp2_2[28:26]};
always@(posedge clk)begin         //3rd
	frac_numo_3[54]<=(temp1_2[31]^temp2_2[31])&isZero_2|isInf_2;
	NaN_3<=NaN_2;
	expo_sign_3[1]<=expo_num1[8];
	expo_sign_3[0]<=expo_num2[8];
	expo_numo_3<=expo_sum;
	isInf_3<=isInf_2;
	//////
	expo_diff<=expo_sum-{expo_num3,temp3_2[28:26]};
	if(temp1_2[31]^temp2_2[31]^temp3_2[31]) begin frac_num3_3[25:0]<=~temp3_2[25:0]; end
	begin frac_num3_3[25:0]<=temp3_2[25:0]; end
	frac_num3_3[27]<=temp3_2[31];
	frac_num3_3[26]<=isZero3_2;
	expo_num3_3<={expo_num3,temp3_2[28:26]};
end
frac_mult multiplier1(.clock(clk), .dataa({isZero_2,temp1_2[25:0]}), .datab({isZero_2,temp2_2[25:0]}), .result(mult_result) );

reg[55:0] frac_num3_4,frac_numo_4;  //[55]:sign    [54:53]:carry       [52]: 1      [51:0]: fraction
reg[8:0] expo_numo_4;
reg[8:0] expo_diff_4;
reg NaN_4;
reg isInf_4;
always@(posedge clk)begin         //4th
	if(expo_diff[8])begin expo_numo_4<=expo_num3_3; expo_diff_4[7:0]<=~expo_diff[7:0]+8'd1; end
	else begin expo_numo_4<=expo_numo_3;  expo_diff_4<=expo_diff[7:0]; end
	frac_num3_4<={frac_num3_3[27],2'b0,frac_num3_3[26:0],26'd0};
	
	
	//frac_numo_4[54]<={frac_numo_3[54],1'b0,frac_numo_3[53:0]};
	frac_numo_4[55]<=frac_numo_3[54];
	expo_diff_4[8]<=expo_diff[8];
	NaN_4<=NaN_3;
	isInf_4<=isInf_3;
end

reg[55:0] frac_num3_5,frac_numo_5;  //[55]:sign    [54:53]:carry       [52]: 1      [51:0]: fraction
reg[8:0] expo_numo_5;
reg NaN_5;
reg isInf_5;
always@(posedge clk)begin         //5th
	if(expo_diff_4[8])begin  frac_numo_5[54:0]<={1'b0, mult_result}>>expo_diff_4[7:0]; frac_num3_5[54:0]<=frac_num3_4[54:0]; end
	else begin frac_num3_5[54:0]<=frac_num3_4[54:0]>>expo_diff_4[7:0];frac_numo_5[54:0]<={1'b0, mult_result};end
	frac_numo_5[55]<=frac_numo_4[55];
	frac_num3_5[55]<=frac_num3_4[55];
	expo_numo_5<=expo_numo_4;
	NaN_5<=NaN_4;
	isInf_5<=isInf_4;
end



reg[56:0] frac_numo_6;  //[55]:sign    [54:53]:carry       [52]: 1      [51:0]: fraction
reg[8:0] expo_numo_6;
wire[54:0] frac_num3_6=(frac_num3_5[55]^frac_numo_5[55])?~frac_num3_5[54:0]:frac_num3_5[54:0];
reg NaN_6;
reg isInf_6;
reg[4:0] shift;
wire[4:0] shiftw;
wire[55:0] frac_numo_1s,frac_num3_1s;
assign frac_numo_1s={frac_numo_5[55],(frac_numo_5[55]?~frac_numo_5[54:0]:frac_numo_5[54:0])};
assign frac_num3_1s={frac_num3_5[55],(frac_num3_5[55]?~frac_num3_5[54:0]:frac_num3_5[54:0])};
always@(posedge clk)begin         //6th
	//frac_numo_6<=frac_numo_5+{frac_num3_5[55],frac_num3_6};
	frac_numo_6[56:0]<=frac_numo_1s+frac_num3_1s;
	expo_numo_6<=expo_numo_5;
	NaN_6<=NaN_5;
	isInf_6<=isInf_5;
	
	shift<=shiftw;
end
LZA_fraction lza_fraction1(.num1(frac_numo_1s[55:25]),.num2(frac_num3_1s[55:25]), .n(shiftw) );


reg[55:0] frac_numo_7;  //[55]:sign    [54:53]:carry       [52]: 1      [51:0]: fraction
reg[8:0] expo_numo_7;
reg[4:0] shift_7;
reg NaN_7;
reg isInf_7;
//wire[4:0] shift;
//reg[4:0] fraction;

wire[55:0] sum_7;
assign sum_7={frac_numo_6[55],frac_numo_6[55]?~(frac_numo_6[54:0]+{54'd0,frac_numo_6[56]}):(frac_numo_6[54:0]+{54'd0,frac_numo_6[56]})};
always@(posedge clk)begin         //7th
	
	frac_numo_7[55:0]<=sum_7;

	expo_numo_7<=expo_numo_6+9'd2-{4'b0,shift};
	NaN_7<=NaN_6;
	isInf_7<=isInf_6;
	shift_7<=shift;
	
end


reg[55:0] frac_numo_8;  //[55]:sign    [54:53]:carry       [52]: 1      [51:0]: fraction
reg[8:0] expo_numo_8;
reg NaN_8;
reg isInf_8;
wire[29:0] shift_result;
assign shift_result=frac_numo_7[54:25]<<shift_7;
always@(posedge clk)begin         //8th
	if(shift_result[29])begin frac_numo_8[54:26]<=shift_result[29:1]; end
	else begin frac_numo_8[54:26]<=shift_result[28:0]; end
	
	frac_numo_8[55]<=frac_numo_7[55];
	expo_numo_8<=expo_numo_7-{8'b0, ~shift_result[29]};
	
	NaN_8<=NaN_7;
	isInf_8<=isInf_7;
	
end


reg [55:24] frac_numo_9;
reg round;
wire signed[31:0] shift_num;
reg NaN_9;
reg isInf_9;
assign shift_num={~expo_numo_8[8],expo_numo_8[8],expo_numo_8[2:0],frac_numo_8[53:27]};
always@(posedge clk)begin         //9th
	{frac_numo_9[54:24],round}<=shift_num>>>(expo_numo_8[8]?(~expo_numo_8[7:3]):expo_numo_8[7:3]);
	frac_numo_9[55]<=frac_numo_8[55];
	NaN_9<=NaN_8;
	isInf_9<=isInf_8;
end

reg[31:0] unumo_10;
reg NaN_10;
always@(posedge clk)begin //10th
	if(isInf_9)begin unumo_10[30:0]<=31'b0; end
	else begin unumo_10[30:0]<={31'b0,round}+(frac_numo_9[55]?(~frac_numo_9[54:24]+31'b1):frac_numo_9[54:24]);end 
	unumo_10[31]<=frac_numo_9[55]|isInf_9;
	NaN_10<=NaN_9;
end

assign unum_o=unumo_10;
assign NaN=NaN_10;

endmodule


//LZC(leading zero counter) module is designed based on MODULAR DESIGN OF FAST LEADING ZEROS COUNTING CIRCUIT (http://iris.elf.stuba.sk/JEEEC/data/pdf/6_115-05.pdf)
module LZC(
			input[30:0] x1,//[32:1] unum  [0]:1
			output[4:0] n
			);
wire[7:0] a;
wire[15:0] z;
reg[31:0] x;
reg [1:0] n1;
wire[2:0] y;
assign n[1:0]=n1[1:0];
assign n[4:2]=y;

always@(*)begin

	if(x1[30]) begin x[31:2]=~x1[29:0]; end			//if the number starts with 1, inverse it
	else begin x[31:2]=x1[29:0]; end
	x[1:0]=2'b10;
	case(y)
	3'b000: n1[1:0]=z[1:0];
	3'b001: n1[1:0]=z[3:2];
	3'b010: n1[1:0]=z[5:4];
	3'b011: n1[1:0]=z[7:6];
	3'b100: n1[1:0]=z[9:8];
	3'b101: n1[1:0]=z[11:10];
	3'b110: n1[1:0]=z[13:12];
	3'b111: n1[1:0]=z[15:14];
	endcase
end
BNE BNE1(.a(a), .y(y));			
NLC NLC7(.x(x[3:0]),		.a(a[7]), 	.z(z[15:14]) );
NLC NLC6(.x(x[7:4]),		.a(a[6]), 	.z(z[13:12]) );
NLC NLC5(.x(x[11:8]),	.a(a[5]),	.z(z[11:10]) );
NLC NLC4(.x(x[15:12]),	.a(a[4]), 	.z(z[9:8])  );
NLC NLC3(.x(x[19:16]),	.a(a[3]), 	.z(z[7:6])  );
NLC NLC2(.x(x[23:20]),	.a(a[2]), 	.z(z[5:4])  );
NLC NLC1(.x(x[27:24]),	.a(a[1]), 	.z(z[3:2])  );
NLC NLC0(.x(x[31:28]),	.a(a[0]), 	.z(z[1:0])  );
endmodule

module LZC_fraction(
			input[31:0] x,
			output[4:0] n
			);
wire[7:0] a;
wire[15:0] z;
reg [1:0] n1;
wire[2:0] y;
assign n[1:0]=n1[1:0];
assign n[4:2]=y;

always@(*)begin

	case(y)
	3'b000: n1[1:0]=z[1:0];
	3'b001: n1[1:0]=z[3:2];
	3'b010: n1[1:0]=z[5:4];
	3'b011: n1[1:0]=z[7:6];
	3'b100: n1[1:0]=z[9:8];
	3'b101: n1[1:0]=z[11:10];
	3'b110: n1[1:0]=z[13:12];
	3'b111: n1[1:0]=z[15:14];
	endcase
end
BNE BNE1(.a(a), .y(y));			
NLC NLC7(.x(x[3:0]),		.a(a[7]), 	.z(z[15:14]) );
NLC NLC6(.x(x[7:4]),		.a(a[6]), 	.z(z[13:12]) );
NLC NLC5(.x(x[11:8]),	.a(a[5]),	.z(z[11:10]) );
NLC NLC4(.x(x[15:12]),	.a(a[4]), 	.z(z[9:8])  );
NLC NLC3(.x(x[19:16]),	.a(a[3]), 	.z(z[7:6])  );
NLC NLC2(.x(x[23:20]),	.a(a[2]), 	.z(z[5:4])  );
NLC NLC1(.x(x[27:24]),	.a(a[1]), 	.z(z[3:2])  );
NLC NLC0(.x(x[31:28]),	.a(a[0]), 	.z(z[1:0])  );
endmodule


module LZA_fraction(
			input[30:0] num1,
			input[30:0] num2,
			output[4:0] n
			);
wire[7:0] a;
wire[15:0] z;
wire[31:0] x;
reg [1:0] n1;
wire[2:0] y;
wire [30:0] LOP_T, LOP_G, LOP_Z; 
wire[30:0] LOP;
assign n[1:0]=n1[1:0];
assign n[4:2]=y;

assign LOP_T[30:0] = num1[30:0] ^ num2[30:0]; 
assign LOP_G[30:0] = num1[30:0] & num2[30:0]; 
assign LOP_Z[30:0] = ~(num1[30:0] | num2[30:0]);

assign LOP[30:0] = {(LOP_T[30:2] & LOP_G[29:1] & ~LOP_Z[28:0] ) |
					(~LOP_T[30:2] & LOP_Z[29:1] & ~LOP_Z[28:0] ) |
					(LOP_T[30:2] & LOP_Z[29:1] & ~LOP_G[28:0] ) |
					(~LOP_T[30:2] & LOP_G[29:1] & ~LOP_G[28:0] ), ~LOP_T[0], 1'b1};
					

					
					
assign x={LOP,1'b0};

always@(*)begin
	
	case(y)
	3'b000: n1[1:0]=z[1:0];
	3'b001: n1[1:0]=z[3:2];
	3'b010: n1[1:0]=z[5:4];
	3'b011: n1[1:0]=z[7:6];
	3'b100: n1[1:0]=z[9:8];
	3'b101: n1[1:0]=z[11:10];
	3'b110: n1[1:0]=z[13:12];
	3'b111: n1[1:0]=z[15:14];
	endcase
end
BNE BNE1(.a(a), .y(y));			
NLC NLC7(.x(x[3:0]),		.a(a[7]), 	.z(z[15:14]) );
NLC NLC6(.x(x[7:4]),		.a(a[6]), 	.z(z[13:12]) );
NLC NLC5(.x(x[11:8]),	.a(a[5]),	.z(z[11:10]) );
NLC NLC4(.x(x[15:12]),	.a(a[4]), 	.z(z[9:8])  );
NLC NLC3(.x(x[19:16]),	.a(a[3]), 	.z(z[7:6])  );
NLC NLC2(.x(x[23:20]),	.a(a[2]), 	.z(z[5:4])  );
NLC NLC1(.x(x[27:24]),	.a(a[1]), 	.z(z[3:2])  );
NLC NLC0(.x(x[31:28]),	.a(a[0]), 	.z(z[1:0])  );
endmodule


module BNE(
			input[7:0] a,
			output[2:0] y 
			);
assign y[2]=a[0]&a[1]&a[2]&a[3];
assign y[1]=a[0]&a[1]&(~a[2]|~a[3]|(a[4]&a[5]));
assign y[0]=a[0]&(~a[1]|(a[2]&~a[3]))|(a[0]&a[2]&a[4]&(~a[5]|a[6]));
endmodule



module NLC(
			input[3:0] x,
			output a,
			output[1:0] z
			);

assign z[1]=~(x[3]|x[2]);
assign z[0]=~(((~x[2])&x[1])|x[3]);
assign a=~(x[0]|x[1]|x[2]|x[3]);
endmodule 