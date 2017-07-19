class RbIssueRelease < ActiveRecord::Base

  include Redmine::SafeAttributes

  belongs_to :issue
  belongs_to :release, :class_name => 'RbRelease'
  validates :issue, uniqueness: { scope: :release }

  safe_attributes 'issue_id',
    'release_id'
    
  attr_accessible :issue_id, :release_id

  def init_journals(user)
    issue.init_journal(user) if issue
  end

end