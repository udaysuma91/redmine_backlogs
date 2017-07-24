class RbIssueRelease < ActiveRecord::Base

  include Redmine::SafeAttributes

  belongs_to :issue
  belongs_to :release, :class_name => 'RbRelease'
  validates :issue, uniqueness: { scope: :release }

  safe_attributes 'issue_id',
    'release_id'
    
  attr_accessible :issue_id, :release_id
 
  after_create  :call_issues_release_added_callback
  after_destroy :call_issues_release_removed_callback
 
  def init_journals(user)
    issue.init_journal(user) if issue
  end

  def call_issues_release_added_callback
    call_issues_callback :release_added
  end

  def call_issues_release_removed_callback
    call_issues_callback :release_removed
  end

  def call_issues_callback(name)
    issue.send(name, self) if issue
  end

end