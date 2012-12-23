class Task < ActiveRecord::Base

  validates :external_id, :presence => true
  
  validates :name, :presence => true
  
  has_many :work_logs
end
