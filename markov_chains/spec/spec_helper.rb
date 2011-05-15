$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "lib")

require 'rubygems'
require 'spec'
require 'markov_chain'
require 'book_parser'

class Spec::Example::ExampleGroup
  def fixture_file_path(name)
    File.join(File.dirname(__FILE__), "fixtures", name)
  end
end