`timescale 1ns / 1ps

module finn_miter_props(

    input logic       ap_clk,
    input logic       ap_rst_n,

    input logic [7:0] m_axis_0_tdata_golden,
    input logic       m_axis_0_tvalid_golden,

    input logic [7:0] m_axis_0_tdata_faulty,
    input logic       m_axis_0_tvalid_faulty

);

    `include "assumptions.sv"
    `include "fault.sv"

    default clocking default_clk @(posedge ap_clk); endclocking;
    assume_fault_always: assume property (@(posedge ap_clk) disable iff (!ap_rst_n) fault_assumptions());

    // ---------------------------------------------------------
    // Property:
    // Test property that runs so quick
    // ---------------------------------------------------------

    property test_property;

        disable iff (!ap_rst_n)

        assumptions()

        |->
        (
            (m_axis_0_tdata_golden == m_axis_0_tdata_faulty)
        )[*1:2];

    endproperty

    test_property_a:
        assert property(test_property);

    
    // ---------------------------------------------------------
    // Property:
    // There shouldnt exist a cycle where output is different
    // ---------------------------------------------------------
	property output_diff_exists;

	    disable iff (!ap_rst_n)

	    assumptions()

	    |->
	    ##[1:50] //252 > 117 >> 68
	    (m_axis_0_tdata_golden != m_axis_0_tdata_faulty);

	endproperty

	output_diff_exists_a:
	    assert property(output_diff_exists);

    // ---------------------------------------------------------
    // Property:
    // Assumptions imply equivalent outputs
    // ---------------------------------------------------------

    property output_preserved;

        disable iff (!ap_rst_n)

        assumptions()

        |->
        (
            (m_axis_0_tdata_golden == m_axis_0_tdata_faulty)
        )[*1:252];
        //)[*1:100];

    endproperty

    output_preserved_a:
        assert property(output_preserved);

    // ---------------------------------------------------------
    // Property:
    // Assumptions imply equivalent outputs for Layer 1 under no faults
    // Within 10 cycles (For now)
    // ---------------------------------------------------------

	property mvau_weight_fault_propagates;

	    disable iff (!ap_rst_n)

	    (
		assumptions()
	    )
	    |->
	    (
		    //golden.finn_design_i.MVAU_hls_1_out_V_TVALID && faulty.finn_design_i.MVAU_hls_1_out_V_TVALID 
		    //&&
		    golden.finn_design_i.MVAU_hls_1_out_V_TDATA ==
		     faulty.finn_design_i.MVAU_hls_1_out_V_TDATA
	    )[*1:232];

	endproperty

    mvau_weight_fault_propagates_a:
        assert property(mvau_weight_fault_propagates);


endmodule


bind finn_miter finn_miter_props finn_checker (

    .ap_clk(ap_clk),
    .ap_rst_n(ap_rst_n),

    .m_axis_0_tdata_golden(m_axis_0_tdata_golden),
    .m_axis_0_tvalid_golden(m_axis_0_tvalid_golden),

    .m_axis_0_tdata_faulty(m_axis_0_tdata_faulty),
    .m_axis_0_tvalid_faulty(m_axis_0_tvalid_faulty)

);