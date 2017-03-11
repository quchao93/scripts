#!/usr/bin/ruby -w
# -*- coding: UTF-8 -*-
# Code author: Chao.Qu<chao.qu@nxp.com>
# Version: 0.0.1

Dir.foreach(".") do | file |
  if file =~ /.gbat/
    puts "\nRun " + file
    system "agen " + file
  end
end

puts "\n\npress any key to continue"
gets
