require_dependency 'application_helper'

module Backlogs
  module ApplicationHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        unloadable
        alias_method_chain :format_object, :backlogs
      end
    end

    module InstanceMethods

      def format_object_with_backlogs(object, html=true, &block)
        if object.class.name == "CustomFieldValue" || object.class.name == "CustomValue"
          if object.custom_field
            if object.custom_field.id == 1 && object.value.present?# && (params[:controller] == "issues" && params[:action] == "show")
              string = ""
              object.value.split(/[\s,]+/).each_with_index do |case_id, i|
                if case_id.starts_with?("CAS-")
                  string+= "<a href='#{object.custom_field.format_store[:url_pattern]}#{case_id}' target='_blank'>#{case_id}</a>"
                else
                  string += case_id
                end
                string+= ", " unless i == object.value.split(/[\s,]+/).size - 1
              end
              f = string.html_safe
            else
              f = object.custom_field.format.formatted_custom_value(self, object, html)
            end
            if f.nil? || f.is_a?(String)
              return f
            else
              return format_object(f, html, &block)
            end
          else
            return object.value.to_s
          end
          return html ? h(object) : object.to_s
        else
          format_object_without_backlogs(object, html=true, &block)
        end 
      end
    end

  end
end
ApplicationHelper.send(:include, Backlogs::ApplicationHelperPatch)

