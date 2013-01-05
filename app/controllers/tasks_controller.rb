require 'ontime'

class TasksController < ApplicationController
  include TasksHelper

  # Login handlers
  
  def do_login
    puts "Logging in for a new access token"
    ot = get_connection
    results = ot.login(params[:username], params[:password])
    if ot.logged_in?
      ot.store_login_info(session)
      redirect_to :action => 'list', :status => :see_other
    else
      # TODO: break out specific errors based on the actual problems
      redirect_to :action => 'login', :status => :see_other, :notice => 'Error logging in.  Please try again'
    end
  end

  def redir_login
    ot = get_connection
    ot.load_login_info(session)
    if ot.logged_in?
      redirect_to :action => 'list'
    else
      redirect_to :action => 'login'
    end
  end
  
  # Task list and work log handlers
  
  def add_log
    ot = get_connection;
    ot.load_login_info(session)
    if !ot.logged_in?
      redirect_to :action => 'login'
      return
    end
    
    if session.has_key? :items
      puts "Adding new work log"
      logger.debug params[:hours]
      logger.debug params[:description]
        
      items = session[:items]
      item  = lookup_by_id(items, params[:id].to_i)
    
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
    ot = get_connection
    ot.load_login_info(session)
    if !ot.logged_in?
      redirect_to :action => 'login'
    end

    ot.filter_by_workflow_step_name(APP_CONFIG['excluded_workflow_steps']) \
      .filter_by_status_name(       APP_CONFIG['excluded_statuses'])

    @items = ot.features + ot.defects
    # TODO move items out of the session, into the rails db for persistence between http requests
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
end
