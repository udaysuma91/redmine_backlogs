namespace :redmine do
  namespace :backlogs do
    task :release_setting_to_backlog => :environment do
      redmine_backlog = Setting.find_by_name("plugin_redmine_backlogs")
      if redmine_backlog.present?
        values = redmine_backlog.value
        values["default_generation_format_id"] = "1" unless redmine_backlog.value.has_key?("default_generation_format_id")
        values["issue_custom_field_id"] = "20" unless redmine_backlog.value.has_key?("issue_custom_field_id")
        values["field_value_not_required"] = "Not applicable" unless redmine_backlog.value.has_key?("field_value_not_required")
        values["field_value_todo"] = "Required" unless redmine_backlog.value.has_key?("field_value_todo")
        values["field_value_done"] = "Completed" unless redmine_backlog.value.has_key?("field_value_done")
        redmine_backlog.value = values
        redmine_backlog.save
      end
    end
  end
end
