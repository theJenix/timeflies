class TasksController < ApplicationController
  
  def initialize()
    @data = Hash.new
    task = Task.new
    task.name = "It's Broke"
    @data['1'] = task
    
    task = Task.new
    task.name = "Fix me"
    @data['2'] = task
    
    task = Task.new
    task.name = "Make it better"
    @data['3'] = task
    super
  end

  def add_log
    
    test = TestObj.new
    test.name = "woo"

    task = @data[params[:id]]
    log = WorkLog.new
    log.hours = params[:hours]
    log.description = params[:description]
    logger.debug params[:hours]
    logger.debug params[:description]
    task.work_logs << log
    render :action => 'logs'
  end

  def list
    render :data => @data
  end

  def edit
    render :item => @data[params[:id]]
  end

  def logs
    logger.debug params[:id]
    logger.debug @data[params[:id]]
    render :item => @data[params[:id]]
  end

  def view
    render :item => @data[params[:id]]
  end
end