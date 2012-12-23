class WorkLog < ActiveRecord::Base

  validates :hours, :presence => true, :numericality => true
  
  validates :description, :presence => true
    
  belongs_to :task
end
