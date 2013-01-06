include RbCommonHelper

class RbEpicboardsController < RbApplicationController
  unloadable

  def show
    @projects = @project.projects_in_shared_product_backlog #self or self and descendants
    stories = RbStory.in_projects(@projects).stories.visible.order(:position)
    @epics = RbEpic.in_projects(@projects).epics.visible.order(:position)
    @story_ids    = stories.map{|s| s.id}

    @settings = Backlogs.settings

    ## determine status columns to show
    tracker = Tracker.find_by_id(RbStory.trackers[0])
    statuses = tracker.issue_statuses
    # disable columns by default
    if User.current.admin? || stories.length == 0
      @statuses = statuses
    else
      enabled = {}
      statuses.each{|s| enabled[s.id] = false}
      # enable all statuses held by current tasks, regardless of whether the current user has access
      stories.each {|task| enabled[task.status_id] = true }
      enabled[IssueStatus.default.id] = true if stories.length == 0 #enable at least one if there are no stories

      roles = User.current.roles_for_project(@project)
      #@transitions = {}
      statuses.each {|status|

        # enable all statuses the current user can reach from any task status
        [false, true].each {|creator|
          [false, true].each {|assignee|

            allowed = status.new_statuses_allowed_to(roles, tracker, creator, assignee).collect{|s| s.id}
            #@transitions["c#{creator ? 'y' : 'n'}a#{assignee ? 'y' : 'n'}"] = allowed
            allowed.each{|s| enabled[s] = true}
          }
        }
      }
      @statuses = statuses.select{|s| enabled[s.id]}
    end

    if stories.size == 0
      @last_updated = nil
    else
      @last_updated = RbStory.find(:first,
                        :conditions => ['tracker_id in (?)', RbStory.trackers],
                        :order      => "updated_on DESC")
    end

    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

end
