# copyright (C) Matthew Hardenburgh
# matthew@hardenburgh.io

# vivado -mode batch -source rcatb.tcl
# use xvlog, xelab and xsim for simulation
# read_verilog, synth_design for FPGA implemention

# Absolute path to this script
set script_path [info script]
# Directory containing this script
set script_dir [file dirname $script_path]
puts "Script directory: $script_dir"
cd $script_dir
set sourceList [file join $script_dir "sourceList.txt"]

set fh [open $sourceList r]
set contents [read $fh]
close $fh

# If your file is newline-separated (recommended):
set srcFiles [split $contents "\n"]

# Drop empties
set clean {}
foreach f $srcFiles {
    if {$f ne ""} { lappend clean $f }
}

exec xvlog -sv {*}$srcFiles --define DEBUG=1
#exec xvlog -sv /home/matthew/uart/src/transmitter.sv /home/matthew/uart/src/reciever.sv /home/matthew/uart/src/uartUtil.sv /home/matthew/uart/build/_deps/svtest-src/testFramework.sv /home/matthew/uart/testing/transmitterTb/transmitterTb.sv --define DEBUG=1
# lint files
exec xelab top --define DEBUG=1
exec xsim top -runall 

exit