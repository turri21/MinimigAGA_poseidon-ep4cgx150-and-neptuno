module profile_cpu (
	input clk,
	input reset_n,
	input clkena,
	input [1:0] cpustate,
	input sel_chip,
	input sel_kick,
	input sel_fast24,
	input sel_fast32
);

// Sizes of histogram buckets and categories

localparam categories_log2 = 2;

localparam accesstypes_log2 = 2;

localparam buckets_log2 = 4;

reg active=1'b0;

// Counter
reg [buckets_log2+1:0] counter; // Cycle count will be a multiple of 4, so add two bits and omit the lowest two when logging
reg [categories_log2-1:0] category;
reg [accesstypes_log2-1:0] accesstype;
reg [buckets_log2-1:0] cyclecount;

always @(posedge clk) begin
	if(sel_chip)
		category<=2'b00;
	else if(sel_kick)
		category<=2'b01;
	else if(sel_fast24)
		category<=2'b10;
	else if(sel_fast32)
		category<=2'b11;
		
	accesstype<=cpustate;

	if(active && !(&counter))	// Saturate counter at maximum
		counter<=counter+1;
	if(clkena)
		counter <= 0;
end

localparam addr_log2 = categories_log2 + accesstypes_log2 + buckets_log2;

reg [31:0] storage [2**addr_log2];
reg [addr_log2-1:0] wrptr;
reg [addr_log2-1:0] rdptr;
reg wren;
reg [31:0] wrdata;

// Write side

localparam S_INIT = 0;
localparam S_CLR = 1;
localparam S_IDLE = 2;
localparam S_READ = 3;
localparam S_WRITE = 4;
reg [3:0] state;

reg [31:0] storage_q;
always @(posedge clk) begin
	wren<=1'b0;
	case(state)
		S_INIT: begin
			wrptr<=1;
			state<=S_CLR;
		end	
		S_CLR: begin
			storage[wrptr]<=0;
			wrptr<=wrptr+1;
			if(!(|wrptr))
				state<=S_IDLE;
		end
		S_IDLE: begin
			if(clkena && active) begin
				rdptr<={category,counter[buckets_log2+1:2],accesstype};
				wrptr<={category,counter[buckets_log2+1:2],accesstype};
				state<=S_READ;
			end
		end
		S_READ:
			state <= S_WRITE;
		S_WRITE: begin
			storage[wrptr]<=storage_q+ (&storage_q ? 1'b0 : 1'b1); // Clamp to prevent overflow
			state <= S_IDLE;
		end

	endcase

	storage_q<=storage[rdptr];

	if(jtag_reset || !reset_n)
		state<=S_INIT;

end


reg [31:0] clkenacounter;

always @(posedge clk) begin
	if(clkena && active)
		clkenacounter<=clkenacounter + (&clkenacounter ? 1'b0 : 1'b1); // Clamp to prevent overflow
	if(jtag_reset || !reset_n)
		clkenacounter<=0;
end


// Virtual JTAG remote interface:

reg [7:0] jtag_cmd;

reg [addr_log2-1:0] rdptr_j;
reg [31:0] jtag_d;

always @(posedge clk) begin
	case(jtag_cmd)
		8'h02: jtag_d <= storage[rdptr_j];
		8'h03: jtag_d <= clkenacounter;
		default: ;
	endcase
end


// Data received from the host computer

reg jtag_reset;
reg jtag_report;

reg jtag_req;
reg jtag_ack;
reg jtag_wr;
wire [31:0] jtag_q;

always @(posedge clk) begin
	jtag_reset<=1'b0;

	jtag_report<=1'b0;

	if(jtag_ack && !jtag_wr) begin
		jtag_cmd <= jtag_q[31:24];
		case(jtag_q[31:24]) // Interpret the highest 8 bits as a command byte

			8'h00: active <= 1'b0;
			8'h01: active <= 1'b1;
			8'h02: begin
				active <= 1'b0;
				jtag_report<=1'b1;
			end
			8'h03: begin
				jtag_report<=1'b1;
			end

			8'hff: jtag_reset<=1'b1; // Command 0xff: reset

		endcase
	end
	
	if(!reset_n)
		active<=1'b0;
end


// Plumbing

always @(posedge clk) begin
	jtag_req<=!jtag_ack;

	if(jtag_ack && jtag_wr) begin
		case(jtag_cmd)
			8'h02: begin
				rdptr_j<=rdptr_j+1;
				jtag_wr <= ~(&rdptr_j);
			end
			8'h03: jtag_wr <= 1'b0;
			default: ;
		endcase
	end

	if(jtag_report) begin
		rdptr_j<=0;
		jtag_wr<=1'b1;
	end

	if(!reset_n)
		rdptr_j<={addr_log2{1'b1}};
end


// This bridge is borrowed from the EightThirtyTwo debug interface

debug_bridge_jtag #(.id('h0068)) bridge (
	.clk(clk),
	.reset_n(reset_n),
	.d(jtag_d),
	.q(jtag_q),
	.req(jtag_req),
	.wr(jtag_wr),
	.ack(jtag_ack)
);

endmodule

