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
    
    @filters       = Hash.new
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
    wrap_in_objects('defects',  filter_raw(get('/defects',  :query => { :user_id => @user_id })))
  end
  
  def features
    wrap_in_objects('features', filter_raw(get('/features', :query => { :user_id => @user_id })))
  end
  
  def clear_filter
    @filters.clear
  end

  def filter_raw(results)
    filtered = Array.new
    # For each result, we want to apply the filters added using the filter_by_...methods
    results["data"].each do |result|
      good = true
      @filters.each do |name, values|
        key = name
        test = result
        # The filter name added using the filter_by methods may refer to inner hashes...this
        # tests successively shorter keys (by _) to find the hash that matches, then processes
        # the remainder keys against the hash value.
        # e.g. "workflow_step" => { "name": ..} will be specified as "workflow_step_name"
        begin
          remainder = ""
          # puts "Testing filter " + key
          while not test.has_key?(key)
            inx       = key.rindex("_")
            # Concat the remainder...this keeps the leading _, to keep separators between
            # parts of the remainder
            remainder = key[inx..key.length] + remainder
            key       = key[0..(inx-1)]
            # puts "Trying " + key + ", " + remainder
          end
          unless key.empty?
            # puts "Found key " + key + " looping around for remainder " + remainder
            test = test[key]
            # Skip the leading _
            key = remainder[1..remainder.length]
          end
        end while not remainder.empty?
        # puts "Value: " + test
        if values.include?(test)
          good = false
          break
        end
      end
      # Add good results to the filtered list
      if good
        filtered << result
      end  
    end
    # We took in a hash that contained data...so we need to return the same
    return { "data" => filtered }
  end
  
  def method_missing(method_id, *args)
    if match = /filter_by_([_a-zA-Z]\w*)/.match(method_id.to_s)
      attribute_name = match.captures.last #.split('_and_')
 
      pp attribute_name
      pp args[0]
      @filters[attribute_name] = args[0]
      return self
    else
      super
    end
  end
end
