class CreateRbReleasePlanning < ActiveRecord::Migration
  def self.up
    create_table :rb_release_plannings do |t|
      t.string :name
      t.text :description
      t.belongs_to :project
    end
  end

  def self.down
    drop_table :rb_release_plannings
  end
end
