module arbiter(
    clock,
    reset,
    req_o,
    req_1,
    gnt_0,
    gnt_1
);


input clock;
input reset;
input req_0;
input req_1;

output gnt_0;
output gnt_1;
