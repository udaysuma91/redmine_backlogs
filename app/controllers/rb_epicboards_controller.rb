include RbCommonHelper

class FakeProductBacklog
  def id; 0 end
  def name; 'Product Backlog' end
end

class RbEpicboardsController < RbApplicationController
  unloadable

  def show
    cls = RbStory
    product_backlog_stories = cls.product_backlog(@project)
    @product_backlog = { :sprint => FakeProductBacklog.new,
      :type => 'productbacklog', :stories => product_backlog_stories||[] }

    sprints = @project.open_shared_sprints
    sprints_backlog_storie_of = cls.backlogs_by_sprint(@project, sprints)
    @sprint_backlogs = sprints.map{ |s| { :sprint => s,
      :type => 'sprint', :stories => sprints_backlog_storie_of[s.id]||[] } }

    releases = @project.open_releases_by_date
    releases_backlog_storie_of = cls.backlogs_by_release(@project, releases)
    @release_backlogs = releases.map{ |r| { :sprint => r,
      :type => 'release', :stories => releases_backlog_storie_of[r.id]||[] } }

    #This project
    #@epics = RbEpic.in_projects([@project]).epics.visible.order(:position)||[]

    #This project and subprojects
    @epics = RbEpic.epics.visible.
                open.
                order('issues.position').
                in_projects(@project.projects_in_shared_product_backlog)||[]
    #add All relevant from sprints and releases
    #sprints.each{|sprint|
    #  @epics += RbEpic.backlog(sprint.project.id, sprint.id, nil, {})||[]
    #}
    #releases.each{|release|
    #  @epics += RbEpic.backlog(release.project.id, nil, release.id {})||[]
    #}
    #@epics make unique and sort by position

    @columns = [@product_backlog,
                @release_backlogs,
                @sprint_backlogs
               ].flatten
    respond_to do |format|
      format.html { render :layout => "rb" }
    end
  end

end
