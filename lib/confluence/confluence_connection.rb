require 'yaml'

require 'confluence/confluence_rpc'

module Confluence::Connection
  @@url = nil
  @@username = nil
  @@password = nil

  def connect(options = {:service => "confluence1"})
    self.confluence_username = options[:username] if options[:username]
    self.confluence_password = options[:password] if options[:password]
  
    self.load_confluence_config
    
    unless confluence_url and confluence_username and confluence_password
      raise "Cannot get Confluence::RPC instance because the confluence_url, confluence_username, or confluence_password have not been set"
    end
    
    s = Confluence::RPC.new(confluence_url, options[:service])
    s.login(confluence_username, confluence_password)

    return s
  end
  module_function :connect
  
  def confluence_url
    @@url
  end
  def confluence_url=(url)
    @@url = url
  end
  
  def confluence_username
    @@username
  end
  def confluence_username=(username)
    @@username = username
  end
  
  def confluence_password
    @@password
  end
  def confluence_password=(password)
    @@password = password
  end
  module_function :confluence_url, :confluence_url=,
                  :confluence_username, :confluence_username=,
                  :confluence_password, :confluence_password=
  
  def load_confluence_config
    conf = YAML.load_file("#{RAILS_ROOT}/config/confluence.yml")[RAILS_ENV]
    self.confluence_url = conf['url'] if conf.has_key? 'url' and not self.confluence_url
    self.confluence_username = conf['username'] if conf.has_key? 'username' and not self.confluence_username
    self.confluence_password = conf['password'] if conf.has_key? 'password' and not self.confluence_password
  end
  
  module_function :load_confluence_config
end