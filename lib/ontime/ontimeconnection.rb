require 'httparty'
require 'json'
require 'pp'

class OnTimeConnection
  include HTTParty
  include OnTimeInterface
  
  debug_output $stderr
  
  private
  
  def wrap_in_objects(type, results)
    objects = Array.new
    results["data"].each do |result|
      obj = OnTimeItem.new(@account_name, @access_token, @user_id)
      obj.id   = result["id"]
      obj.name = result["name"]
      obj.type = type
      objects << obj
    end
    return objects
  end
  
  public
  
  def initialize(a_name, c_id, c_secret)
    @account_name  = a_name
    @client_id     = c_id
    @client_secret = c_secret
    
    base_uri build_base_uri(a_name, '/')
  end
  
  def login(username, password)
    response = get('/oauth2/token',
                    :query => { :grant_type    => "password",
                                :username      => username,
                                :password      => password,
                                :client_id     => @client_id,
                                :client_secret => @client_secret,
                                :scope         => 'read write'})
    
    if response.has_key? "error"
      @error      = response["error"]
      @error_desc = response["error_description"]
    else
      #{"access_token":"ec7cfcd1-dcb5-4ffb-8579-d811ecd6d2a6","token_type":"bearer","data":{"id":106,"first_name":"Jesse","last_name":"Rosalia","email":"jesse.rosalia@ad-juster.com"}}Jesses-MacBook-Pro:helpers thejenix$ 
      pp response
      @access_token = response["access_token"]
      @user_id      = response["data"]["id"]
      # Construct a uri with /v1 appended.  This lets all future method calls match
      # the API docs exactly.
      base_uri build_base_uri(@account_name, '/v1')
      default_params :access_token => @access_token
    end
    
    return logged_in?
  end
  
  def logged_in?
    !@access_token.nil?
  end
  
  def defects
    wrap_in_objects('defects',  get('/defects',  { :user_id => @user_id }))
  end
  
  def features
    wrap_in_objects('features', get('/features', { :user_id => @user_id }))
  end
end
