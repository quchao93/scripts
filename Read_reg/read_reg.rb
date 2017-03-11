##########################################################################################
# Copyright (c) 2016, Freescale Semiconductor, Inc.
# All rights reserved.
# Code author: Chao.Qu<chao.qu@nxp.com>
# Version: 0.0.1
##########################################################################################

require 'optparse'
require 'pathname'
require "win32ole"

def process_args()

  execl_folder = nil
  opt_parser = OptionParser.new do | opts |     
    opts.on("-d", "--dir [the parent folder of registe execl file ]", String, \
      "specify the parent folder of one register execl file") do | value |
      execl_folder = check_convert_path(value)
    end

    opts.on("-h", "--help", "print this help") do
      puts(opts)
      puts "Example: ruby read_reg.rb -d C:\\mcu-chipmodel\\npi-data\\Kinetis\\K3S_1M_2.4G\\ksdk\\K32W022S1M2_M0P"
      exit(0)
    end
  end

  opt_parser.parse!

  if nil == execl_folder
    execl_folder = (Pathname.new(File.dirname(__FILE__)).realpath).to_s
  end

  execl_file = check_register_file(execl_folder)
  read_register_file(execl_file)

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

def check_register_file(execl_folder)
  a = 0
  execl_file = nil
  Dir.entries(execl_folder).each do |sub|
    if File.file?("#{execl_folder}/#{sub}")
      if File.extname(sub) == ".xls" || File.extname(sub) == ".xlsx"
        a = a + 1
        execl_file = "#{execl_folder}/#{sub}"
        $name = File.basename(sub, File.extname(sub))
      end
    end
  end
  if a == 0
    puts "Execl file does not exist in: #{execl_folder}"
    exit(0)
  else 
    if a == 1
      puts "Execl file has found in: #{execl_folder}"
      return execl_file
    else 
      puts "There are more one execl file in: #{execl_folder}"
      exit(0)
    end
  end
end

def read_register_file(execl_file)

  excel =WIN32OLE::new('excel.Application')
  workbook =excel.Workbooks.Open(execl_file)
  worksheet =workbook.Worksheets(1) #定位到第一个sheet
  worksheet.Select
  #puts worksheet.visible #判断sheet是否存在
  rows = worksheet.UsedRange.Rows.Count   #获取sheet的行数
  File.delete("./#{$name}.txt") if File::exists?("./#{$name}.txt")
  File.open("./#{$name}.txt","a") {|buffer| buffer.write("##{$name}:#{$name} Register\n")}

  for rowindex in 2..rows
    if (worksheet.range("a#{rowindex}").value != nil)
      File.open("./#{$name}.txt","a") {|buffer| buffer.write(worksheet.range("b#{rowindex}").value.gsub(/0x/, "") + "h " + worksheet.range("a#{rowindex}").value + " 32 RW 00000000h\n")}
    end
  end

  File.open("./#{$name}.txt","a") {|buffer| buffer.write("\n#Register\n")}

  for rowindex in 2..rows
    if (worksheet.range("a#{rowindex}").value != nil)
      File.open("./#{$name}.txt","a") {|buffer| buffer.write("\n##{worksheet.range("a#{rowindex}").value}\n")}
      case worksheet.range("d#{rowindex}").value     #convert bits_name and puts
      when "NA"
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} reserved reserved\n")}
      when /_observe_mux_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} observe_mux #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_input_on_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} SION #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_mux_mode_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} mux_mode #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_lvttl_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} lvttl #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_pue_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} pue #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_ode_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} ode #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_hys_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} hys #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_fsel_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} fsel #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_dse_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} dse #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_vsel_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} vsel #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_select_input/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} DAISY #{worksheet.range("e#{rowindex}").text}.\n")}
      else
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} #{worksheet.range("d#{rowindex}").text} #{worksheet.range("e#{rowindex}").text}.\n")}
      end
    else
      case worksheet.range("d#{rowindex}").value
      when "NA"
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} reserved reserved\n")}
      when /_observe_mux_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} observe_mux #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_input_on_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} SION #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_mux_mode_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} mux_mode #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_lvttl_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} lvttl #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_pue_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} pue #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_ode_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} ode #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_hys_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} hys #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_fsel_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} fsel #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_dse_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} dse #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_vsel_/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} vsel #{worksheet.range("e#{rowindex}").text}.\n")}
      when /_select_input/
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} DAISY #{worksheet.range("e#{rowindex}").text}.\n")}
      else
        File.open("./#{$name}.txt","a") {|buffer| buffer.write("!#{worksheet.range("c#{rowindex}").text} #{worksheet.range("d#{rowindex}").text} #{worksheet.range("e#{rowindex}").text}.\n")}
      end
    end
  end
  workbook.close false
  excel.quit
  puts "read register execl successful!"
end

#main
process_args()