class AddIndexToRbIssueReleasesIssueId < ActiveRecord::Migration
  def self.up
    add_index :rb_issue_releases, :issue_id
  end

  def self.down
    remove_index :rb_issue_releases, :issue_id
  end
end
