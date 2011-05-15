require 'markov_chain'

mc = MarkovChain.new(" ")
buffer = ""

File.open("aiw.txt").each_line do |line|
  if 
  d.split(/\.\?!/).each do |sentence|
    mc.analyze(sentence.split(/\s\(\)/).select {|item| item.size > 0}.map{|word| word.downcase})
  end
end

mc.convert
puts mc.generate(50)
