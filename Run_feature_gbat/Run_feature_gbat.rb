##########################################################################################
# Copyright (c) 2016, Freescale Semiconductor, Inc.
# All rights reserved.
# Code author: Chao.Qu<chao.qu@nxp.com>
# Version: 0.0.1
##########################################################################################

require 'optparse'
require 'pathname'

class FeatureData
#  FILTERS = ["add","inst"]
#  DIRECTORY = "C:/mcu-chipmodel/chipmodel/soc"
  
  def initialize()
    @feature_path = Array.new
    @hits_num_sub = 0
    @hits_file_sub = 0
    @status = 0
  end
  
  def process_args()
    opt_parser = OptionParser.new do | opts |
      opts.on("-d", "--dir [C:\\mcu-chipmodel\\chipmodel\\soc]", String, \
        "Specify the directory which we want to search in chipmodel") do | value |
        @directory = check_convert_path(value)
      end

#      opts.on("-f", "--fil [Optional -- add, inst,...]", Array, \
#        "Optional -- list of file which we want to search") do | value |
#        @filters = value
#      end

      opts.on("-i", "--ipname [d_ip_llwu_syn.itmp]", String, \
        "Specify the ipname") do | value |
        @ipname = value
      end

      opts.on("-h", "--help", "print this help") do
        puts(opts)
        puts "Example: ruby Run_feature_gbat.rb -d C:\\mcu-chipmodel\\chipmodel\\soc -i d_ip_llwu_syn.itmp"
        exit(0)
      end
    end

    opt_parser.parse!

#    if nil == @filters
#      @filters = FILTERS
#    end

#    if nil == @directory
#      @directory = DIRECTORY
#    end

    puts "\nSearch target:"
    puts "ipname: " + @ipname
    puts "directory: " + @directory
#    puts "filters: " + @filters.to_s
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
  
  public
  def search_run_feature()
    File.delete("./search_#{@ipname}.txt") if File::exists?("./search_#{@ipname}.txt")
    search_blocks(@directory)
    puts "\nSearch Result:"
    if @hits_file_sub != 0
      puts "  #{@hits_num_sub.to_s} hits in #{@hits_file_sub.to_s} files, please see detail information in search_#{@ipname}.txt"
      IO.foreach("./search_#{@ipname}.txt") do |line|
        puts line
      end
    else
      puts "#{@hits_num_sub.to_s} hits in #{@hits_file_sub.to_s} files, please check given dirctory"
    end

    File.open("./search_#{@ipname}.txt","a") do |buffer|
      buffer.write("\nSearch '#{@ipname}' (#{@hits_num_sub} hits in #{@hits_file_sub} files)\n")
    end
#    puts @feature_path                         #存放feature files 路径的数组
    run_gbat()
    if @status == 0 && @hits_file_sub != 0
      puts "\nRun all feature files successfully!"
    end
    if @status != 0
      puts "\nErrors occur when run feature files, please see detail information in folder run_feature_error_logs"
    end
  end

  def search_blocks(path)
    if File.directory?(path)
      Dir.entries(path).each do |sub|
        if sub != '.' && sub != '..'
          if sub == "blocks"
            search_templete("#{path}/#{sub}")
#            puts "success"
          else
            search_blocks("#{path}/#{sub}")
          end
        end
      end
    end
  end
  
  def search_templete(blocks)
    Dir.entries(blocks).each do |sub|
      if File.file?("#{blocks}/#{sub}")
        if File.extname(sub) == ".add" || File.extname(sub) == ".inst"
        #if File.extname(sub) == ".inst"
          search_ip("#{blocks}/#{sub}")
        end
      end
    end
  end

  def search_ip(templete)
    line_num = 0                                             #判断匹配的行号
    hits_num = 0                                             #该文件中匹配的次数
    hits_line = Array.new                                    #存放行号和行内容
    IO.foreach(templete) do |line|
      line.force_encoding("UTF-8")                           #强制转换为UTF-8编码
      line_num = line_num + 1                                #行号加1
      if ( line =~ /(.*)#{@ipname}(.*)/i )
        hits_num = hits_num + 1                              #匹配次数加1
        hits_line.push("    Line  #{line_num}:     #{line}") #将行号和行内容存放数组
      end
    end
    if hits_num >= 1                                         #成功匹配一次及以上 输出匹配结果
      @hits_num_sub = @hits_num_sub + hits_num               #记录总的匹配次数
      @hits_file_sub = @hits_file_sub + 1                    #记录总的匹配文件数目
      @feature_path.push(File.join(File.expand_path("../..",templete),"batches/features"))
      File.open("./search_#{@ipname}.txt","a") do |buffer|
        buffer.write("  #{templete}  (#{hits_num} hits)\n")
        hits_line.each do |hit_line|
          buffer.write(hit_line)
        end
      end
    end
  end
  
  def run_gbat()
    path = Array.new
    pwd = Dir.pwd
    outlog = nil
    generate_erroer = 0
    @feature_path.each do |feature_path|
      path = feature_path.split("/")
      npi = path[-3]                                          #获取 NPI 名字
      npi = npi.upcase
      if Dir.exist?(feature_path)                             #判断对否存在 feature 文件夹
        Dir.chdir(feature_path)
        Dir.entries(feature_path).each do |sub|
          if sub != '.' && sub != '..'
            if File.file?("#{feature_path}/#{sub}")
              if File.extname(sub) == ".gbat"
                $CMD = "agen64 #{sub}"
                outlog = "#{pwd}/run_feature_error_logs/#{npi}_#{sub}_log.txt"
                puts "\nRun #{npi} feature files"
                puts "#{$CMD} -relaxFieldValueIds -allowInstParamRedefinition -relaxResetValues"
                system("#{$CMD} -relaxFieldValueIds -allowInstParamRedefinition -relaxResetValues > #{outlog}")
                IO.foreach(outlog) do |line|
                  if line =~ /agen: Total:/ && line =~ /ERRORS/
                    generate_erroer = 1
                    @status = 1
                  end
                end
                if generate_erroer == 0
                  puts "Run #{npi} #{sub} successfully"
                  File.delete(outlog) if File::exists?(outlog)
                else
                  puts "Errors occur when run #{npi} #{sub}, please see detail information in folder run_feature_error_logs"
                end
              end
            end
          end
        end
      end
    end
    Dir.chdir(pwd)
  end
  
end


#main
val = FeatureData.new()
val.process_args()
val.search_run_feature()
