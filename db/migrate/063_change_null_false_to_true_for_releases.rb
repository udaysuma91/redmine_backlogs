class ChangeNullFalseToTrueForReleases < ActiveRecord::Migration
  def change
    change_column_null :releases, :release_start_date, true
    change_column_null :releases, :release_end_date, true
  end
end
