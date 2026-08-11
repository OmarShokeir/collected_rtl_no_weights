`timescale 1 ps / 1 ps

module finn_miter
(
    //=========================================================
    // Shared Inputs
    //=========================================================
    input         ap_clk,
    input         ap_rst_n,

    input  [39:0] s_axis_0_tdata,
    input         s_axis_0_tvalid,

    input         m_axis_0_tready,

    //=========================================================
    // Outputs (for bind/checker)
    //=========================================================
    output [7:0] m_axis_0_tdata_golden,
    output       m_axis_0_tvalid_golden,

    output [7:0] m_axis_0_tdata_faulty,
    output       m_axis_0_tvalid_faulty
);

    //=========================================================
    // Internal handshake signals
    //=========================================================

    wire s_axis_0_tready_golden;
    wire s_axis_0_tready_faulty;

    //=========================================================
    // Golden DUT
    //=========================================================

    finn_design_wrapper golden (
        .ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),

        .s_axis_0_tdata(s_axis_0_tdata),
        .s_axis_0_tvalid(s_axis_0_tvalid),
        .s_axis_0_tready(s_axis_0_tready_golden),

        .m_axis_0_tdata(m_axis_0_tdata_golden),
        .m_axis_0_tvalid(m_axis_0_tvalid_golden),
        .m_axis_0_tready(m_axis_0_tready)
    );

    //=========================================================
    // Faulty DUT
    //=========================================================

    finn_design_wrapper faulty (
        .ap_clk(ap_clk),
        .ap_rst_n(ap_rst_n),

        .s_axis_0_tdata(s_axis_0_tdata),
        .s_axis_0_tvalid(s_axis_0_tvalid),
        .s_axis_0_tready(s_axis_0_tready_faulty),

        .m_axis_0_tdata(m_axis_0_tdata_faulty),
        .m_axis_0_tvalid(m_axis_0_tvalid_faulty),
        .m_axis_0_tready(m_axis_0_tready)
    );

    //=========================================================
    // Optional comparator
    //=========================================================

    wire outputs_equal;

    assign outputs_equal =
        (m_axis_0_tvalid_golden == m_axis_0_tvalid_faulty) &&
        (m_axis_0_tdata_golden  == m_axis_0_tdata_faulty);

endmodule