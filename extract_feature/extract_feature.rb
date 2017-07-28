##########################################################################################
# Copyright (c) 2016, Freescale Semiconductor, Inc.
# All rights reserved.
# Code author: Chao.Qu<chao.qu@nxp.com>
# Version: 0.0.1
##########################################################################################

require 'optparse'
require 'pathname'

class FeatureData

  def initialize()
    @featurefile_nam = Array.new
    @actual_featurename = nil
    @feature_val = Array.new
    @error_line = Array.new
  end
  
  def process_args()
    opt_parser = OptionParser.new do | opts |
      opts.on("-d", "--dir [C:\\mcu-sdk-2.0\\devices\\K32W042S1M2]", String, \
        "Specify the directory which we want to search in chipmodel") do | value |
        @directory = check_convert_path(value)
      end


      opts.on("-h", "--help", "print this help") do
        puts(opts)
        puts "Example: ruby extract_feature.rb -d C:\\mcu-sdk-2.0\\devices\\K32W042S1M2"
        exit(0)
      end
    end

    opt_parser.parse!

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
  
  def extra_feature()
    search_featurefile(@directory)
	if @featurefile_nam.length > 1
	  puts "There are more than one feature file. please input the number to select one feature"
      @featurefile_nam.each_with_index do |elem, i|	
        puts " #{i+1}:    #{@featurefile_nam[i]}"	 
      end
	  inputval = gets.chomp.to_i
	  @actual_featurename = @featurefile_nam[inputval-1]
	  puts "select feature is: #{@actual_featurename}"
	else
	  puts "There is one feature file:"
	  @actual_featurename = @featurefile_nam
	  puts @actual_featurename
	end
	process_featurefile("#{@directory}/#{@actual_featurename}")	
  end
	  
  def search_featurefile(path)
	Dir.entries(path).each do |sub|
	  if File.file?("#{path}/#{sub}")
		if ( sub =~ /(.*)_features.h/i )
		  @featurefile_nam.push(sub)
		end
	  end
	end
  end
  
  def process_featurefile(file)
    io = File.open(file, "r")
	io.each_line do |line|
	  if ( line =~ /^#define FSL_FEATURE_.* \(.+\)/ )
	    if ( line =~ /\([1-9][0-9]*\)$/ ) || ( line =~ /\(0x.*\)$/ )
		  val = line
		  val = val.sub!(/^#define /, '                         ')
		  val = val.sub!(/ \(/,'=')		  
		  val = val.sub!(/\)$/, ' \\')
		  @feature_val.push(val)
		else 
		  if ( line =~ / \(0\)$/ )
		  else 
		    @error_line.push("  Line  #{io.lineno}:  #{line}")
		  end
	    end
	  end
	end	 
    io.close
	puts @feature_val
    puts @error_line	
  end
    
  
  
end
		  
  
  
#main
val = FeatureData.new()
val.process_args()
val.extra_feature()

  
  