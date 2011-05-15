require 'rubygems'
require 'bloomr'

b = Bloom.new(100000, 8)

("a".."sss").each {|c| b.add(c)}

puts ("ooo".."zzz").map {|c| b.contains?(c)}.select {|a| a == true}.count