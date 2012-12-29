require 'httparty'

module HTTPartyEx
  
  def query(params)
    :query => { :access_token => @access_token }.merge(params)
  end
end  
  
class OnTimeObject
  include HTTParty
  include HTTPartyEx
  
  @id
  @name
  @type
    
  attr_accessor :id, :name, :type

  def initialize(uri, a_token, u_id)
    base_uri uri
    
    @access_token = a_token
    @user_id      = u_id
  end
    
  def work_logs
    get('/work_logs', query({ :type => @type, :id => @id }))
  end
  
  def add_work_log
    
  end

  def inspect
    self.name
  end
    
  def to_s
    self.name
  end
end
    
class OnTimeInterface
  include HTTParty
  include HTTPartyEx
    
  private
  
  def wrap_in_objects(type, results)
    objects = Array.new
    results[:data].each do |result|
      obj = OnTimeObject.new(base_uri, @access_token, @user_id)
      obj.id   = result[:id]
      obj.name = result[:name]
      obj.type = result[:type]
    end
  end
  
  public
  
  def initialize(a_name, c_id, c_secret)
    @account_name = a_name
    @client_id = c_id
    @client_secret = c_secret
    base_uri a_name + '.ontimenow.com'
  end
  
  def login(username, password)
    response = get('/api/oath2/token',
                    :query => { :grant_type    => "password",
                                :username      => username,
                                :password      => password,
                                :client_id     => @client_id,
                                :client_secret => @client_secret,
                                :scope         => 'read write'})
    
    if response.has_key? :error
      @error = response[:error]
      @error_desc = response[:error_description]
    else
    
      #{"access_token":"ec7cfcd1-dcb5-4ffb-8579-d811ecd6d2a6","token_type":"bearer","data":{"id":106,"first_name":"Jesse","last_name":"Rosalia","email":"jesse.rosalia@ad-juster.com"}}Jesses-MacBook-Pro:helpers thejenix$ 
      @access_token = response[:access_token];
      @user_id      = response[:data][:id];
      base_uri @account_name + '.ontimenow.com/api/v1'
    end
    
    return logged_in?
  end
  
  def logged_in?
    @access_token.nil?
  end
  
  def defects
    wrap_in_objects('defect', get('/defects', query({ user_id => @user_id })))
  end
  
  def features
    wrap_in_objects('feature', get('/features', query({ user_id => @user_id })))
  end
end
