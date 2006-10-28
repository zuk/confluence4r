require 'xmlrpc/client'
require 'logger'

# A useful helper for running Confluence XML-RPC from Ruby. Takes care of
# adding the token to each method call (so you can call server.getSpaces()
# instead of server.getSpaces(token)). Also takes care of re-logging in
# if your login times out.
#
# Usage:
#
# server = Confluence::RPC.new("http://confluence.atlassian.com")
# server.login("user", "password")
# puts server.getSpaces()
#
module Confluence
  class RPC
    attr_reader :log
    
    def initialize(server_url, proxy = "confluence1")
      server_url += "/rpc/xmlrpc" unless server_url[-11..-1] == "/rpc/xmlrpc"
      @server_url = server_url
      server = XMLRPC::Client.new2(server_url)
      @conf = server.proxy(proxy)
      @token = "12345"
      
      @log = Logger.new "#{RAILS_ROOT}/log/confluence4r.log"
    end
    
    def login(username, password)
      log.info "Logging in as '#{username}'."
      @user = username
      @pass = password
      do_login()
    end
    
    def method_missing(method_name, *args)
      log.info "Calling #{method_name}(#{args.inspect})."
      begin
        @conf.send(method_name, *([@token] + args))
      rescue XMLRPC::FaultException => e
        log.error "#{e}: #{e.message}"
        if (e.faultString.include?("InvalidSessionException"))
          do_login
          retry
        else
          raise e.faultString
        end
      end
    end
    
    private
    
    def do_login()
      begin
        @token = @conf.login(@user, @pass)
      rescue XMLRPC::FaultException => e
        raise e.faultString
      end
    end
  end
end