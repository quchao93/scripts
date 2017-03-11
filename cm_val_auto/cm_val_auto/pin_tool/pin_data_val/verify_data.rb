##########################################################################################
# Copyright (c) 2016, Freescale Semiconductor, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# o Redistributions of source code must retain the above copyright notice, this list
#   of conditions and the following disclaimer.
#
# o Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
# o Neither the name of Freescale Semiconductor, Inc. nor the names of its
#   contributors may be used to endorse or promote products derived from this
#   software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Brief:
# ++++++++++++++++
# Main entry, define the automatic validation flow.
#
# --- Code author: Bill.Yuan <Bill.Yuan@nxp.com>
# --- Version added: 0.0.1
#
# ++++++++++++++++
# --- 0.0.1: Bill.Yuan --- add the automatic validation flow
#
##########################################################################################

require './pin_model'
require './xml_parser'
require './xls_parser'

require 'optparse'
require 'find'
require "awesome_print"
require 'yaml'
require 'pathname'

class PinDataVal
  CONFIG_FILE_NAME = "signal_configuration.xml"
  REF_PIN_DATABASE_FOLDER = "./rm_pin_db"

  def initialize()
    @is_peripheral_val = false
    @is_features_val = false
  end

  def process_args()
    opt_parser = OptionParser.new do | opts |
      opts.on("-d", "--dir [the parent folder of pin tool xml data processor]", String, \
        "specify the parent folder of one processor") do | value |
        @xml_data_folder = check_convert_path(value)
      end

      opts.on("-r", "--ref [Optional -- the parent folder of reference excel files from RM docs]", String, \
        "Optional -- specify the parent folder of reference excel files") do | value |
        @xls_data_folder = check_convert_path(value)
      end

      opts.on("-p", "--peripheral", "is enable peripheral instance value validation") do | value |
        @is_peripheral_val = value
      end

      opts.on("-f", "--features", "is enable features value validation") do | value |
        @is_features_val = value
      end

      opts.on("-h", "--help", "print this help") do
        puts(opts)
        puts "Example: ruby verify_data.rb -d C:\\ProgramData\\NXP\\KEx_Tools\\1.0\\mcu_data\\kex_tools\\processors\\MK65FN2M0xxx18\
        -r C:\\rm_pin_db"
        exit(0)
      end
    end

    opt_parser.parse!

    if nil == @xls_data_folder
      @xls_data_folder = (Pathname.new(File.dirname(__FILE__)).realpath + Pathname.new(REF_PIN_DATABASE_FOLDER)).to_s
    end

    if Chip::DEBUG
      puts 'xml_data_folder: ' + @xml_data_folder
      puts 'xls_data_folder: ' + @xls_data_folder
      puts 'is_peripheral_val ' + @is_peripheral_val.to_s
      puts 'is_features_val ' + @is_features_val.to_s
    end
  end

  def validate_data()
    is_found_xml_pin_data = false
    Find.find(@xml_data_folder) do |config_file|
      if config_file =~ /\/#{CONFIG_FILE_NAME}$/
        test_report = Hash.new()

        puts 'found the config file: ' + config_file if Chip::DEBUG
        is_found_xml_pin_data = true

        target_chip = Chip.new(config_file)
        if !target_chip.parse()
          test_report["target_chip"] = "Parse error!"
          generate_report(target_chip.info.part_num, test_report, false)
          next
        end
        p target_chip.info if Chip::DEBUG

        ref_chip = RefChip.new(@xls_data_folder, target_chip.info)
        ref_chip.set_adv_options(@is_peripheral_val, @is_features_val)
        ref_chip.set_testresult_parent(test_report)
        if !ref_chip.parse()
          test_report["ref_chip"] = "Parse error!"
          generate_report(ref_chip.info.part_num, test_report, false)
          next
        end
        p ref_chip.info if Chip::DEBUG

        ref_chip.compare(target_chip)
        generate_report(ref_chip.info.part_num, test_report, 0 == ref_chip.fail_num)

        target_chip.generate_peripheral_type_yml() if Chip::DEBUG
      end
    end

    puts "\nNot found pin data file #{CONFIG_FILE_NAME} under folder #{@xml_data_folder}" if !is_found_xml_pin_data
  end

  private
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

  def generate_report(part_num, test_report, is_pass)
    # puts test_report.to_yaml
    puts test_report.to_yaml[0..600]
    
    report_file = "#{part_num}_PASS.yml"
    report_file = "#{part_num}_FAIL.yml" if !is_pass

    File.open(report_file, 'w') {|f| f.write test_report.to_yaml }
    puts "Data validation completed!"
  end
end

#main
val = PinDataVal.new()
val.process_args()
val.validate_data()
