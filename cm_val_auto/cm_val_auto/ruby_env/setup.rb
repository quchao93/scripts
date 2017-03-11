#! ruby
# Please install ruby v 2.x.x 64bits
# http://rubyinstaller.org/downloads/
puts "\nMake sure you have installed the ruby v2.x.x 64bits!"
puts "http://rubyinstaller.org/downloads/ \n\n"

Dir.foreach(".") do | file |
  if file =~ /.gem/
    puts "\ninstalling " + file
    system "gem install " + file
  end
end

puts "\n\npress any key to continue"
gets
