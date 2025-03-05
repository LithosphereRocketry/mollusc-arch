/*
Simple module to detect whether a given register requires kernel privilege.

*/

module privileged(
        input [3:0] reg_addr,
        output priv    
    );
    assign priv = (reg_addr >= 4'd12);
endmodule