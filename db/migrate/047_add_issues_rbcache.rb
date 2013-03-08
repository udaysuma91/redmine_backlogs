class AddIssuesRbcache < ActiveRecord::Migration
  def self.up
    add_column :issues, :release_burndown_cache, :text
  end

  def self.down
    remove_column :issues, :release_burndown_cache
  end
end
