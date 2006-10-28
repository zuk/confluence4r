require 'confluence/confluence_remote_data_object'

# Exposes a vaguely ActiveRecord-like interface for dealing with Confluence::Pages
# in Confluence.
class Confluence::Page < Confluence::RemoteDataObject

  self.save_method = :storePage
  self.get_method = :getPage
  self.destroy_method = :removePage

  self.attr_conversions = {
      :id => :int,
      :version => :int,
      :parentId => :int,
      :current => :boolean,
      :homePage => :boolean,
      :created => :datetime,
      :modified => :datetime
    }
    
  self.readonly_attrs = [:current, :created, :modified, :contentStatus]

  DEFAULT_SPACE = "encore"
  
  def initialize(data_object = nil)
    super
    #self.creator = self.confluence_user unless self.include? :creator
  end
  
  def content=(new_content)
    # make sure metadata doesn't get overwritten
    old_metadata = self.metadata.entries if self.content
    super
    self.metadata.merge! old_metadata if old_metadata
  end
  
  def load_from_object(data_object)
    super
    self.modifier = self.confluence_username unless self.attributes.include? :modifier
  end
  
  def metadata
    Confluence::Metadata.new(self)
  end
  
  def parent
    self.class.find(self.parentId)
  end
  
  def to_s
    self.title
  end
  
  def edit_group=(group)
    encore.setPageEditGroup(self.name, group)
  end
  
  def edit_group
  	perm = get_permissions
  	return nil if perm.nil? or perm.empty?
  	perm.each do |p|
  		return p['lockedBy'] if p['lockType'] == 'Edit'
  	end
  	return nil
  end
  
  def view_group=(group)
    encore.setPageViewGroup(self.name, group)
  end
  
  def view_group
  	perm = get_permissions
  	return nil if perm.nil? or perm.empty?
  	perm.each do |p|
  		return p['lockedBy'] if p['lockType'] == 'View'
  	end
  	return nil
  end
  
  def get_permissions
  	confluence.getPagePermissions(self.id.to_s)
  end
  
  ### class methods #########################################################
    
  def self.find_by_name(name, space = DEFAULT_SPACE)
    r = confluence.getPage(space, name)
    self.new(r)
  end
  
  def self.find_by_title(title, space = DEFAULT_SPACE)
    self.find_by_name(title, space)
  end
  
  
  #############################################################################
  
  protected
    def self.metadata_accessor(accessor, metadata_key)
      f = <<-END
        def #{accessor.to_s}
          self.metadata['#{metadata_key}']
        end
        def #{accessor.to_s}=(val)
          self.metadata['#{metadata_key}'] = val
        end
      END
      module_eval f
    end
    
    def reload_newly_created!
      self.load_from_object(confluence.getPage(self.space, self.name))
    end
end