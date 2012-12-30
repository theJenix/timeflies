require 'httparty'
require 'json'
require 'pp'

module OnTimeInterface
  
  def build_base_uri(account_name, query)
    return 'https://' + account_name + '.ontimenow.com/api' + query
  end

  def base_uri(uri)
    self.class.base_uri uri
  end

  def default_params(params)
    self.class.default_params params
  end

  def get(query, options)
    self.class.get(query, options)
  end

  def post(query, options, &block)
    self.class.post(query, options) { block }
  end

  def query(params)
    { :query => { :access_token => @access_token }.merge(params) }
  end
end  
  
=begin
BODY DATA 	A json object with the following properties:

work_done: (object) Amount of time associated with this work log

    duration: (float) Duration of work for the work log. Used in conjuction the the time_unit. Required
    time_unit: (object) Time unit the duration represents
        id: (integer) ID of the time unit. Required


work_log_type: (object) Type of work performed

    id: (integer) ID of the work log type. Required


description: (string) Description of work.

date_time: (date) Date that the work took place.

remaining_time: (object) Time remaining for the item associated with this work log.

    duration: (float) Duration of work left for this work logs item, used in conjuction the the time_unit. Required
    time_unit: (object) Time unit the duration represents
        id: (integer) ID of the time unit. Required
=end
  
class OnTimeWorkLog
  include HTTParty
  include OnTimeInterface
  
  debug_output $stderr
  
  @id
  @item
  @desc
  @date_time
  @duration
  @old_duration
  @work_units
  
  attr_accessor :id, :desc, :date_time, :duration, :old_duration, :work_units
  
  def initialize(a_name, a_token, u_id)
    base_uri build_base_uri(a_name, '/v1')
    
    @access_token = a_token
    @user_id      = u_id
    
    @old_duration = 0
    @duration     = 0
  end

  def save
    # Use the current time as "date/time worked".  This makes the assumption that
    # the app will be used to log time immediately after performing it.
    #current_time = Time.new.getutc
    #time_str     = current_time.strftime("%Y-%m-%dT%H:%M:%SZ")
    
    delta = @duration - @old_duration
    duration_left = [@item.remaining_duration - delta, 0].max
    
    body = { :user => { :id => @user_id },
             :item => { :id => @item.id, :item_type => @item.type },
             :date_time => @date_time,
             :work_done      => { :duration => @duration,     :time_unit => { :id => 2 } },
             :remaining_time => { :duration => duration_left, :time_unit => { :id => 2 } },
           }

    # If there's an ID set, we want to update the existing record.
    # Otherwise, post a new record.  In either case, we're sending the same data
    if @id
      response = post("/work_logs/#{id}", query({}).merge({:body => body.to_json, :headers => { 'Content-Type' => 'application/json' }}))
    else
      response = post('/work_logs',       query({}).merge({:body => body.to_json, :headers => { 'Content-Type' => 'application/json' }}))
    end
    pp response
    
  end
end

class OnTimeItem
  include HTTParty
  include OnTimeInterface
  
  debug_output $stderr
  
  @id
  @name
  @remaining_estimate
  @type
    
  attr_accessor :id, :name, :type

  private
  
  def wrap_in_objects(results)
    objects = Array.new
    results["data"].each do |result|
      # Only store work log items for this object
      if @id == result["item"]["id"]
        obj = OnTimeWorkLog.new(@account_name, @access_token, @user_id)
        obj.item = self
        obj.id   = result["id"]
        obj.desc = result["description"]
        obj.date_time = result["date_time"]
        obj.work_done = result["work_done"]["duration"]
        objects << obj
      end
    end
    return objects
  end
  
  public
  
  def initialize(a_name, a_token, u_id)
    base_uri build_base_uri(a_name, '/v1')
    
    @access_token = a_token
    @user_id      = u_id
  end
    
  def remaining_duration
    response = get("/#{id}", query({}))
    return response["remaining_duration"]["duration"]
  end
  
  def work_logs
    #{"work_log_type"=>{"name"=>"", "id"=>0}, "description"=>"", "user"=>{"name"=>"Peter Yang", "id"=>100}, "id"=>5,
    # "work_done"=>{"time_unit"=>{"abbreviation"=>"hrs", "name"=>"Hours", "id"=>2}, "duration"=>1.0},
    # "item"=>{"name"=>"Reporting Change", "id"=>13, "item_type"=>"defects"}, "date_time"=>"2012-07-02T05:00:00Z"}
    # NOTE: this is a bit of a hack, because filtering by item_id doesn't work
    #get('/work_logs', query({ :item_types => @type, :item_id => @id }))
    wrap_in_objects(get('/work_logs', query({ :item_types => @type, :user_id => @user_id}))
  end
  
  def inspect
    self.name
  end
    
  def to_s
    self.name
  end
end
    
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
      #default_params :access_token => @access_token
    end
    
    return logged_in?
  end
  
  def logged_in?
    !@access_token.nil?
  end
  
  def defects
    wrap_in_objects('defect',  get('/defects',  query({ :user_id => @user_id })))
  end
  
  def features
    wrap_in_objects('features', get('/features', query({ :user_id => @user_id })))
  end
end
