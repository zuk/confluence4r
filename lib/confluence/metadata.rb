# Allows for reading and writing a {metadata-list} macro in a page's content.
# 
# For example, if your wiki content is:
# 
#   Hello, World!
#   {metadata-list}
#   || Foo   | Bar |
#   || Fruit | Orange |
#   {metadata-list}
# 
# You may do this (assuming that you have the above text stored in a variable
# called 'wiki_content'):
# 
#   m = Confluence::Metadata.new(wiki_content)
#   puts m['Foo']    # outputs "Bar"
#   puts m['Fruit']  # outputs "Orange"
#   
#   m['Fruit'] = "Banana"
#   puts m['Fruit']  # outputs "Banana"
#   m['Hello'] = "Goodbye"
#   
# ... and your wiki_content now holds:
# 
#   Hello, World!
#   {metadata-list}
#   || Foo   | Bar |
#   || Fruit | Banana |
#   || Hello | Goodbye |
#   {metadata-list}
#
class Confluence::Metadata
  include Enumerable

  def initialize(page)
    raise ArgumentError.new("Argument passed to Confluence::Metadata must be a Confluence::Page") unless page.kind_of? Confluence::Page
    @page = page
  end
  
  def [](metadata_key)
    extract_metadata_from_content[metadata_key]
  end
  
  def []=(metadata_key, value)
    metadata = extract_metadata_from_content
    metadata[metadata_key] = value
    replace_metadata_in_content(metadata)
    value
  end
  
  def each
    metadata = extract_metadata_from_content
    metadata.each{|k,v| yield k,v}
  end
  
  def include?(key)
    not self.find{|k,v| k}.nil?
  end
  alias_method :has_key?, :include?
  
  def empty?
    extract_metadata_from_content.empty?
  end
  
  # Merges a hash (or some other Hash-like, Enumerable object) into
  # this metadata. That is, key-value pairs from the given object will be added
  # as metadata to this Confluence::Metadata's page, overriding any existing duplicate keys.
  def merge!(data)
    data.each do |k,v|
      self[k] = v
    end
  end
  
  private
    def extract_metadata_from_content
      return {} if @page.content.nil?
    
      in_body = false
      metadata = {}
      @page.content.each do |line|
        #TODO: handle other kinds of metadata macros
        in_body = !in_body if line =~ /\{metadata-list\}/
        
        if in_body        
          metadata[$1] = $2 if line =~ /\|\|\s*(.*?)\s*\|\s*(.*?)\s*\|/
        end
      end
      
      return metadata
    end
    
    def replace_metadata_in_content(metadata)
      #TODO: handle cases where there are multiple {metadata-list} macros in a page
      #TODO: handle other kinds of metadata macros
      
      macro_name = "{metadata-list}"
      
      @page.content = "" if @page.content.nil?
      
      @page.content += "\n#{macro_name}\n\n#{macro_name}" unless @page.content.include? macro_name
      
      metadata_start = @page.content.index(macro_name) + macro_name.size
      metadata_end = @page.content.index(macro_name, metadata_start) - 1
      
      longest_key = 0
      metadata.each do |key, val|
        longest_key = key.size if key.size > longest_key
      end
      
      metadata_body = ""
      metadata.each do |key, val|
        padding = " " * (longest_key - key.size)
        metadata_body += "|| #{key}#{padding} | #{val} |\n"
      end
      
      @page.content[metadata_start..metadata_end] = "\n"+metadata_body
    end
end