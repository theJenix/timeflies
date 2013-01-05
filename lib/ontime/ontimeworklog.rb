require 'httparty'
require 'json'
require 'pp'

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
  
 # debug_output $stderr
  
  @id
  @item
  @desc
  @date_time
  @duration
  @old_duration
  @work_units
  
  attr_accessor :id, :item, :desc, :date_time, :duration, :old_duration, :work_units
  
  def initialize(a_name, a_token, u_id)
    base_uri build_base_uri(a_name, '/v1')
    default_params :access_token => a_token
    
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

    # If there's an ID set, we want to update the existing record.
    # Otherwise, post a new record.  In either case, we're sending the same data
    if @id
      # Compute the duration left based on the item's remaining duration, and the delta between
      # the current duration and old duration.  This could increase the remaining duration
      # if duration < old_duration
      delta         = @duration - @old_duration
      duration_left = [@item.remaining_duration - delta, 0].max
      uri           = "/work_logs/#{id}"
    else
      # For new work logs, we don't care about old_duration...just subtract the duration from
      # remaining duration
      duration_left = [@item.remaining_duration - @duration, 0].max
      uri           = '/work_logs'
    end
    #TODO: this hardcodes the time unit to "hours"...need to be more flexible eventually
    body = { :user => { :id => @user_id },
             :item => { :id => @item.id, :item_type => @item.type },
             :description => @desc,
             :date_time   => @date_time,
             :work_done      => { :duration => @duration,     :time_unit => { :id => 2 } },
             :remaining_time => { :duration => duration_left, :time_unit => { :id => 2 } },
           }

    response = post(uri, {:body => body.to_json, :headers => { 'Content-Type' => 'application/json' }})
    # Return whether or not the item was updated on the server
    data = response["data"]
    updated = data["itemUpdated"]
    
    # It's been updated on the server...update the old_duration and id fields
    if updated
      @old_duration = @duration
      @id = data["id"]
    end

    return updated
  end
end
