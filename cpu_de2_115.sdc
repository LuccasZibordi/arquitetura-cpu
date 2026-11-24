create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]
# Asynchronous human controls feed only the input synchronizers.
# Exceptions start at the pins, keeping synchronizer stages and reset release timed.
set_false_path -from [get_ports {KEY[0] KEY[1] SW[0] SW[1] SW[2] SW[3]}]
# Human-readable indicators have no external sampling clock.
set_false_path -to [get_ports {LEDR[*] LEDG[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*] HEX6[*] HEX7[*]}]
derive_clock_uncertainty
