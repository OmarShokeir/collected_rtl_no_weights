# Summary: This script retrieves all signals from the design, 
# checks their state using get_signal_info, and categorizes them into true and false signals. 
# The results are written to separate text files, 
# which are then processed by Python scripts to sort the true signals 
# and generate a SystemVerilog function for assumptions.

set outdir "output_signals"
file mkdir $outdir

set fh_true  [open "$outdir/state_true_signals.txt" w]
set fh_false [open "$outdir/state_false_signals.txt" w]

foreach sig [get_signals] {

    if {[catch {get_signal_info -state $sig} result]} {
        puts $fh_false $sig
        continue
    }

    set res_lower [string tolower $result]

    if {$res_lower eq "true"} {
        puts $fh_true $sig
    } else {
        puts $fh_false $sig
    }
}

close $fh_true
close $fh_false

puts "Done. Files written to $outdir/"

exec python3 process_true_signals.py \
    "$outdir/state_true_signals.txt" \
    "$outdir/state_true_signals_sorted.txt"

puts "Sorted file: $outdir/state_true_signals_sorted.txt"

exec python3 generate_assumptions_func.py \
    "$outdir/state_true_signals_sorted.txt" \
    "$outdir/assumptions.sv" \
    assumptions

puts "Generated function: $outdir/assumptions.sv"