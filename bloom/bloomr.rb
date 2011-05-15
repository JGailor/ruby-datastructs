class Bloom
  require 'inline'
  
  PRIMES = [7919, 9733, 11149, 12553, 13499, 14887, 16333, 17387, 18313, 19423, 22811, 31601]
  
  def initialize(width, hash_count = nil)
    @integer_bit_length = 1.size * 7
    @width = width
    @filters = Array.new((@width / @integer_bit_length.to_f).ceil, 0)
    @num_functions = (hash_count || [(@width / @integer_bit_length), 2].max)
    @time = Time.now.to_i
  end
  
  def convert_index_to_slot_and_bit(index)
    [(index / @integer_bit_length), (1 << (index % @integer_bit_length))]
  end
  
  def position_set?(index)
    slot, bit = convert_index_to_slot_and_bit(index)
    (@filters[slot] & bit) == bit
  end
  
  def set_position(index)
    slot, bit = convert_index_to_slot_and_bit(index)
    (@filters[slot] |= bit)
  end
  
  def add(value)
    (0...@num_functions).each {|i| set_position(elf_hash(value, PRIMES[i], @width))}
  end
  
  def contains?(value)
    (0...@num_functions).all? {|i| position_set?(elf_hash(value, PRIMES[i], @width))}
  end
  
  inline do |builder|
    builder.c "
      long elf_hash(char* target, long seed, long max) {
        int g, i = 0;
        
        for(i = 0; i < strlen(target); i++) {
          seed = (seed << 4) + target[i];
          g = seed & 0xF0000000;
          if(g != 0) {
            seed = seed ^ (g >> 24) ;
          }
          
          seed = seed & (~g);
        }
        
        return (seed % max);
      }
    "
  end
end