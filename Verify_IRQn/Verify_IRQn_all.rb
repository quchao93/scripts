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
    opts.on("-d", "--dir [the upper folder of header file in chip-model ]", String, \
      "specify the upper folder of SOC.h") do | value |
      $header_folder = check_convert_path(value)
    end

    opts.on("-n", "--num [the number of interrupt vector occurrences]", String, \
      "specify the number of interrupt vector occurrences") do | value |
      $num = value
    end

    opts.on("-h", "--help", "print this help") do
      puts(opts)
      puts "Example: ruby Verify_IRQn_all.rb -d C:\\mcu-chipmodel\\npi-data\\Kinetis\\K3S_1M_2.4G\\ksdk -n 1"
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

def get_header_file()
  Dir.entries($header_folder).each do |sub|
    if sub != '.' && sub != '..'
      if File.directory?("#{$header_folder}/#{sub}")
        $name = sub
        Dir.entries("#{$header_folder}/#{sub}").each do |header|
          if header != '.' && header != '..'
            if File.file?("#{$header_folder}/#{sub}/#{header}")
              if File.basename(header, File.extname(header)) == $name && File.extname(header) == ".h"
                $header = "#{$header_folder}/#{sub}/#{header}"
                Verify_IRQn()
              end
            end
          end
        end
      end
    end
  end
end

def Verify_IRQn()
  $interrupt = Array.new
  IO.foreach("#{$header}"){|line|
    if ( line =~ /(.*)_IRQn( *)= \d/ )
      line1 = line.gsub(/ /, "")
      line2 = line1.gsub(/=(.*)\n/, "")
      $interrupt.push("#{line2}")
    end}

  IO.foreach("#{$header}"){|line|
    if ( line =~ /(.*)_IRQn(.*)/ )
      File.open("./#{$name}_interrupt.txt","a"){|buffer|
      buffer.write(line)}
    end}

  File.delete("./Verify_#{$name}.txt") if File::exists?("./Verify_#{$name}.txt")
  for irq in $interrupt
    a = 0
    IO.foreach("./#{$name}_interrupt.txt"){|line|
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

  File.delete("./#{$name}_interrupt.txt") if File::exists?("./#{$name}_interrupt.txt")

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
get_header_file()
Verify_IRQn()