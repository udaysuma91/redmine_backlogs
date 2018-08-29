ApplicationHelper.module_eval do
  # Original generates a link to a version
  # Now generate a link to a sprint
  old_link_to_version = instance_method(:link_to_version)
  
  def link_to_version(version, options = {})
    return '' unless version && version.is_a?(Version)
    return old_link_to_version(version, options) unless Backlogs.configured?
    link_to_sprint(version, options.merge({:team => true}))
  end

  def format_object(object, html=true, &block)# override format_object method to display case_id with link
    if block_given?
      object = yield object
    end
    case object.class.name
    when 'Array'
      formatted_objects = object.map {|o| format_object(o, html)}
      html ? safe_join(formatted_objects, ', ') : formatted_objects.join(', ')
    when 'Time'
      format_time(object)
    when 'Date'
      format_date(object)
    when 'Fixnum'
      object.to_s
    when 'Float'
      sprintf "%.2f", object
    when 'User'
      html ? link_to_user(object) : object.to_s
    when 'Project'
      html ? link_to_project(object) : object.to_s
    when 'Version'
      html ? link_to_version(object) : object.to_s
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    when 'Issue'
      object.visible? && html ? link_to_issue(object) : "##{object.id}"
    when 'Attachment'
      html ? link_to_attachment(object) : object.filename
    when 'CustomValue', 'CustomFieldValue'
      if object.custom_field
        if object.custom_field.id == 1 && object.value.present?# && (params[:controller] == "issues" && params[:action] == "show")
          string = ""
          object.value.split(',').each_with_index do |case_id, i|
            if case_id.include? "CAS-"
              string+= "<a href='#{object.custom_field.format_store[:url_pattern]}#{case_id}' target='_blank'>#{case_id}</a>"
            else
              string += case_id
            end
            string+= ", " unless i == object.value.split(',').size - 1
          end
          f = string.html_safe
        else
          f = object.custom_field.format.formatted_custom_value(self, object, html)
        end
        if f.nil? || f.is_a?(String)
          f
        else
          format_object(f, html, &block)
        end
      else
        object.value.to_s
      end
    else
      html ? h(object) : object.to_s
    end
  end
end
