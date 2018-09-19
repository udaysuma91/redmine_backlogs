class RbReleasePlanning < ActiveRecord::Base
  unloadable
  validates_presence_of :name
  validates_presence_of :project_id

  belongs_to :project
end
