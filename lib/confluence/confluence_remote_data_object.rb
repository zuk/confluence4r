require 'active_support'
require 'confluence/confluence_connector'

# Abstract object representing some piece of data in Confluence.
# This must be overridden by a child class that defines values
# for the class attributes save_method and get_method and/or
# implements its own get and save methods.
class Confluence::RemoteDataObject
#  include Reloadable
  
  class_inheritable_accessor :attr_conversions, :readonly_attrs
  class_inheritable_accessor :save_method, :get_method, :destroy_method
  
  attr_accessor :attributes
  
  attr_accessor :confluence, :encore
  
  @@connector = nil
  
  def self.connector=(connector)
    @@connector = connector
  end
  
  def self.confluence
    raise "Cannot establish confluence connection because the connector has not been set." unless @@connector
    @@connector.connect
  end
  
  def confluence
    raise "Cannot establish confluence connection because the connector has not been set." unless @@connector
    @@connector.connect
  end
  
  # TODO: encore-specific code like this probably shouldn't be here...
  def self.encore
    raise "Cannot establish confluence connection because the connector has not been set." unless @@connector
  	@@connector.connect("encore")
  end
  
  def encore
    raise "Cannot establish confluence connection because the connector has not been set." unless @@connector
    @@connector.connect("encore")
  end
  
  def initialize(data_object = nil)
    self.attributes = {}
    load_from_object(data_object) unless data_object.nil?
  end
  
  def load_from_object(data_object)
    data_object.each do |attr, value|
      if self.class.attr_conversions.has_key? attr.to_sym
        value = self.send("as_#{attr_conversions[attr.to_sym]}", value)
      end
      self.send("#{attr}=", value)
    end
  end
  
  def save
    before_save if respond_to? :before_save
    
    data = {} unless data
    
    self.attributes.each do |attr,value|
      data[attr.to_s] = value.to_s unless self.readonly_attrs.include? attr
    end
    
    raise NotImplementedError.new("Can't call #{self}.save because no @@save_method is defined for this class") unless self.save_method
    
    self.confluence.send(self.class.send(:save_method), data)
    
    # we need to reload because the version number has probably changed, we want the new ID, etc.
    reload
    
    after_save if respond_to? :after_save
  end
  
  def reload
    before_reload if respond_to? :before_reload
    
    if self.id
      self.load_from_object(self.class.send(:get, self.id))
    else
      # We don't have an ID, so try to use alternate method for reloading. (This is for newly created records that may not yet have an id assigned)
      raise NotImplementedError, "Can't reload this #{self.class} because it does not have an id and does not implement the reload_newly_created! method." unless self.respond_to? :reload_newly_created!
      self.reload_newly_created!
    end
    
    after_reload if respond_to? :after_reload
  end
  
  def destroy
    before_destroy if respond_to? :before_destroy
    
    raise NotImplementedError.new("Can't call #{self}.destroy because no @@destroy_method is defined for this class") unless self.destroy_method
    eval "confluence.#{self.destroy_method}(self.id.to_s)"
    
    after_destroy if respond_to? :after_destroy
  end
  
  def [](attr)
    self.attributes[attr]
  end
  
  def []=(attr, value)
    self.attributes[attr] = value
  end
  
  def id
    self[:id]
  end
  
  def method_missing(name, *args)
    if name.to_s =~ /^(.*?)=$/
      self[$1.intern] = args[0]
    elsif name.to_s =~ /^[\w_]+$/
      self[name]
    else
      raise NoMethodError, name.to_s
    end
  end
  
  def ==(obj)
    if obj.kind_of? self.class
      self.attributes == obj.attributes
    else
      super
    end
  end
  
  ### class methods #########################################################
  
  def self.find(id)
    r = get(id)
    self.new(r)
  end
  
  ### type conversions ######################################################
  
  # TODO: put these in a module?
  def as_int(val)
    val.to_i
  end
  
  def as_string(val)
    val.to_s
  end
  
  def as_boolean(val)
    val == "true"
  end
  
  def as_datetime(val)
    val =~ /\w{3} (\w{3}) (\d{2}) (\d{2}):(\d{2}):(\d{2}) (\w{3}) (\d{4})/
    month = $1
    day = $2
    hour = $3
    minute = $4
    second = $5
    tz = $6
    year = $7
    Time.local(year, month, day, hour, minute, second)
  end
  
  ###########################################################################
  
  protected
    # Returns the raw XML-RPC anonymous object with the data corresponding to 
    # the given id. This depends on the get_method class attribute, which must
    # be defined for this method to work.
    def self.get(id)
      raise NotImplementedError.new("Can't call #{self}.get(#{id}) because no get_method is defined for this class") unless self.get_method
      raise ArgumentError.new("You must specify a #{self} id!") unless id
      confluence.log.debug("get_method for #{self} is #{self.get_method}")
      obj = confluence.send(self.send(:get_method), id.to_s)
      return obj
    end
end