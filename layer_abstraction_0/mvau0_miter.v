`timescale 1 ps / 1 ps

module mvau0_miter
(
    //=========================================================
    // Shared Inputs
    //=========================================================
    input          ap_clk,
    input          ap_rst_n,

    // Input activation stream
    input  [39:0]  in0_V_TDATA,
    input          in0_V_TVALID,

    // Weight stream
    input  [1279:0] weights_V_TDATA,
    input           weights_V_TVALID,

    // Output handshake
    input          out_V_TREADY,

    //=========================================================
    // Outputs (for bind/checker)
    //=========================================================
    output [31:0] out_V_TDATA_golden,
    output        out_V_TVALID_golden,

    output [31:0] out_V_TDATA_faulty,
    output        out_V_TVALID_faulty
);

    //=========================================================
    // Internal handshake signals
    //=========================================================

    wire in0_V_TREADY_golden;
    wire in0_V_TREADY_faulty;

    wire weights_V_TREADY_golden;
    wire weights_V_TREADY_faulty;

    //=========================================================
    // Golden DUT
    //=========================================================

    MVAU_hls_0 golden (
        .ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),

        .in0_V_TDATA(in0_V_TDATA),
        .in0_V_TVALID(in0_V_TVALID),
        .in0_V_TREADY(in0_V_TREADY_golden),

        .weights_V_TDATA(weights_V_TDATA),
        .weights_V_TVALID(weights_V_TVALID),
        .weights_V_TREADY(weights_V_TREADY_golden),

        .out_V_TDATA(out_V_TDATA_golden),
        .out_V_TVALID(out_V_TVALID_golden),
        .out_V_TREADY(out_V_TREADY)
    );

    //=========================================================
    // Faulty DUT
    //=========================================================

    MVAU_hls_0 faulty (
        .ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),

        .in0_V_TDATA(in0_V_TDATA),
        .in0_V_TVALID(in0_V_TVALID),
        .in0_V_TREADY(in0_V_TREADY_faulty),

        .weights_V_TDATA(weights_V_TDATA),
        .weights_V_TVALID(weights_V_TVALID),
        .weights_V_TREADY(weights_V_TREADY_faulty),

        .out_V_TDATA(out_V_TDATA_faulty),
        .out_V_TVALID(out_V_TVALID_faulty),
        .out_V_TREADY(out_V_TREADY)
    );

    //=========================================================
    // Optional comparator
    //=========================================================

    wire outputs_equal;

    assign outputs_equal =
        (out_V_TVALID_golden == out_V_TVALID_faulty) &&
        (out_V_TDATA_golden  == out_V_TDATA_faulty);

endmodule