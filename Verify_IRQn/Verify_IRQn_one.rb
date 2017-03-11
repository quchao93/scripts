##########################################################################################
# Copyright (c) 2016, Freescale Semiconductor, Inc.
# All rights reserved.
# Code author: Chao.Qu<chao.qu@nxp.com>
# Version: 0.0.1
##########################################################################################

require 'optparse'
require 'pathname'

def process_args()                              
  opt_parser = OptionParser.new do | opts |     
    opts.on("-d", "--dir [the parent folder of header file in chip-model ]", String, \
      "specify the parent folder of one SOC.h") do | value |
      $header_folder = check_convert_path(value)
    end

    opts.on("-n", "--num [the number of interrupt vector occurrences]", String, \
      "specify the number of interrupt vector occurrences") do | value |
      $num = value
    end

    opts.on("-h", "--help", "print this help") do
      puts(opts)
      puts "Example: ruby Verify_IRQn_one.rb -d C:\\mcu-chipmodel\\npi-data\\Kinetis\\K3S_1M_2.4G\\ksdk\\K32W022S1M2_M0P -n 1"
      exit(0)
    end
  end

  opt_parser.parse!
  
end

def check_convert_path(path)
  if nil == path or !Dir.exist?(path)
    puts "Folder does not exist: #{path}"
    exit(0)
  end

  path.gsub!('\\', '/')
  if !File.directory?(path)
    puts "Folder is not a folder: #{path}"
    exit(0)
  end

  return path
end

def Verify_IRQn()
  #path = "#{Pathname.new(File.dirname(__FILE__)).realpath}"
  $interrupt = Array.new
  $name = $header_folder.gsub(/(.*)\//, "")
  Dir.entries($header_folder).each do |sub|
    if File.file?("#{$header_folder}/#{sub}")
      if File.basename(sub, File.extname(sub)) == $name && File.extname(sub) == ".h"
        $header = "#{$header_folder}/#{sub}"
      end
    end
  end

  IO.foreach("#{$header}"){|line|
    if ( line =~ /(.*)_IRQn( *)= \d/ )
      line1 = line.gsub(/ /, "")
      line2 = line1.gsub(/=(.*)\n/, "")
      $interrupt.push("#{line2}")
    end
  }

  IO.foreach("#{$header}"){|line|
    if ( line =~ /(.*)_IRQn(.*)/ )
      File.open("./Verify_interrupt.txt","a"){|buffer|
      buffer.write(line)}
    end}

  File.delete("./Verify_#{$name}.txt") if File::exists?("./Verify_#{$name}.txt")
  for irq in $interrupt
    a = 0
    IO.foreach("./Verify_interrupt.txt"){|line|
      a = get_line_irq(line, irq, a) if ( line =~ /(.*) #{irq}(.*)/ )}
    if nil == $num
      File.open("./Verify_#{$name}.txt","a"){|buffer|
        buffer.write(irq + " : " + "#{a}\n")}
    end
    if a.to_s == $num
      File.open("./Verify_#{$name}.txt","a"){|buffer|
        buffer.write(irq + " : " + "#{a}\n")}
    end
  end

  File.delete("./Verify_interrupt.txt") if File::exists?("./Verify_interrupt.txt")

end

def get_line_irq(line, irq,a)
  #if ( line =~ /(.*) #{irq}(.*)/ )
    a = a + 1
    line = line.sub!(/ #{irq}/, "")
  #end 
  if !( line =~ /(.*) #{irq}(.*)/ )
    return a
  end
  get_line_irq(line, irq, a) if ( line =~ /(.*) #{irq}(.*)/ )
end

#main
process_args()
Verify_IRQn()