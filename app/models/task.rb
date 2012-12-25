class Task < ActiveRecord::Base

  attr_accessible :external_id, :name
  
  validates :external_id, :presence => true
  
  validates :name, :presence => true
  
  has_many :work_logs
end
