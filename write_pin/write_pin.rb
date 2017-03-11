##########################################################################################
# Copyright (c) 2016, Freescale Semiconductor, Inc.
# All rights reserved.
# Code author: Chao.Qu<chao.qu@nxp.com>
# Version: 0.0.1
##########################################################################################

require 'pathname'
require "win32ole"

def write_pin()

  pin_execl = nil
  reg_exexl = nil
  ref_pin_execl = "mScale_850D_Pin_List_v0.8.xlsx"
  ref_reg_execl = "iomuxc_reg_pph_1218.xls"
  execl_folder = (Pathname.new(File.dirname(__FILE__)).realpath).to_s
  pin_execl = "#{execl_folder}/#{ref_pin_execl}"
  reg_exexl = "#{execl_folder}/#{ref_reg_execl}"
  puts "Find pin_execl #{pin_execl}"
  puts "Find reg_exexl #{reg_exexl}"
  File.delete("./result.txt") if File::exists?("./result.txt")

  excel =WIN32OLE::new('excel.Application')
  reg_workbook =excel.Workbooks.Open(reg_exexl)
  reg_worksheet =reg_workbook.Worksheets(1) #定位到第1个sheet
  reg_worksheet.Select
  #puts reg_worksheet.visible #判断sheet是否存在
  reg_rows = reg_worksheet.UsedRange.Rows.Count   #获取sheet的行数
  
  pin_workbook =excel.Workbooks.Open(pin_execl)
  pin_worksheet =pin_workbook.Worksheets(2) #定位到第2个sheet
  pin_worksheet.Select
  #puts pin_worksheet.visible #判断sheet是否存在
  pin_rows = pin_worksheet.UsedRange.Rows.Count   #获取sheet的行数
  
  base_addr = 0x30330000
  
  reg_name = Array.new
  reg_addr = Array.new
  for rowindex in 2..reg_rows
    if (reg_worksheet.range("a#{rowindex}").value != nil)
      reg_name.push(reg_worksheet.range("a#{rowindex}").value)
      reg_addr.push(reg_worksheet.range("b#{rowindex}").value)
    end
  end
  
  
  for rowindex in 3..pin_rows
    pin_name = nil
    addr = nil
    pin_name = pin_worksheet.range("c#{rowindex}").value
    for name in 0..reg_name.size - 1
      if (/#{pin_name}/i =~ reg_name[name])
        addr = reg_addr[name].to_i(16) + base_addr
        #puts addr.to_s(16)
        if (pin_worksheet.range("f#{rowindex}").value != nil)
          File.open("./result.txt","a") {|buffer| buffer.write("#define #{reg_name[name]}_#{pin_worksheet.range("f#{rowindex}").value}          #{addr.to_s(16)}, 0x0\n")}
        end
        if (pin_worksheet.range("g#{rowindex}").value != nil)
          File.open("./result.txt","a") {|buffer| buffer.write("#define #{reg_name[name]}_#{pin_worksheet.range("g#{rowindex}").value}          #{addr.to_s(16)}, 0x1\n")}
        end
        if (pin_worksheet.range("h#{rowindex}").value != nil)
          File.open("./result.txt","a") {|buffer| buffer.write("#define #{reg_name[name]}_#{pin_worksheet.range("h#{rowindex}").value}          #{addr.to_s(16)}, 0x2\n")}
        end
        if (pin_worksheet.range("i#{rowindex}").value != nil)
          File.open("./result.txt","a") {|buffer| buffer.write("#define #{reg_name[name]}_#{pin_worksheet.range("i#{rowindex}").value}          #{addr.to_s(16)}, 0x3\n")}
        end
        if (pin_worksheet.range("j#{rowindex}").value != nil)
          File.open("./result.txt","a") {|buffer| buffer.write("#define #{reg_name[name]}_#{pin_worksheet.range("j#{rowindex}").value}          #{addr.to_s(16)}, 0x4\n")}
        end
        if (pin_worksheet.range("k#{rowindex}").value != nil)
          File.open("./result.txt","a") {|buffer| buffer.write("#define #{reg_name[name]}_#{pin_worksheet.range("k#{rowindex}").value}          #{addr.to_s(16)}, 0x5\n")}
        end
        if (pin_worksheet.range("l#{rowindex}").value != nil)
          File.open("./result.txt","a") {|buffer| buffer.write("#define #{reg_name[name]}_#{pin_worksheet.range("l#{rowindex}").value}          #{addr.to_s(16)}, 0x6\n")}
        end
        if (pin_worksheet.range("n#{rowindex}").value != nil)
          File.open("./result.txt","a") {|buffer| buffer.write("#define #{reg_name[name]}_#{pin_worksheet.range("n#{rowindex}").value}          #{addr.to_s(16)}, 0x7\n")}
        end
      end
    end
  end
  reg_workbook.close false
  pin_workbook.close false
  excel.quit
  puts "Write successful!!"
end


#main
write_pin()
