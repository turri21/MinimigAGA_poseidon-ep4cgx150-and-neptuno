module rs232_jtag (
	input clk,
	input reset_n,
	input rxd,
	output txd
);


reg [15:0] clkdiv;
reg [7:0] txdata;
reg txreq;
wire txack;

wire [7:0] rxdata;
wire rxreq;
reg rxack;

wire [4:0] uart_status;
wire rxempty = uart_status[2];

buffered_uart uart (
	.clk(clk),
	.reset(jtag_reset | ~reset_n),
	.rxd(rxd),
	.txd(txd),
	.clkdiv(clkdiv),
	.txdata(txdata),
	.txreq(txreq),
	.txack(txack),
	.rxdata(rxdata),
	.rxreq(rxreq),
	.rxack(rxack),
	.status(uart_status)
);


// Virtual JTAG remote interface:

reg [7:0] jtag_cmd;

reg [31:0] jtag_d;

always @(posedge clk) begin
	case(jtag_cmd)
		8'h00: jtag_d <= {27'b0,uart_status};
		8'b01: jtag_d <= {24'b0,rxdata};
		default: jtag_d <= 0;
	endcase
end


// Plumbing

reg jtag_reset;
reg jtag_req;
reg jtag_wr;
reg jtag_ack;
wire [31:0] jtag_q;

always @(posedge clk) begin
	jtag_reset<=1'b0;
	jtag_req<=~jtag_ack;

	if(jtag_ack && !jtag_wr) begin
		jtag_cmd <= jtag_q[31:24];
		case(jtag_q[31:24]) // Interpret the highest 8 bits as a command byte
			8'h00: jtag_wr<=1'b1;
			8'h01: begin
				jtag_wr<=rxreq ^ rxack;
			end
			8'h02: begin
				txdata<=jtag_q[7:0];
				txreq<=~txack;
			end
			8'h03: clkdiv[15:0] <= jtag_q[15:0];

			8'hff: jtag_reset<=1'b1; // Command 0xff: reset
			default: ;
		endcase
	end

	if(jtag_ack && jtag_wr) begin
		case(jtag_cmd) // Interpret the highest 8 bits as a command byte
			8'h00: jtag_wr<=1'b0;
			8'h01: begin
				if(rxempty)
					jtag_wr<=1'b0;
				rxack<=rxreq;
			end
			default:
				jtag_wr<=1'b0;
		endcase
	end

	if(!reset_n) begin
		jtag_wr<=1'b0;
	end
end


// This bridge is borrowed from the EightThirtyTwo debug interface

debug_bridge_jtag #(.id('h0232)) bridge (
	.clk(clk),
	.reset_n(reset_n),
	.d(jtag_d),
	.q(jtag_q),
	.req(jtag_req),
	.wr(jtag_wr),
	.ack(jtag_ack)
);

endmodule


module buffered_uart (
	input clk,
	input reset,
	input rxd,
	output txd,
	input [15:0] clkdiv,
	input [7:0] txdata,
	input txreq,
	output reg txack,
	output reg [7:0] rxdata,
	output reg rxreq,
	input rxack,
	output [4:0] status
);


// Transmit side

wire txready;
reg [7:0] txdata_i;
reg [7:0] txbuf[256];
reg [7:0] txrdptr;
reg [7:0] txwrptr;
reg [7:0] txwrnext;
reg txfull;
reg txempty;

reg txgo;

always @(*) begin
	txwrnext <= txwrptr+1;
	txfull <= (txwrnext==txrdptr) ? 1'b1 : 1'b0;
	txempty <= (txwrptr==txrdptr) ? 1'b1 : 1'b0;
end

always @(posedge clk) begin
	if(reset) begin
		txrdptr<=0;
		txwrptr<=0;
		txack<=txreq;
		txgo<=1'b0;
	end
	if(txreq!=txack) begin
		if(!txfull) begin
			txbuf[txwrptr]<=txdata;
			txwrptr<=txwrnext;
			txack<=txreq;
		end
	end
	if(txready && !txempty) begin
		txdata_i<=txbuf[txrdptr];
		txgo<=1'b1;
	end
	if(txgo && !txready) begin
		txgo<=1'b0;
		txrdptr<=txrdptr+1;
	end
end


// Receive side

reg [7:0] rxdata_i;
reg [7:0] rxbuf[256];
reg [7:0] rxrdptr;
reg [7:0] rxwrptr;
reg [7:0] rxwrnext;
reg rxfull;
reg rxempty;
reg rxoverflow;

reg rxready;
reg rxstb;

always @(*) begin
	rxwrnext <= rxwrptr+1;
	rxfull <= (rxwrnext==rxrdptr) ? 1'b1 : 1'b0;
	rxempty <= (rxwrptr==rxrdptr) ? 1'b1 : 1'b0;
end

always @(posedge clk) begin
	if(reset) begin
		rxoverflow<=1'b0;
		rxrdptr<=0;
		rxwrptr<=0;
		rxreq<=rxack;
	end
	if(rxack==rxreq && !rxempty) begin
		rxdata<=rxbuf[rxrdptr];
		rxrdptr<=rxrdptr+1;
		rxreq<=~rxack;
		rxoverflow<=1'b0;
	end
	if(rxstb) begin
		if(rxfull)
			rxoverflow<=1'b1;
		else begin
			rxbuf[rxwrptr]<=rxdata_i;
			rxwrptr<=rxwrnext;
		end
	end
end


// UART

simple_uart uart (
	.clk(clk),
	.reset(~reset),

	.txdata(txdata_i),
	.txgo(txgo),
	.txready(txready),

	.rxdata(rxdata_i),
	.rxready(rxready),
	.rxint(rxstb),
	.txint(),
	.clock_divisor(clkdiv),

	.rxd(rxd),
	.txd(txd)
);

assign status = {rxoverflow,rxfull,rxempty,txfull,txempty};

endmodule

