#############################################################
# Permanent Stuck-at-1 Campaign
#############################################################

set property "sva/finn_checker/output_preserved_a"
#set property "sva/finn_checker/test_property_a"

file mkdir results

set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set campaign_dir "results/campaign_$timestamp"

file mkdir $campaign_dir

#############################################################
# Read originals
#############################################################

set fp [open "assumptions.sv" r]
set original_assumptions [split [read $fp] "\n"]
close $fp

set fp [open "fault.sv" r]
set original_fault [split [read $fp] "\n"]
close $fp

#############################################################

set fault_id 0

catch {stop_message_log}

for {set i 0} {$i < [expr {[llength $original_assumptions]-1}]} {incr i} {

    set l1 [string trim [lindex $original_assumptions $i]]
    set l2 [string trim [lindex $original_assumptions [expr {$i+1}]]]

    if {![string match "golden.*==" $l1]} {
        continue
    }

    if {![string match "faulty.**" $l2]} {
        continue
    }

    incr fault_id

    puts ""
    puts "=============================================="
    puts "Fault #$fault_id"
    puts $l1
    puts "=============================================="

    #########################################################
    # Restore assumptions
    #########################################################

    set assumptions $original_assumptions

    #########################################################
    # Restore fault.sv
    #########################################################

    set faultfile $original_fault

    #########################################################
    # Comment assumption
    #########################################################

    set assumptions [lreplace \
        $assumptions \
        $i \
        $i \
        "// [lindex $assumptions $i]"]

    set assumptions [lreplace \
        $assumptions \
        [expr {$i+1}] \
        [expr {$i+1}] \
        "// [lindex $assumptions [expr {$i+1}]]"]

    #########################################################
    # Extract faulty signal
    #########################################################

    set faulty_signal $l2

    regsub {&&$} $faulty_signal "" faulty_signal
    set faulty_signal [string trim $faulty_signal]

    #########################################################
    # Build stuck-at assumption
    #########################################################

set expr "    fault_assumptions =\n(\n        $faulty_signal == {(\$bits($faulty_signal)){1'b1}}\n    );"

    #########################################################
    # Replace body of fault.sv
    #########################################################

    set new_fault {}

    foreach line $faultfile {

        if {[string match "*fault_assumptions =*" $line]} {

            lappend new_fault $expr

        } elseif {[string match "*1'b1*" $line]} {

            # skip original assignment

        } else {

            lappend new_fault $line
        }
    }

    #########################################################
    # Write assumptions
    #########################################################

    set fp [open "assumptions.sv" w]
    puts $fp [join $assumptions "\n"]
    close $fp

    #########################################################
    # Write fault
    #########################################################

    set fp [open "fault.sv" w]
    puts $fp [join $new_fault "\n"]
    close $fp

    #########################################################
    # Save copies for this fault
    #########################################################

    file copy -force \
        "assumptions.sv" \
        [format "%s/assumptions_%04d.sv" $campaign_dir $fault_id]

    file copy -force \
        "fault.sv" \
        [format "%s/fault_%04d.sv" $campaign_dir $fault_id]

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
    # Log
    #########################################################

    set logfile [format "%s/fault_%04d.txt" \
        $campaign_dir \
        $fault_id]

    set fp [open $logfile w]
    puts $fp "Permanent stuck-at-1 fault:"
    puts $fp $faulty_signal
    puts $fp ""
    close $fp

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
# Restore originals
#############################################################

set fp [open "assumptions.sv" w]
puts $fp [join $original_assumptions "\n"]
close $fp

set fp [open "fault.sv" w]
puts $fp [join $original_fault "\n"]
close $fp

puts ""
puts "Campaign completed."
puts "Faults injected: $fault_id"
puts "Results: $campaign_dir"