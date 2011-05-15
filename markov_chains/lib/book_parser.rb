class BookParser
  def initialize(filename)
    @file = File.new(filename)
    @preamble_marker = /\*\*\*\sSTART OF THIS PROJECT GUTENBERG.*?\*\*\*/
    @postamble_marker = /(End of Project Gutenberg.*|\*\*\* END OF THIS PROJECT GUTENBERG.*?\*\*\*)/
    @sentence_separator = /(\.|!|\?)\s*/
  end
  
  def readline
    unless @preamble_finished
      read_preamble
    end
    
    unless @postamble_found
      line = @file.readline.chomp
      if line =~ @postamble_marker
        @postamble_found = true
        nil
      else
        line
      end
    end
  end
  
  def read_sentence
    begin
      if @fragments && @fragments =~ @sentence_separator
        parse_out_sentence(@fragments)
      else
        line = readline
        return nil unless line
        line = "#{@fragments} #{line}"
        until line =~ @sentence_separator
          new_line = readline
          line += (new_line ? " #{new_line}" : ".")
        end
      
        if line
          parse_out_sentence(line)
        end
      end
    rescue
      line ? line.strip : nil
    end
  end
  
  protected
    def parse_out_sentence(line)
      splits = line.split(@sentence_separator, 2)
      sentence = splits.shift
      @fragments = (splits.last.length > 0 ? splits.last : nil)
      sentence.strip
    end
    
    def read_preamble
      preamble_end = /\*\*\*\sSTART OF THIS PROJECT GUTENBERG+.*?\*\*\*/
      @file.rewind
      data = @file.readline.chomp
      @preamble_finished = (data =~ preamble_end)        
      until(data.nil? || @preamble_finished)
        data = @file.readline.chomp
        @preamble_finished = (data =~ preamble_end)          
      end
    end
  
  def finished!
    # @file.close
  end
end