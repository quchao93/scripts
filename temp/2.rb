#! ruby -Iengine -I../core -I.

require 'rubygems'
require 'pathname'

templete = "C:/mcu-chipmodel/chipmodel/soc/kinetis/k3s_1m_2.4g/blocks/soc.add"
path = File.expand_path("../..",templete)
feature = File.join(path,"batches/features")
puts "templete: " + templete
puts "path: " + path
puts "feature: " + feature
feature_path = feature.split("/")
npi = feature_path[-3]
npi = npi.upcase
puts npi

  
  def search_blocks(path)
    if File.directory?(path)
      Dir.entries(path).each do |sub|
        if sub != '.' && sub != '..'
#          puts sub
          if sub == "blocks"
#            puts "success"
#            puts "#{path}/#{sub}"
            search_templete("#{path}/#{sub}")
            break
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
          #puts "#{blocks}/#{sub}"
          search_ip("#{blocks}/#{sub}")
        end
      end
    end
  end
  
  
  def search_ip(templete)
  ipname = "d_ip_llwu_syn.add"
  feature_path = Array.new
  hits_line = Array.new
  line_num = 0
  a = 0
    IO.foreach(templete) do |line|
      line.force_encoding("UTF-8")
      line_num = line_num + 1
      if ( line =~ /(.*)d_ip_llwu_syn.add(.*)/ )
        a = a + 1
        hits_line.push("    Line  #{line_num}:     #{line}")
      end
    end
    if a >= 1
      feature_path.push(File.join(File.expand_path("../..",templete),"batches/features"))
      File.open("./#{ipname}_search.txt","a") do |buffer|
        buffer.write("  #{templete}  (#{a} hits)\n")
        hits_line.each do |hit_line|
          buffer.write(hit_line)
        end
      end
    end
  end

  
  search_blocks("C:/mcu-chipmodel/chipmodel/soc")