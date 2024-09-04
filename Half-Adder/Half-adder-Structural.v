module half_str(s,c,a,b);
input a,b;
output s,c;
xor (s,a,b) ;
and (c,a,b) ;
endmodule
