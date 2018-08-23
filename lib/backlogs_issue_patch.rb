require_dependency 'issue'

module Backlogs
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        belongs_to :release, :class_name => 'RbRelease', :foreign_key => 'release_id'
        belongs_to :rbteam, :class_name => 'User', :foreign_key => 'rbteam_id'

        acts_as_list_with_gaps :default => (Backlogs.setting[:new_story_position] == 'bottom' ? 'bottom' : 'top')

        has_one :backlogs_history, :class_name => RbIssueHistory, :dependent => :destroy
        has_many :rb_release_burnchart_day_cache, :dependent => :delete_all

        belongs_to :rb_issue_release
        has_many :releases, :class_name => 'RbRelease', :through => :rb_issue_release

        validates_inclusion_of :release_relationship, :in => RbStory::RELEASE_RELATIONSHIP

        safe_attributes 'release_id','release_relationship' #FIXME merge conflict. is this required?
        safe_attributes 'rbteam_id'

        after_create :set_wbso_field #set parent story wbso field to chield task if chield task wbso field blank

        before_save :backlogs_before_save
        after_save  :backlogs_after_save

        include Backlogs::ActiveRecord::Attributes
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def history
        @history ||= RbIssueHistory.where(:issue_id => self.id).first_or_initialize
      end

      def release_burnchart_day_caches(release_id)
        RbReleaseBurnchartDayCache.where(:issue_id => self.id, :release_id => release_id)
      end

      def is_epic?
        return RbEpic.trackers.include?(tracker_id)
      end

      def is_feature?
        return RbGeneric.feature_trackers.include?(tracker_id)
      end

      def is_story?
        RbStory.trackers_include?(tracker_id)
      end

      def is_rbgeneric?
        [].concat(RbGeneric.feature_trackers).concat(RbEpic.trackers).concat(RbGeneric.trackers).include?(tracker_id)
      end

      def is_task?
        RbTask.tracker?(tracker_id)
      end

      def backlogs_issue_type
        return "story" if self.is_story?
        return "impediment" if self.blocks(true).any?
        return "task" if self.is_task?
        ""
      end

      def story
        if @rb_story.nil?
          if self.new_record?
            parent_id = self.parent_id
            parent_id = self.parent_issue_id if parent_id.blank?
            parent_id = nil if parent_id.blank?
            parent = parent_id ? Issue.find(parent_id) : nil

            if parent.nil?
              @rb_story = nil
            elsif parent.is_story?
              @rb_story = parent.becomes(RbStory)
            else
              @rb_story = parent.story
            end
          else
            @rb_story = Issue.where("root_id = ? and lft < ? and rgt > ? and tracker_id in (?)", root_id, lft, rgt, RbStory.trackers)
                              .order('lft DESC').first
            @rb_story = @rb_story.becomes(RbStory) if @rb_story
          end
        end
        return @rb_story
      end

      def blocks(include_closed = false)
        # return issues that I block that aren't closed
        return [] if closed? and !include_closed
        begin
          return relations_from.collect {|ir| ir.relation_type == 'blocks' && (!ir.issue_to.closed? || include_closed) ? ir.issue_to : nil }.compact
        rescue
          # stupid rails and their ignorance of proper relational databases
          Rails.logger.error "Cannot return the blocks list for #{self.id}: #{e}"
          return []
        end
      end

      def blockers
        # return issues that block me
        return [] if closed?
        relations_to.collect {|ir| ir.relation_type == 'blocks' && !ir.issue_from.closed? ? ir.issue_from : nil}.compact
      end

      def velocity_based_estimate
        return nil if !self.is_story? || ! self.story_points || self.story_points <= 0

        hpp = self.project.scrum_statistics.hours_per_point
        return nil if ! hpp

        return Integer(self.story_points * (hpp / 8))
      end

      def set_wbso_field
        wbso_field_chield = self.custom_values.find_by(custom_field_id: 19)
        if (wbso_field_chield.value.blank? && self.parent_id.present?)
          wbso_parent = self.parent.custom_values.find_by(custom_field_id: 19)
          wbso_field_chield.update_columns(value: wbso_parent.value) if wbso_parent.value.present?
        end
      end

      def backlogs_before_save
        if Backlogs.configured?(project)

          #story follow feature release
          if Backlogs.setting[:scaled_agile_enabled] && self.is_story?
            self.release = self.parent.release if (self.parent && self.parent.is_feature?)
          end

          if self.is_story?
            if Backlogs.setting[:estimated_hours_per_point].to_f > 0 && self.story_points? && self.story_points > 0
              self.estimated_hours = Backlogs.setting[:estimated_hours_per_point].to_f * self.story_points
            end
          end

          if (self.is_task? || self.story)
            if Backlogs.setting[:scaled_agile_enabled]
              self.rbteam_id = self.parent.rbteam_id unless self.parent.blank?
            end
            self.remaining_hours = self.estimated_hours if self.remaining_hours.blank?
            self.estimated_hours = self.remaining_hours if self.estimated_hours.blank?

            self.remaining_hours = 0 if self.status.backlog_is?(:success, self.tracker)

            self.fixed_version = self.story.fixed_version if self.story
            self.start_date = Date.today if self.start_date.blank? && self.status_id != self.tracker.default_status.id

            self.tracker = Tracker.find(RbTask.tracker) unless self.tracker_id == RbTask.tracker
          elsif self.is_story? && Backlogs.setting[:set_start_and_duedates_from_sprint]
            if self.fixed_version
              self.start_date ||= (self.fixed_version.sprint_start_date || Date.today)
              self.due_date ||= self.fixed_version.effective_date
              self.due_date = self.start_date if self.due_date && self.due_date < self.start_date
            else
              self.start_date = nil
              self.due_date = nil
            end
          end
        end
        self.remaining_hours = self.leaves.sum("COALESCE(remaining_hours, 0)").to_f unless self.leaves.empty?

        self.move_to_top if self.position.blank? || (@copied_from.present? && @copied_from.position == self.position)

        # scrub position from the journal by copying the new value to the old
        @attributes_before_change['position'] = self.position if @attributes_before_change

        @backlogs_new_record = self.new_record?

        return true
      end

      def invalidate_release_burnchart_data
        RbReleaseBurnchartDayCache.delete_all(["issue_id = ? AND day >= ?",self.id,Date.today])
        #FIXME Missing cleanup of older cache entries which is no longer
        # valid for any releases. Delete cache entries not related to
        # current release?
      end

      def backlogs_after_save
        self.history.save!
        self.invalidate_release_burnchart_data

        [self.parent_id, self.parent_id_was].compact.uniq.each{|pid|
          p = Issue.find(pid)
          r = p.leaves.sum("COALESCE(remaining_hours, 0)").to_f
          if r != p.remaining_hours
            p.update_attribute(:remaining_hours, r)
            p.history.save
          end
        }

        return unless Backlogs.configured?(self.project)

        # stories (and their tasks) follow feature release
        if Backlogs.setting[:scaled_agile_enabled] && self.is_feature?
            self.class.connection.execute("update issues set
                               updated_on = #{self.class.connection.quote(self.updated_on)},
                               release_id = #{self.class.connection.quote(self.release_id)}
                               where root_id=#{self.class.connection.quote(self.root_id)} and
                                  lft > #{self.class.connection.quote(self.lft)} and
                                  rgt < #{self.class.connection.quote(self.rgt)} and
                                  (tracker_id in (#{self.class.connection.quote(RbTask.tracker)})
                                   or
                                   tracker_id in (#{RbGeneric.story_trackers({:type=>:array}).join(',')})
                                  )
                               ")

        end

        if self.is_story?
          # raw sql and manual journal here because not
          # doing so causes an update loop when Issue calls
          # update_parent :<
          tasklist = RbTask.where("root_id=? and lft>? and rgt<? and
                                          (
                                            (? is NULL and not fixed_version_id is NULL)
                                            or
                                            (not ? is NULL and fixed_version_id is NULL)
                                            or
                                            (not ? is NULL and not fixed_version_id is NULL and ?<>fixed_version_id)
                                            or
                                            (tracker_id <> ?)
                                          )", self.root_id, self.lft, self.rgt,
                                              self.fixed_version_id, self.fixed_version_id,
                                              self.fixed_version_id, self.fixed_version_id,
                                              RbTask.tracker).all.to_a
          tasklist.each{|task| task.history.save! }
          if tasklist.size > 0
            task_ids = '(' + tasklist.collect{|task| self.class.connection.quote(task.id)}.join(',') + ')'
            self.class.connection.execute("update issues set
                                updated_on = #{self.class.connection.quote(self.updated_on)},
                                fixed_version_id = #{self.class.connection.quote(self.fixed_version_id)},
                                tracker_id = #{RbTask.tracker}
                                where id in #{task_ids}")
          end

          if Backlogs.setting[:scaled_agile_enabled]
            #force tasks to have same team as story
            self.class.connection.execute("update issues set
                               updated_on = #{self.class.connection.quote(self.updated_on)},
                               rbteam_id = #{self.class.connection.quote(self.rbteam_id)}
                               where root_id=#{self.class.connection.quote(self.root_id)} and
                                  lft > #{self.class.connection.quote(self.lft)} and
                                  rgt < #{self.class.connection.quote(self.rgt)} and
                                  tracker_id in (#{self.class.connection.quote(RbTask.tracker)})
                               ")
          end
        end #is_story?
      end

      def assignable_releases
        project.shared_releases
      end

      def release_id=(rid)
        self.release = nil
        write_attribute(:release_id, rid)
      end

      def rbteam
        Group.find(rbteam_id)
      rescue
        nil
      end

      def rbteam_id=(tid)
        write_attribute(:rbteam_id, tid)
      end

      def issue_releases
        @IssueReleases = RbIssueRelease.where(:issue_id => self.id).to_a
      end

      # Called after a release relation is added
      def release_added(release)
        if current_journal
          current_journal.journalize_release(release, :added)
          current_journal.save
        end
      end
    
      # Called after a release relation is removed
      def release_removed(release)
        if current_journal
          current_journal.journalize_release(release, :removed)
          current_journal.save
        end
      end

    end
  end
end

Issue.send(:include, Backlogs::IssuePatch) unless Issue.included_modules.include? Backlogs::IssuePatch
