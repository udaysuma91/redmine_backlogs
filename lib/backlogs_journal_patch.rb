require_dependency 'journal'

module Backlogs
  module JournalPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end
    
    module ClassMethods
    end

    module InstanceMethods

      # Adds a journal detail for an issue release relation that was added or removed
      def journalize_release(release, added_or_removed)
        key = (added_or_removed == :removed ? :old_value : :value)
        details << JournalDetail.new(
            :property  => 'RbRelease',
            :prop_key  => 'release',
            key => release.release.id
          )
      end

    end
  end
end

Journal.send(:include, Backlogs::JournalPatch) unless Journal.included_modules.include? Backlogs::JournalPatch