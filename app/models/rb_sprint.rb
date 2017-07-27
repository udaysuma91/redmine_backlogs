require 'date'
require 'version'

class RbSprint < Version
  unloadable

  validate :start_and_end_dates

  belongs_to :release, :class_name => 'RbRelease', :foreign_key => 'release_id'

  def start_and_end_dates
    errors.add(:base, l(:error_sprint_end_before_start) ) if self.effective_date && self.sprint_start_date && self.sprint_start_date >= self.effective_date
  end

  scope :open_sprints, lambda { |project| open_or_locked.by_date.in_project(project) }
  scope :closed_sprints, lambda { |project| closed.by_date.in_project(project) }

  scope :closed, -> { where(:status => 'closed') }
  scope :open_or_locked, -> { where(:status => ['open', 'locked']) }

  def self.by_date_clause
    dir = Backlogs.setting[:sprint_sort_order] == 'desc' ? 'DESC' : 'ASC'
    "CASE #{table_name}.sprint_start_date WHEN NULL THEN 1 ELSE 0 END #{dir},
     #{table_name}.sprint_start_date #{dir},
     CASE #{table_name}.effective_date WHEN NULL THEN 1 ELSE 0 END #{dir},
     #{table_name}.effective_date #{dir}"
  end
  scope :by_date, -> { order(by_date_clause) }
  scope :in_project, lambda {|project| where(:project_id => project) }

  safe_attributes 'sprint_start_date',
      'story_points'
  
  #depending on sharing mode
  #return array of projects where this sprint is visible
  def shared_to_projects(scope_project)
    @shared_projects ||=
      begin
        # Project used when fetching tree sharing
        r = self.project.root? ? self.project : self.project.root
        # Project used for other sharings
        p = self.project
        Project.visible.joins('LEFT OUTER JOIN versions ON versions.project_id = projects.id').
          includes(:versions).
          where(["#{Version.table_name}.id = #{id}" +
          " OR (#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED} AND (" +
          " 'system' = ? " +
          " OR (#{Project.table_name}.lft >= #{r.lft} AND #{Project.table_name}.rgt <= #{r.rgt} AND ? = 'tree')" +
          " OR (#{Project.table_name}.lft > #{p.lft} AND #{Project.table_name}.rgt < #{p.rgt} AND ? IN ('hierarchy', 'descendants'))" +
          " OR (#{Project.table_name}.lft < #{p.lft} AND #{Project.table_name}.rgt > #{p.rgt} AND ? = 'hierarchy')" +
          "))",sharing,sharing,sharing,sharing]).order('lft').distinct
      end
    @shared_projects
  end

  def stories
    return RbStory.sprint_backlog(self)
  end

  def points
    return stories.inject(0){|sum, story| sum + story.story_points.to_i}
  end

  def has_wiki_page
    return false if wiki_page_title.blank?

    page = project.wiki.find_page(self.wiki_page_title)
    return false if !page

    template = find_wiki_template
    return false if template && page.text == template.text

    return true
  end

  def find_wiki_template
    projects = [self.project] + self.project.ancestors

    template = Backlogs.setting[:wiki_template]
    if template =~ /:/
      p, template = *template.split(':', 2)
      projects << Project.find(p)
    end

    projects.compact!

    projects.each{|p|
      next unless p.wiki
      t = p.wiki.find_page(template)
      return t if t
    }
    return nil
  end

  def rb_wiki_page
    if ! project.wiki
      return ''
    end

    self.update_attribute(:wiki_page_title, Wiki.titleize(self.name)) if wiki_page_title.blank?

    page = project.wiki.find_page(self.wiki_page_title)
    if !page
      template = find_wiki_template
      if template
      page = WikiPage.new(:wiki => project.wiki, :title => self.wiki_page_title)
      page.content = WikiContent.new
      page.content.text = "h1. #{self.name}\n\n#{template.text}"
      page.save!
      end
    end

    return wiki_page_title
  end

  def eta
    return nil if ! self.sprint_start_date

    dpp = self.project.scrum_statistics.info[:average_days_per_point]
    return nil if !dpp

    derived_days = if Backlogs.setting[:include_sat_and_sun]
                     Integer(self.points * dpp)
                   else
                     # 5 out of 7 are working days
                     Integer(self.points * dpp * 7.0/5)
                   end
    return self.sprint_start_date + derived_days
  end

  def activity
    bd = self.burndown

    # assume a sprint is active if it's only 2 days old
    return true if bd[:hours_remaining] && bd[:hours_remaining].compact.size <= 2

    return Issue.exists?(['fixed_version_id = ? and ((updated_on between ? and ?) or (created_on between ? and ?))', self.id, -2.days.from_now, Time.now, -2.days.from_now, Time.now])
  end

  def impediments
    @impediments ||= Issue.where(
            ["id in (
              select issue_from_id
              from issue_relations ir
              join issues blocked
                on blocked.id = ir.issue_to_id
                and blocked.tracker_id in (?)
                and blocked.fixed_version_id = (?)
              where ir.relation_type = 'blocks'
              )",
            RbStory.trackers + [RbTask.tracker],
            self.id]
      ) #.sort {|a,b| a.closed? == b.closed? ?  a.updated_on <=> b.updated_on : (a.closed? ? 1 : -1) }
  end

  #override version load_issue_count to count only stories
  def load_issue_counts
    unless @issue_count
      @open_issues_count = 0
      @closed_issues_count = 0
      stories.group(:status).count.each do |status, count|
        if status.is_closed?
          @closed_issues_count += count
        else
          @open_issues_count += count
        end
      end
      @issue_count = @open_issues_count + @closed_issues_count
    end
  end
  
  # Returns the average estimated time of assigned issues
  # or 1 if no issue has an estimated time
  # Used to weight unestimated issues in progress calculation
  def estimated_average
    if @estimated_average.nil?
      average = stories.average(:estimated_hours).to_f
      if average == 0
        average = 1
      end
      @estimated_average = average
    end
    @estimated_average
  end

  # Returns the total progress of open or closed issues.  The returned percentage takes into account
  # the amount of estimated time set for this version.
  #
  # Examples:
  # issues_progress(true)   => returns the progress percentage for open issues.
  # issues_progress(false)  => returns the progress percentage for closed issues.
  #override version issue_progress to count only stories
  def issues_progress(open)
    @issues_progress ||= {}
    @issues_progress[open] ||= begin
      progress = 0
      if issues_count > 0
        ratio = open ? 'done_ratio' : 100

        done = stories.open(open).sum("COALESCE(estimated_hours, #{estimated_average}) * #{ratio}").to_f
        progress = done / (estimated_average * issues_count)
      end
      progress
    end
  end
  
  def sprint_points
    load_sprint_points
    @sprint_points
  end

  def sprint_points_display(notsized='-')
    format_story_points(sprint_points, notsized)
  end

  def release_id=(rid)
    self.release = nil
    write_attribute(:release_id, rid)
  end

  private
  
  def load_sprint_points
    unless @sprint_points
      @sprint_points = stories.sum(:story_points)
    end
  end
end
