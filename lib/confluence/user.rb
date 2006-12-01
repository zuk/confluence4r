require 'confluence/confluence_remote_data_object'

class Confluence::User < Confluence::RemoteDataObject

  self.save_method = :editUser
  # TODO: implement :create_method ('addUser')
  self.get_method = :getUser
  self.destroy_method = :removeUser
    
  self.readonly_attrs = ['username', 'name']
  self.attr_conversions = {}
  
  @groups
  
  def id
    self.username
  end
  
  def id=(new_id)
    self.username = new_id
  end
  
  def username
    self.name
  end
  
  def username=(new_username)
    self.username=(new_username)
  end
  
  def groups
    # groups are cached for the lifetime of the user object or until a group-modifying method is called
    # FIXME: This is probably a bad idea, since the user's groups may be changed outside of the user object
    #         ... currently it's not a serious problem, since this is unlikely to happen within the object's
    #         short lifetime, but it may be problematic if start storing the user object in a cache or in the
    #         session.
    @groups ||= confluence.getUserGroups(username)
  end
  
  def in_group?(group)
    groups.include? group
  end
  
  def add_to_group(group)
    @groups = nil # reset cached group list
    confluence.addUserToGroup(username, group)
  end
  
  def remove_from_group(group)
    @groups = nil # reset cached group list
    confluence.removeUserFromGroup(username, group)
  end
  
  def has_permission?(permtype, page)
    if permtype == :edit
      group_or_name = page.edit_group
    else
      group_or_name = page.view_group
    end
        
    return true if group_or_name.nil?
    return true if group_or_name == username
    return in_group?(group_or_name)
  end
  
  def to_s
    self.username
  end
  
  def to_wiki
    "[~#{self.username}]"
  end
  
  ### class methods #########################################################
    
  def self.find_by_username(username)
    find(username)
  end
  
  # DEPRECATED: this method is confusing since it could be taken as meaning "find by first/last name"
  def self.find_by_name(username)
    find_by_username(username)
  end
  
  def self.find_by_email(email)
    usernames = confluence.getActiveUsers(true)
    usernames.each do |username|
      user = find_by_username(username)
      return user if user.email == email
    end
    
    return nil
  end
  
  def self.find_all
    # FIXME: this is really slow... we should probably just look in the confluence database instead
    usernames = find_all_usernames
    usernames.collect{|u| find_by_username(u)}
  end
  
  def self.find_all_usernames
    confluence.getActiveUsers(true)
  end
  
  class NoSuchUser < Exception
  end
  
end