require_dependency 'admin_controller'
require 'rubygems'

module Backlogs
  module AdminControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          alias_method_chain :plugins, :plugin_list # modify some_method method by adding your_action action
        end
      end

      module InstanceMethods
        def plugins_with_plugin_list # hide release note plugin from plugins list
          @plugins = Redmine::Plugin.all.select{|plugin| plugin.id != :redmine_release_notes}
        end
      end
  end    
end
AdminController.send :include, Backlogs::AdminControllerPatch
