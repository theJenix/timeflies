class OnTimeItem
  include HTTParty
  include OnTimeInterface
  
  debug_output $stderr
  
  @id
  @name
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
        obj.old_duration = result["work_done"]["duration"]
        obj.duration = result["work_done"]["duration"]
        objects << obj
      end
    end
    return objects
  end
  
  public
  
  def initialize(a_name, a_token, u_id)
    base_uri build_base_uri(a_name, '/v1')
    default_params :access_token => a_token
    
    @account_name = a_name
    @access_token = a_token
    @user_id      = u_id
  end
    
  def remaining_duration
    response = get("/#{type}/#{id}", {})
    data = response["data"]
    return data["remaining_duration"]["duration"]
  end
  
  def work_logs
    #{"work_log_type"=>{"name"=>"", "id"=>0}, "description"=>"", "user"=>{"name"=>"Peter Yang", "id"=>100}, "id"=>5,
    # "work_done"=>{"time_unit"=>{"abbreviation"=>"hrs", "name"=>"Hours", "id"=>2}, "duration"=>1.0},
    # "item"=>{"name"=>"Reporting Change", "id"=>13, "item_type"=>"defects"}, "date_time"=>"2012-07-02T05:00:00Z"}
    # NOTE: this is a bit of a hack, because filtering by item_id doesn't work
    #get('/work_logs', query({ :item_types => @type, :item_id => @id }))
    wrap_in_objects(get('/work_logs', :query => { :item_types => @type, :user_id => @user_id }))
  end
  
#  def inspect
#    self.name
#  end
    
  def to_s
    self.name
  end
end
