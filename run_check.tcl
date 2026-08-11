# -----------------------
# Configuration
# -----------------------

set api_key "Your_Resend_API_Key_Here"

proc run_property {prop api_key} {

    set full_prop "sva/finn_checker/$prop"

    puts "====================================="
    puts "Running property: $full_prop"
    puts "====================================="

    set result [catch {
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
            [list $full_prop]
    } msg]

    if {$result == 0} {
        set status "FINISHED"
    } else {
        set status "ERROR"
    }

    puts $msg

    # -----------------------
    # Email notification
    # -----------------------

    set json [format {
{
  "from":"OneSpin <onboarding@resend.dev>",
  "to":["omarshokeir2@gmail.com"],
  "subject":"OneSpin Job %s",
  "text":"Property %s has completed.\n\nStatus: %s"
}
} $status $prop $status]

    catch {
        exec curl -s https://api.resend.com/emails \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            -d $json
    } curl_result

    puts "Email response:"
    puts $curl_result
}

# -----------------------
# Run properties
# -----------------------

#run_property "output_diff_exists_a" $api_key
run_property "output_preserved_a" $api_key
#run_property "mvau_weight_fault_propagates_a" $api_key

puts "All properties completed."