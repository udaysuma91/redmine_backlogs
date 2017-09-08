# Base class of all controllers in Redmine Backlogs
class RbApplicationController < ApplicationController
  unloadable

  before_filter :load_project, :authorize, :check_if_plugin_is_configured, :load_genericboard

  #provide list of javascript_include_tags which must be rendered before common.js
  def rb_jquery_plugins
    @rb_jquery_plugins
  end
  def rb_jquery_plugins=(html)
    @rb_jquery_plugins = html
  end

  private

  # Loads the project to be used by the authorize filter to
  # determine if User.current has permission to invoke the method in question.
  def load_project
    if params[:issue_release] && !params[:issue_release].empty?
      params[:release_id] = params[:issue_release][:release_id]
    end
    @project = if params[:sprint_id]
                 load_sprint
                 @sprint.project
               elsif params[:release_id] && !params[:release_id].empty?
                 load_release
                 @release.project
               elsif params[:release_multiview_id] && !params[:release_multiview_id].empty?
                 load_release_multiview
                 @release_multiview.project
               elsif params[:project_id]
                 Project.find(params[:project_id])
               elsif params[:issue_release_id]
                 load_issue_release
                 @issue_release.issue.project
               else
                 raise "Cannot determine project (#{params.inspect})"
               end
  end

  def check_if_plugin_is_configured
    @settings = Backlogs.settings
#    make a copy to workaround RuntimeError (can't modify frozen ActionController::Parameters):
    s1 = @settings.dup
    # stupid hack to make it also work for travis
    story_trackers = s1["story_trackers"] ? s1["story_trackers"] : s1[:story_trackers]
    task_tracker = s1["task_tracker"] ? s1["task_tracker"] : s1[:task_tracker]
    scaled_agile_enabled = s1["scaled_agile_enabled"] ? s1["scaled_agile_enabled"] : s1[:scaled_agile_enabled]
    epic_trackers = s1["epic_trackers"] ? s1["epic_trackers"] : s1[:epic_trackers]
    feature_trackers = s1["feature_trackers"] ? s1["feature_trackers"] : s1[:feature_trackers]
    if story_trackers.blank? || task_tracker.blank? || (scaled_agile_enabled && (epic_trackers.blank? || feature_trackers.blank?))
      puts("check_if_plugin_is_configured: no trackers for story or task, or if scaled agile is enabled for epic or feature, halting. " +
        "--#{s1[:story_trackers]}--#{s1[:task_tracker]}--#{s1[:scaled_agile_enabled]}--#{s1[:epic_trackers]}--#{s1[:feature_trackers]} ## " +
        "--#{s1["story_trackers"]}--#{s1["task_tracker"]}--#{s1["scaled_agile_enabled"]}--#{s1["epic_trackers"]}--#{s1["feature_trackers"]} ## " +
        "--#{story_trackers.blank?}--#{task_tracker.blank?}--#{scaled_agile_enabled}--#{epic_trackers.blank?}--#{feature_trackers.blank?} ## " +
        "settings: #{s1}")
      respond_to do |format|
        format.html { render :template => "backlogs/not_configured",  :handlers => [:erb], :formats => [:html] }
        format.js { }
      end
    end
  end

  def load_sprint
    @sprint = RbSprint.find(params[:sprint_id])
  end

  def load_release
    @release = RbRelease.find(params[:release_id])
  end

  def load_release_multiview
    @release_multiview = RbReleaseMultiview.find(params[:release_multiview_id])
  end

  def load_genericboard
    @genericboard = if Backlogs.setting[:scaled_agile_enabled] && params[:genericboard_id]
                      RbGenericboard.find(params[:genericboard_id])
                    else
                      nil
                    end

  end
  
  def load_issue_release
    @issue_release = RbIssueRelease.find(params[:issue_release_id])
  end
end
