# copyright (C) Matthew Hardenburgh
# matthew@hardenburgh.io

# vivado -mode batch -source rcatb.tcl
# use xvlog, xelab and xsim for simulation
# read_verilog, synth_design for FPGA implemention
set TOP transmitterTb

puts "PWD is [pwd]"
set projRoot [pwd]

# Build the include args for xvlog
#set inc_dirs   [list \
#    [file join $projRoot src] \
#    [file join $projRoot testing/transmitterTb] \
#]
#set inc_args {}
#foreach d $inc_dirs { lappend inc_args -i $d }

# Absolute path to this script
set script_path [info script]
# Directory containing this script
set script_dir [file dirname $script_path]
puts "Script directory: $script_dir"

set sourceList [file join $script_dir "sourceList.txt"]
set includeDirs [file join $script_dir "includeDirs.txt"]

# slurp up source list
set fh [open $sourceList r]
set sourceListContents [read $fh]
close $fh

set fh [open $includeDirs r]
set includeDirListContents [read $fh]
close $fh

# If your file is newline-separated (recommended):
set srcFiles [split $sourceListContents "\n"]

set includeList [split $sourceListContents "\n"]
set inc_args {}
foreach d $includeDirListContents { lappend inc_args -i $d }

# Drop empties
set clean {}
foreach f $srcFiles {if {$f ne ""} { lappend clean $f }}
puts "xvlog include args: $inc_args"

# last thing, cd to build directory
cd $script_dir

exec xvlog -sv {*}$srcFiles {*}$inc_args
# lint files
exec xelab -L work $TOP -s ${TOP}_sim
exec xsim ${TOP}_sim -runall 

exit