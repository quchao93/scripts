#! ruby -Iengine -I../core -I.

require 'rubygems'

$DEFAULT_OPT=[
    # Uncommend this option if only some of toolchains would be supported.
    # Valid options: iar,mdk,atl,armgcc.
    # "-t iar,mdk,atl,armgcc",
]


#$PARAMS=(ARGV + $DEFAULT_OPT).join(" ")
#$BOARD = File.basename(__FILE__).split(".")[0].split("_")[1]
$CMD = "ruby Read_reg/read_reg.rb"
puts "run command #{$CMD}"

#Resolve the path issue
pwd = Dir.pwd
Dir.chdir("../")
system("#{$CMD}")
Dir.chdir(pwd)

if ($?.exitstatus != 0)
    puts "error occurred, press enter key to quit"
else
    puts "succeed, press enter key to quit"
end

# To avoid script blocked for waiting input here, option --pass could be used here
# which would do nothing but just avoid this checking.
if (ARGV.size == 0)
    gets
end
