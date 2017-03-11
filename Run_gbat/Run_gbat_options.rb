#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-
# Code author: Chao.Qu<chao.qu@nxp.com>
# Version: 0.0.1

require 'optparse'
require 'pathname'

def process_args()                              
  opt_parser = OptionParser.new do | opts |     
    opts.on("-d", "--dir [the parent folder of SOC.gbat file in chip-model ]", String, \
      "specify the parent folder of SOC.gbat") do | value |
      $gbat_folder = check_convert_path(value)
    end


    opts.on("-h", "--help", "print this help") do
      puts(opts)
      puts "Example: ruby Run_gbat.rb -d C:\mcu-chipmodel\chipmodel\soc\kinetis\k3s_1m_2.4g\batches\memory_maps\sdk"
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

def run()
  pwd = Dir.pwd
  Dir.chdir($gbat_folder)
  Dir.entries($gbat_folder).each do |sub|
    if sub != '.' && sub != '..'
      if File.file?("#{$gbat_folder}/#{sub}")
        if File.extname(sub) == ".gbat"
          $CMD = "agen #{sub}"
          puts "\n"
          puts "\n"
          puts $CMD
          system("#{$CMD}")
          #puts "#{$CMD} -relaxFieldValueIds -allowInstParamRedefinition -relaxResetValues"
          #system("#{$CMD} -relaxFieldValueIds -allowInstParamRedefinition -relaxResetValues > C:/Users/B58848/Desktop/Scripts/Run_gbat/run_feature_error_log/#{sub}_log.txt")
        end
      end
    end
  end
  Dir.chdir(pwd)
end

process_args()
run()