`timescale 1ns / 1ps

module mvau0_miter_props(

    input logic       ap_clk,
    input logic       ap_rst_n,

    input logic [31:0] out_V_TDATA_golden,
    input logic        out_V_TVALID_golden,

    input logic [31:0] out_V_TDATA_faulty,
    input logic        out_V_TVALID_faulty

);

    `include "assumptions.sv"
    `include "fault.sv"

    default clocking default_clk @(posedge ap_clk); endclocking;

    // Fault is permanently present
    assume_fault_always:
        assume property (
            @(posedge ap_clk)
            disable iff (!ap_rst_n)
            fault_assumptions()
        );

    // ---------------------------------------------------------
    // Property:
    // Layer-0 outputs remain equivalent
    // ---------------------------------------------------------

    property layer0_output_preserved;

        disable iff (!ap_rst_n)

        assumptions()

        |->
        (
            (out_V_TVALID_golden == out_V_TVALID_faulty) &&
            (out_V_TDATA_golden  == out_V_TDATA_faulty)
        )[*1:252];

    endproperty

    layer0_output_preserved_a:
        assert property(layer0_output_preserved);

endmodule


bind mvau0_miter mvau0_miter_props mvau0_checker (

    .ap_clk(ap_clk),
    .ap_rst_n(ap_rst_n),

    .out_V_TDATA_golden(out_V_TDATA_golden),
    .out_V_TVALID_golden(out_V_TVALID_golden),

    .out_V_TDATA_faulty(out_V_TDATA_faulty),
    .out_V_TVALID_faulty(out_V_TVALID_faulty)

);