class CreateRbReleasePlannings < ActiveRecord::Migration
  def change
    create_table :rb_release_plannings do |t|
      t.string :name
      t.text :description
      t.belongs_to :project
    end
  end
end
