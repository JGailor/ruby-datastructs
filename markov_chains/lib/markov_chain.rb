class MarkovChain
  def initialize(output_separator = '')
    @output_separator = output_separator
    @states = {}
    @mappings = {}    
  end
  
  def analyze_and_convert(words)
    words.each {|w| analyze(w)}
    convert
  end
  
  def analyze(set)
    unless set.size == 0
      (@states[''] ||= {})[set.first] = (@states[''][set.first] || 0) + 1
      
      if(set.size > 1)
        (@states[set.first] ||= {})[set[1]] = (@states[set.first][set[1]] || 0) + 1
      end
      
      if(set.size > 2)
        set.each_with_index do |item, i|
          unless ((i + 2) >= set.size)
            key = [item, set[i + 1]].join("")
            trans_letter = set[i + 2]
            (@states[key] ||= {})[trans_letter] = (@states[key][trans_letter] || 0) + 1
          end
        end
      end
    end
  end

  def convert
    @states.each do |key, value|
      (@mappings[key] ||= {})
      sum = value.values.inject(0) {|total, cur| total += cur}
      low = 0
      value.each do |k, v|
        upper = ((100 * (v.to_f / sum)).round) + low
        @mappings[key][k] = [low + 1, upper]
        low = upper
      end
    end
  end

  def get_rand
    (rand() * 100).to_i + 1
  end

  def transition(current)
    target = get_rand
    begin
      @mappings[current].find {|k, v| (v.first <= target && v.last >= target)}.first
    rescue => e
      nil
    end
  end

  def generate(length)
    string = [transition('')]
  
    (length - 1).times do
      val = (string.size > 1 ? transition("#{string[-2]}#{string[-1]}") : transition(string.last))
      break unless val
      string << val
    end
  
    string.join(@output_separator).split(" ").map{|word| word.capitalize}.join(" ")
  end
end


