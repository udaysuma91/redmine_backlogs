class RbGeneric < Issue
  unloadable

  RELEASE_RELATIONSHIP = %w(auto initial continued added)

  private


  def self.__find_options_normalize_option(option)
    option = [option] if option && !option.is_a?(Array)
    option = option.collect{|s| s.is_a?(Integer) ? s : s.id} if option
  end

  def self.__find_options_add_permissions(options)
    permission = options.delete(:permission)
    permission = false if permission.nil?

    options[:conditions] ||= []
    if permission
      if Issue.respond_to? :visible_condition
        visible = Issue.visible_condition(User.current, :project => project || Project.find(project_id))
      else
        visible = Project.allowed_to_condition(User.current, :view_issues)
      end
      Backlogs::ActiveRecord.add_condition(options, visible)
    end
  end

  def self.__find_options_sprint_condition(project_id, sprint_ids, tracker_ids)
    if Backlogs.setting[:sharing_enabled]
      ["
        tracker_id in (?)
        and fixed_version_id IN (?)", tracker_ids, sprint_ids]
    else
      ["
        project_id = ?
        and tracker_id in (?)
        and fixed_version_id IN (?)", project_id, tracker_ids, sprint_ids]
    end
  end

  def self.__find_options_release_condition(project_id, release_ids, tracker_ids)
    ["
      project_id in (#{Project.find(project_id).projects_in_shared_product_backlog.map{|p| p.id}.join(',')})
      and tracker_id in (?)
      and fixed_version_id is NULL
      and release_id in (?)", tracker_ids, release_ids]
  end

  def self.__find_options_pbl_condition(project_id, tracker_ids, include_releases)
    if include_releases
    ["
      project_id in (#{Project.find(project_id).projects_in_shared_product_backlog.map{|p| p.id}.join(',')})
      and tracker_id in (?)
      and fixed_version_id is NULL
      and is_closed = ?", tracker_ids, false]
    else
      ["
      project_id in (#{Project.find(project_id).projects_in_shared_product_backlog.map{|p| p.id}.join(',')})
      and tracker_id in (?)
      and release_id is NULL
      and fixed_version_id is NULL
      and is_closed = ?", tracker_ids, false]
    end
  end

  def self.__find_options_generic_condition(project_id, tracker_ids)
    ["
      project_id in (#{Project.find(project_id).projects_in_shared_product_backlog.map{|p| p.id}.join(',')})
      and tracker_id in (?)", tracker_ids
    ]
  end

  public

  def self.find_options(options, generic_scope=false)
    Rails.logger.info "Options: #{options}"
    options = options.dup

    project = options.delete(:project)
    if project.nil?
      project_id = nil
    elsif project.is_a?(Integer)
      project_id = project
      project = nil
    else
      project_id = project.id
    end

    self.__find_options_add_permissions(options)

    include_releases = options.delete(:include_releases)

    sprint_ids = self.__find_options_normalize_option(options.delete(:sprint))
    release_ids = self.__find_options_normalize_option(options.delete(:release))
    tracker_ids = self.__find_options_normalize_option(options.delete(:trackers) || self.trackers)
    Rails.logger.info "SprintId: #{sprint_ids}; ReleaseId: #{release_ids}; TrackerId: #{tracker_ids}; GenScope: #{generic_scope};"
    if generic_scope
      Backlogs::ActiveRecord.add_condition(options, self.__find_options_generic_condition(project_id, tracker_ids))
      options[:joins] ||= []
      options[:joins] [options[:joins]] unless options[:joins].is_a?(Array)
      options[:joins] << :status
      options[:joins] << :project
    elsif sprint_ids
      Backlogs::ActiveRecord.add_condition(options, self.__find_options_sprint_condition(project_id, sprint_ids, tracker_ids))
    elsif release_ids
      Backlogs::ActiveRecord.add_condition(options, self.__find_options_release_condition(project_id, release_ids, tracker_ids))
    else #product backlog
      Backlogs::ActiveRecord.add_condition(options, self.__find_options_pbl_condition(project_id, tracker_ids, include_releases))
      options[:joins] ||= []
      options[:joins] [options[:joins]] unless options[:joins].is_a?(Array)
      options[:joins] << :status
      options[:joins] << :project
    end

    joins(options[:joins]).includes(options[:joins]).where(options[:conditions])
  end

  scope :backlog_scope, lambda{|opts={}| self.find_options(opts) }
  scope :generic_backlog_scope, lambda{|opts| self.find_options(opts, true) }

  def list_with_gaps_options
    {
      :project => self.project_id,
      :sprint => self.fixed_version_id,
      :release => self.release_id
    }
  end

  def self.trackers(options = {})
    self.get_trackers(:story_trackers, options)
  end

  def self.story_trackers(options = {})
    self.get_trackers(:story_trackers, options)
  end

  def self.feature_trackers(options = {})
    self.get_trackers(:feature_trackers, options)
  end

  def self.all_trackers(tracker_id)
    if RbEpic.trackers(:type=>:array).include?(tracker_id)
      return RbEpic.trackers
    elsif self.feature_trackers(:type=>:array).include?(tracker_id)
      return self.feature_trackers
    elsif self.story_trackers(:type=>:array).include?(tracker_id)
      return self.story_trackers
    elsif tracker_id == RbTask.tracker
      return [RbTask.tracker]
    end

  end

  def self.get_trackers(trackersettings, options = {})
    # legacy
    options = {:type => options} if options.is_a?(Symbol)

    # somewhere early in the initialization process during first-time migration this gets called when the table doesn't yet exist
    trackers = []
    if has_settings_table
      trackers = Backlogs.setting[trackersettings]
      trackers = [] if trackers.blank?
    end

    trackers = Tracker.where(id: trackers)
    trackers = trackers & options[:project].trackers if options[:project]
    trackers = trackers.sort_by { |t| [t.position] }

    case options[:type]
      when :trackers      then return trackers
        when :array, nil  then return trackers.collect{|t| t.id}
        when :string      then return trackers.collect{|t| t.id.to_s}.join(',')
        else                   raise "Unexpected return type #{options[:type].inspect}"
    end
  end

  def self.has_settings_table
    ActiveRecord::Base.connection.tables.include?('settings')
  end

  def self.create_and_position(params)
    params['prev'] = params.delete('prev_id') if params.include?('prev_id')
    params['next'] = params.delete('next_id') if params.include?('next_id')
    params['prev'] = nil if (['next', 'prev'] - params.keys).size == 2

    # lft and rgt fields are handled by acts_as_nested_set
    attribs = params.select{|k,v| !['prev', 'next', 'id', 'lft', 'rgt'].include?(k) && RbStory.column_names.include?(k) }
    attribs[:status] = RbStory.class_default_status
    attribs = Hash[*attribs.flatten]
    s = self.new(attribs)
    s.save!
    s.position!(params)

    return s
  end

  def update_and_position!(params)
    params['prev'] = params.delete('prev_id') if params.include?('prev_id')
    params['next'] = params.delete('next_id') if params.include?('next_id')
    self.position!(params)

    # lft and rgt fields are handled by acts_as_nested_set
    attribs = params.select{|k,v| !['prev', 'id', 'project_id', 'lft', 'rgt'].include?(k) && RbStory.column_names.include?(k) }
    attribs = Hash[*attribs.flatten]

    return self.journalized_update_attributes attribs
  end

  def position!(params)
    if params.include?('prev')
      if params['prev'].blank?
        self.move_to_top # move after 'prev'. Meaning no prev, we go at top
      else
        self.move_after(self.class.find(params['prev']))
      end
    elsif params.include?('next')
      if params['next'].blank?
        self.move_to_bottom
      else
        self.move_before(self.class.find(params['next']))
      end
    end
  end

  def sprint
    self.fixed_version.becomes(RbSprint) if self.fixed_version
  end

  def points_display(notsized='-')
    format_story_points(story_points, notsized)
  end

  #Alias to get generics into columns
  #def name
  #  subject
  #end

end
