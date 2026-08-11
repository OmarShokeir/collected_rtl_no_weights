#############################################################
# Single Fault Injection Campaign
#
# For each assumption:
#   golden.xxx == faulty.xxx
#
# replace ONLY that comparison with
#
#   golden.xxx != faulty.xxx
#
# run output_preserved_a
# save report
#############################################################

# -----------------------------------------------------------
# Configuration
# -----------------------------------------------------------

set property "sva/finn_checker/output_preserved_a"
#set property "sva/finn_checker/test_property_a"


# Fresh campaign directory
file mkdir results

set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set campaign_dir "results/campaign_$timestamp"

file mkdir $campaign_dir

puts "Campaign directory:"
puts "  $campaign_dir"

# -----------------------------------------------------------
# Read original assumptions
# -----------------------------------------------------------

set fp [open "assumptions.sv" r]
set original_lines [split [read $fp] "\n"]
close $fp

# -----------------------------------------------------------
# Iterate over every comparison
# -----------------------------------------------------------

set fault_id 0

catch {stop_message_log}
for {set i 0} {$i < [expr {[llength $original_lines]-1}]} {incr i} {

    set l1 [string trim [lindex $original_lines $i]]
    set l2 [string trim [lindex $original_lines [expr {$i+1}]]]

    #
    # Match:
    #
    # golden.xxx ==
    # faulty.xxx &&
    #
    if {![string match "golden.*==" $l1]} {
        continue
    }

    if {![string match "faulty.**" $l2]} {
        continue
    }

    incr fault_id

    puts ""
    puts "=================================================="
    puts "Running fault #$fault_id"
    puts "$l1"
    puts "=================================================="

    #########################################################
    # Restore original file
    #########################################################

    set modified $original_lines

    #########################################################
    # Inject ONE fault
    #########################################################

    set newline [string map {"==" "!="} [lindex $modified $i]]

    set modified [lreplace $modified $i $i $newline]

    #########################################################
    # Write assumptions.sv
    #########################################################

    set fp [open "assumptions.sv" w]
    puts $fp [join $modified "\n"]
    close $fp

    #########################################################
    # Reload assumptions
    #########################################################

    puts "Reloading..."

    catch {read_itl} msg
    puts $msg

    catch {read_sva} msg
    puts $msg

    puts "Reload finished."

    #########################################################
    # Report file
    #########################################################

    set logfile [format "%s/fault_%04d.txt" \
        $campaign_dir \
        $fault_id]

    #########################################################
    # First line = faulted signal
    #########################################################

    set fp [open $logfile w]
    puts $fp "Faulted signal:"
    puts $fp $l1
    puts $fp ""
    close $fp

    #########################################################
    # Append OneSpin output
    #########################################################

    start_message_log -append $logfile

    catch {

        check \
            -verbose \
            -force \
            -approver1_steps 1 \
            -approver2_steps 0 \
            -approver3_steps 0 \
            -approver4_steps 0 \
            -disprover1_steps 0 \
            -disprover3_steps 0 \
            -disprover6_steps 0 \
            -prover1_steps 0 \
            -prover2_steps 0 \
            [list $property]

        report_result -details [list $property]

    }

    stop_message_log

    puts "Saved -> $logfile"
}

#############################################################
# Restore original assumptions.sv
#############################################################

set fp [open "assumptions.sv" w]
puts $fp [join $original_lines "\n"]
close $fp

#############################################################
# Done
#############################################################

puts ""
puts "=================================================="
puts "Campaign completed."
puts "Faults injected: $fault_id"
puts "Results:"
puts "  $campaign_dir"
puts "=================================================="