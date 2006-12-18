require 'yaml'

require 'confluence/confluence_rpc'

class Confluence::Connector
  
  attr_accessor :username, :password, :default_service, :url, 
                :admin_proxy_username, :admin_proxy_password

  def initialize(options = {})
    load_confluence_config
    @url ||= options[:url]
    @username = options[:username] || @username
    @password = options[:password] || @password
    @default_service = options[:service] || 'confluence1'
  end
  
  def connect(service = nil)
    unless url and username and password and service || default_service
      raise "Cannot get Confluence::RPC instance because the confluence url, username, password, or service have not been set"
    end
    
    rpc = Confluence::RPC.new(url, service || default_service)
    rpc.login(username, password)

    return rpc
  end
  
  def load_confluence_config
    conf = YAML.load_file("#{RAILS_ROOT}/config/confluence.yml")[RAILS_ENV]
    @url = conf['url'] || conf[:url]
    @default_service = conf['service'] || conf[:service]
    @username = conf['username'] || conf[:username]
    @password = conf['password'] || conf[:password]
    @admin_proxy_username = conf['admin_proxy_username'] || conf[:admin_proxy_username]
    @admin_proxy_password = conf['admin_proxy_password'] || conf[:admin_proxy_password]
  end
  
  def self.default_confluence_url
    conf = YAML.load_file("#{RAILS_ROOT}/config/confluence.yml")[RAILS_ENV]
    conf['url'] || conf[:url]
  end
  
  # The given block will be executed using another account, as set in the confluence.yml file under admin_proxy_username
  # and admin_proxy_password. This is useful when you want to execute some function that requires admin privileges. You
  # will of course have to set up a corresponding account on your Confluence server with administrative rights.
  def self.through_admin_proxy
    super_connector = Confluence::Connector.new
    
    raise "Cannot execute through_admin_proxy because the admin_proxy_username has not been set." unless super_connector.admin_proxy_username
    raise "Cannot execute through_admin_proxy because the admin_proxy_password has not been set." unless super_connector.admin_proxy_password
    
    super_connector.username = super_connector.admin_proxy_username
    super_connector.password = super_connector.admin_proxy_password
    
    normal_connector = Confluence::RemoteDataObject.connector
    Confluence::RemoteDataObject.connector = super_connector
    
    yield
    
    Confluence::RemoteDataObject.connector = normal_connector
  end
end