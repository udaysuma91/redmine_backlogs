require_dependency 'projects_helper'

module Backlogs
  module ProjectsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        unloadable
        alias_method_chain :project_settings_tabs, :backlogs
      end
    end

    module InstanceMethods

      def project_settings_tabs_with_backlogs
        tabs = project_settings_tabs_without_backlogs
        tabs << {:name => 'backlogs',
          :action => :manage_project_backlogs,
          :partial => 'backlogs/project_settings',
          :label => :label_backlogs
        } if @project.module_enabled?('backlogs') and 
             User.current.allowed_to?(:configure_backlogs, nil, :global=>true)
        return tabs
      end

      # Returns a set of options for a select field, grouped by project.
      # override so we also see team of sprint/version.
      def version_options_for_select(versions, selected=nil)
        puts "===================================== we komen in de nieuwe functie :)"
        grouped = Hash.new {|h,k| h[k] = []}
        versions.each do |version|
          grouped[version.project.name] << [version.name_team, version.id]
        end

        selected = selected.is_a?(Version) ? selected.id : selected
        if grouped.keys.size > 1
          grouped_options_for_select(grouped, selected)
        else
          options_for_select((grouped.values.first || []), selected)
        end
      end

    end

  end
end

ProjectsHelper.send(:prepend, Backlogs::ProjectsHelperPatch) unless ProjectsHelper.included_modules.include? Backlogs::ProjectsHelperPatch

