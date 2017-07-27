class RemoveDefaultSprintRelease < ActiveRecord::Migration
  def self.up
    if ActiveRecord::Base.connection.column_exists?(:versions, :release_id)
      remove_column :versions, :release_id
    end
  end

  def self.down
    add_column :versions, :release_id, :integer
  end
end
