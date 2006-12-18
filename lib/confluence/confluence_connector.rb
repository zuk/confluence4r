require 'yaml'

require 'confluence/confluence_rpc'

class Confluence::Connector
  
  attr_accessor :username, :password, :default_service, :url

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
  end
  
  def self.default_confluence_url
    conf = YAML.load_file("#{RAILS_ROOT}/config/confluence.yml")[RAILS_ENV]
    conf['url'] || conf[:url]
  end
end