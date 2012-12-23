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

  def list
    render :data => @data
  end

  def edit
    render :item => @data[params[:id]]
  end

  def view
    render :item => @data[params[:id]]
  end
end
