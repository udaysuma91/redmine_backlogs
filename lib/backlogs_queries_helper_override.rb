QueriesHelper.module_eval do
  # Show linked releases
  def column_content(column, item) # override queries helper method
    value = column.value_object(item)
    if column.name == :releases
      releases = RbIssueRelease.where(issue_id: item.id).pluck(:release_id)
      RbRelease.where(id: releases).pluck(:name).join(', ')
    elsif value.is_a?(Array)
      values = value.collect {|v| column_value(column, item, v)}.compact
      safe_join(values, ', ')
    else
      column_value(column, item, value)
    end
  end
end
