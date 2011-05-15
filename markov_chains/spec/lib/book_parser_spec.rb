require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe BookParser do
  context "BookParser#new" do
    it "it should open the file from the initialize parameter" do
      File.should_receive(:new).with(fixture_file_path("aiw_preamble.txt")).and_return(nil)
      BookParser.new(fixture_file_path("aiw_preamble.txt"))
    end
  end
  
  context "reading a whole file" do
    it "should successfully read the whole file without error" do
      bp = BookParser.new(fixture_file_path("aiw.txt"))
      count = 0
      lambda {while(last_sentence = bp.read_sentence);count += 1;end}.should_not raise_error
      count.should > 0
    end
  end
  
  context "#read_preamble" do    
    before(:all) do
      @data = <<-AIW
Project Gutenberg's Alice's Adventures in Wonderland, by Lewis Carroll

This eBook is for the use of anyone anywhere at no cost and with
almost no restrictions whatsoever.  You may copy it, give it away or
re-use it under the terms of the Project Gutenberg License included
with this eBook or online at www.gutenberg.org


Title: Alice's Adventures in Wonderland

Author: Lewis Carroll

Posting Date: June 25, 2008 [EBook #11]
Release Date: March, 1994

Language: English

Character set encoding: ASCII

*** START OF THIS PROJECT GUTENBERG EBOOK ALICE'S ADVENTURES IN WONDERLAND ***
AIW
  end
   
   before(:each) do
      @faux_file = StringIO.new(@data, "r")
      File.stub!(:new).and_return(@faux_file)
    end
    
    it "should call #readline until it reads the end of the preamble" do
      bp = BookParser.new("")
      bp.send(:read_preamble)
      bp.instance_variable_get(:"@preamble_finished").should be_true
    end
    
    it "should raise an error if there is the preamble could not be found" do
      File.stub!(:new).and_return(StringIO.new("no preamble here"))
      bp = BookParser.new("")
      lambda{bp.send(:read_preamble)}.should raise_error
    end
  end
  
  context "#readline" do    
    it "should call #read_preamble if @preamble_finished is not set" do
      File.stub!(:new).and_return(StringIO.new("this is a string\n*** START OF THIS PROJECT GUTENBERG EBOOK ALICE'S ADVENTURES IN WONDERLAND ***"))
      bp = BookParser.new("")
      bp.should_receive(:read_preamble)
      bp.readline
    end
    
    it "should read the next line from the file" do
      File.stub!(:new).and_return(StringIO.new("this is the first line\nthis is the second line"))
      bp = BookParser.new("")
      bp.instance_variable_set(:"@preamble_finished", true)
      bp.readline.should == "this is the first line"
      bp.readline.should == "this is the second line"
    end
    
    it "should return nil when the @postamble_found is set" do
      File.stub!(:new).and_return(StringIO.new("this is a string... yadada"))
      bp = BookParser.new("")
      bp.instance_variable_set(:"@preamble_finished", true)
      bp.instance_variable_set(:"@postamble_found", true)
      bp.readline.should be_nil
    end
    
    it "should return nil when it finds the string 'End of Project Gutenberg'" do
      data = <<-AIW
Lastly, she pictured to herself how this same little sister of hers
would, in the after-time, be herself a grown woman; and how she would
keep, through all her riper years, the simple and loving heart of her
childhood: and how she would gather about her other little children, and
make THEIR eyes bright and eager with many a strange tale, perhaps even
with the dream of Wonderland of long ago: and how she would feel with
all their simple sorrows, and find a pleasure in all their simple joys,
remembering her own child-life, and the happy summer days.

              THE END




      
End of Project Gutenberg's Alice's Adventures in Wonderland, by Lewis Carroll
AIW

      faux_file = StringIO.new(data, "r")
      File.stub!(:new).and_return(faux_file)
      bp = BookParser.new("")
      bp.instance_variable_set(:"@preamble_finished", true)
      15.times{bp.readline().should_not be_nil}
      bp.readline().should be_nil
      bp.instance_variable_get(:"@postamble_found").should be_true
    end
    
    it "should read until it finds the string '*** END OF THIS PROJECT GUTENBERG'" do
      data = <<-AIW
Lastly, she pictured to herself how this same little sister of hers
would, in the after-time, be herself a grown woman; and how she would
keep, through all her riper years, the simple and loving heart of her
childhood: and how she would gather about her other little children, and
make THEIR eyes bright and eager with many a strange tale, perhaps even
with the dream of Wonderland of long ago: and how she would feel with
all their simple sorrows, and find a pleasure in all their simple joys,
remembering her own child-life, and the happy summer days.

              THE END




      
*** END OF THIS PROJECT GUTENBERG ***
AIW

      faux_file = StringIO.new(data, "r")
      File.stub!(:new).and_return(faux_file)
      bp = BookParser.new("")
      bp.instance_variable_set(:"@preamble_finished", true)
      15.times{bp.readline().should_not be_nil}
      bp.readline().should be_nil
      bp.instance_variable_get(:"@postamble_found").should be_true      
    end    
  end
  
  context "#read_sentence" do
    context "various sentence-enders" do
      def setup_test(input)
        File.stub!(:new).and_return(StringIO.new(input))
        bp = BookParser.new("")
        bp.instance_variable_set(:"@preamble_finished", true)
        bp
      end
      
      it "should consider a . to be end-of-sentence" do
        setup_test("A sentence ending with a period.").read_sentence.should == "A sentence ending with a period"
      end
      
      it "should consider a ! to be end-of-sentence" do
        setup_test("A sentence ending with a !").read_sentence.should == "A sentence ending with a"
      end
      
      it "should consider a ? to be end-of-sentence" do
        setup_test("A sentence ending with a ?").read_sentence.should == "A sentence ending with a"
      end
    end
    
    context "single line input" do
      before(:each) do
        File.stub!(:new).and_return(StringIO.new("This is a sentence.  And so is this."))
        @bp = BookParser.new("")
        @bp.instance_variable_set(:"@preamble_finished", true)
      end
    
      it "should return a sentence" do
        @bp.read_sentence.should == "This is a sentence"
      end
    
      it "should set the @fragment variable if there is anything left after finding the end of a sentence in a line" do
        @bp.read_sentence
        @bp.instance_variable_get(:"@fragments").should == "And so is this."
      end
    
      it "should not call readline again if the @fragments variable has a full sentence in it" do
        @bp.should_not_receive(:readline)
        @bp.instance_variable_set(:"@fragments", "And so is this.")
        @bp.read_sentence.should == "And so is this"
        @bp.instance_variable_get(:"@fragments").should == nil
      end
    end
    
    context "multi-line single sentence input" do
      before(:each) do
        File.stub!(:new).and_return(StringIO.new("This is a multi-line\nsentence."))
        @bp = BookParser.new("")
        @bp.instance_variable_set(:"@preamble_finished", true)
      end
      
      it "should read multiple lines until a sentence is found" do
        @bp.read_sentence.should == "This is a multi-line sentence"
      end
    end
    
    context "multi-line multi sentence input" do
      before(:each) do
        File.stub!(:new).and_return(StringIO.new("This is a multi-line\nsentence.This is the second multi-line\nsu su su sentence."))
        @bp = BookParser.new("")
        @bp.instance_variable_set(:"@preamble_finished", true)
      end
      
      it "should correctly read multiple lines w/ multiple sentences" do
        @bp.read_sentence.should == "This is a multi-line sentence"
        @bp.read_sentence.should == "This is the second multi-line su su su sentence"
      end
      
      it "should return nil when there are no more sentences" do
        @bp.read_sentence.should == "This is a multi-line sentence"
        @bp.read_sentence.should == "This is the second multi-line su su su sentence"
        @bp.read_sentence.should be_nil
      end
    end    
  end
end