##########################################################################################
# Copyright (c) 2016, Freescale Semiconductor, Inc.
# All rights reserved.
# Code author: Chao.Qu<chao.qu@nxp.com>
# Version: 0.0.1
##########################################################################################

require 'optparse'
require 'pathname'
require 'find'

class SearchData

  def initialize()
    @filters = Array.new         #过滤器
    @file_path = Array.new
    @hits_num_sub = 0
    @hits_file_sub = 0
  end

  def process_args()
    opt_parser = OptionParser.new do | opts |
      opts.on("-d", "--dir [C:\\mcu-chipmodel\\chipmodel\\soc]", String, "Specify the directory which you want to search") do | value |
        @directory = check_convert_path(value)
      end

      opts.on("-s", "--str [d_ip_llwu_syn.itmp]", String, "Specify the string which you want to search") do | value |
        @string = value
      end

      opts.on("-f", "--fil [Optional -- add, inst,...]", Array, "Optional -- list of file which we want to search") do | value |
       @filters = value
      end

      opts.on("-h", "--help", "print this help") do
        puts(opts)
        puts "Example: ruby Run_feature_gbat.rb -d C:\\mcu-chipmodel\\chipmodel\\soc -s d_ip_llwu_syn -f .inst,.add"
        exit(0)
      end
    end

    opt_parser.parse!
    puts "\nSearch target:"
    puts "string: " + @string
    puts "directory: " + @directory
    puts "filters: " + @filters.to_s if nil != @filters
  end
  
  def check_convert_path(path)
    if nil == path or !Dir.exist?(path)
      puts "Directory does not exist: #{path}"
      exit(0)
    end
    path.gsub!('\\', '/')
    if !File.directory?(path)
      puts "Directory is not a folder: #{path}"
      exit(0)
    end
    return path
  end

  def search()
    File.delete("./search_#{@string}.txt") if File.exists?("./search_#{@string}.txt")     #删除旧的搜索结果
    search_file(@directory)   
    puts "\nSearch Result:"
    if @hits_file_sub != 0
      puts "  #{@hits_num_sub.to_s} hits in #{@hits_file_sub.to_s} files, please see detail information in search_#{@ipname}.txt"
      IO.foreach("./search_#{@string}.txt") do |line|
        puts line
      end
    else
      puts "#{@hits_num_sub.to_s} hits in #{@hits_file_sub.to_s} files, please check given dirctory"
    end
    File.open("./search_#{@string}.txt","a") do |buffer|
      buffer.write("\nSearch '#{@string}' (#{@hits_num_sub} hits in #{@hits_file_sub} files)\n")
    end 
  end

  # def search_file(path)
    # if File.directory?(path)
      # Dir.entries(path).each do |sub|
        # if sub != '.' && sub != '..'
          # if File.file?("#{path}/#{sub}") && is_target_file?(sub)
            # search_string("#{path}/#{sub}")
            # puts "haha"
          # end
          # if File.directory?("#{path}/#{sub}")
            # search_file("#{path}/#{sub}")
          # end
        # end
      # end
    # end
  # end

  def search_file(path)
    Find.find(path) do |sub|                       #是否需要排除隐藏文件夹
      if File.file?(sub) && is_target_file?(sub)
        search_string(sub)
      end
    end
  end

  def is_target_file?(path)
    if @filters == nil          #当未指定filters时，所有文件都是目标文件
      return true
    else
      @filters.each do |filter|
        if File.basename(path, File.extname(path)) == filter || File.extname(path) == filter || File.basename(path) == filter
          return true
        end
      end
      return false
    end
  end

  def search_string(path)
    hits_num = 0                                               #该文件中匹配的次数
    line_num = 0                                               #判断匹配的行号
    hits_line = Array.new                                      #存放行号和行内容
    IO.foreach(path) do |line|
      begin
        line.force_encoding("UTF-8")                           #强制转换为UTF-8编码
        line_num = line_num + 1                                #行号加1
        if ( line =~ /#{@string}/i )                           #不区分大小写
          hits_num = hits_num + 1                              #匹配次数加1
          hits_line.push("    Line  #{line_num}:     #{line}") #将行号和行内容存放数组
        end
      rescue
        break
      end
    end
    if hits_num >= 1                                           #成功匹配一次及以上 输出匹配结果
      @hits_num_sub = @hits_num_sub + hits_num                 #记录总的匹配次数
      @hits_file_sub = @hits_file_sub + 1                      #记录总的匹配文件数目
      @file_path.push(path)                                    #@file_path数组用于扩展其他应用
      File.open("./search_#{@string}.txt","a") do |buffer|
        buffer.write("  #{path}  (#{hits_num} hits)\n")
        hits_line.each do |hit_line|
          buffer.write(hit_line)
        end
      end
    end
  end

end

#main
val = SearchData.new()
val.process_args()
val.search()
