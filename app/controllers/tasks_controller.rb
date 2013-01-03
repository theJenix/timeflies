require 'ontime'

class TasksController < ApplicationController
  
  def initialize()   
    super
  end

  def add_log
    if session.has_key? :items
      puts "Adding new work log"
      logger.debug params[:hours]
      logger.debug params[:description]
        
      items = session[:items]
      item  = lookup_by_id(items, params[:id].to_i)
    
      ot = session[:connection];
    
      log = ot.new_work_log()
      log.item      = item
      log.duration  = params[:hours].to_f
      log.desc      = params[:description]

      current_time  = Time.new.getutc
      log.date_time = current_time.strftime("%Y-%m-%dT%H:%M:%SZ")
    
      log.save
    
      redirect_to :action => 'logs'
    else
      puts "Something wrong...redirecting"
      redirect_to :action => 'list'
    end
  end

  def list
    ot = session[:connection];
    if not ot
      puts "Creating a new connection"
      ot = OnTimeConnection.new(APP_CONFIG['account_name'], ENV['ontime_client_id'], ENV['ontime_client_secret'])
      ot.login(ENV['ontime_username'], ENV['ontime_password'])

      ot.filter_by_workflow_step_name(APP_CONFIG['excluded_workflow_steps']) \
        .filter_by_status_name(       APP_CONFIG['excluded_statuses'])
      session[:connection]   = ot
    end

    @items = ot.features + ot.defects
    session[:items] = @items    
    render
  end

  def edit
    render :item => @data[params[:id]]
  end

  def logs
    logger.debug params[:id]
    if session.has_key? :items
      items = session[:items]
      @item = lookup_by_id(items, params[:id].to_i)
      logger.debug @item
      render 
    else
      redirect_to :action => 'list'
    end
  end

  def view
    items = session[:items]
    @item = lookup_by_id(items, params[:id].to_i)
    render 
  end
  
  def lookup_by_id(items, id)
    found = nil
    pp items
    items.each do |item|
      if item.id == id
        found = item
        break
      end
    end
    return found
  end
end
