module half_3(s,c,a,b) ;
input a,b;
output reg s,c;
always @(*)
begin
s=a^b;
c=a&b;
end

endmodule
