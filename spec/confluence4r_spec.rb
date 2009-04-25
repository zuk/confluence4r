require 'spec_helper'
require 'confluence/confluence_remote_data_object'

CLASS_INHERITABLE_ACCESSORS = [:attr_conversions, :readonly_attrs, :save_method, :get_method, :destroy_method]
ACCESSORS = [:attributes, :confluence, :encore]

describe Confluence::RemoteDataObject, "when initialized with no data object" do
  before(:each) do
    @crdo = Confluence::RemoteDataObject.new
  end
  
  it "should respond to its class-inheritable accessors" do
    CLASS_INHERITABLE_ACCESSORS.each do |accessor_sym|
      @crdo.should respond_to(accessor_sym)
      @crdo.should respond_to("#{accessor_sym}=".to_sym)
    end
  end

  it "should respond to its ordinary accessors" do
    ACCESSORS.each do |accessor_sym|
      @crdo.should respond_to(accessor_sym)
      @crdo.should respond_to("#{accessor_sym}=".to_sym)
    end
  end
end
