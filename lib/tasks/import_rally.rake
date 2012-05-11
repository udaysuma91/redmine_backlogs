require 'xmlsimple'
require 'date'

#Usage: RAILS_ENV=production rake redmine:backlogs:import_rally project='EP-src' epic_tracker=Epic XMLFILE=~/Stories.xml author=paat ITERATIONSXML=~/Iterations.xml RELEASESXML=~/Releases.xml
class Converter
  attr_accessor :releases, :iterations, :stories
  
  def initialize(project, tracker)
    @releases = {}
    @iterations = {}
    @stories = {}
    @parents = {}
    @positions = {}

    @project = project
    @tracker = tracker
    @epictracker = nil

    @author = User.find(:first, :conditions => ['login=?', ENV['author']])
    raise "Could not find Author #{@author}" unless @author
  end

  def create_objects
    status = IssueStatus.find(:first, :conditions => ['name=?','Accepted'])
    unless status
      status = IssueStatus.new(:name => 'Accepted', :default_done_ratio => 100)
      status.save!
    end

    epictracker = Tracker.find(:first, :conditions => ["name=?", ENV['epic_tracker']])
    if !epictracker
      puts "Creating task tracker '#{ENV['epic_tracker']}'"
      epictracker = Tracker.new(:name => ENV['epic_tracker'])
      epictracker.save!
    end
    @epictracker = epictracker

    @parents.each{|key, name|
        if ! IssueCategory.find(:first, :conditions => {'name' => name, "project_id"=>@project.id})
          puts "Adding category #{name}"
          cat = IssueCategory.new(:name => name, :project => @project)
          cat.save!
          puts "#{cat}"
        end
    }
    @releases.each{|key, name|
      if ! RbSprint.find(:first, :conditions => {"name"=> name, "project_id"=>@project.id})
        puts "Creating version #{name} at #{@project}"
        sprint = RbSprint.new( :name => name , :project => @project)
        sprint.save!
      end
    }
    @iterations.each{|key, name|
      if ! RbSprint.find(:first, :conditions => {"name"=> name, "project_id"=>@project.id})
        puts "Creating version #{name} at #{@project}"
        sprint = RbSprint.new( :name => name , :project => @project)
        sprint.save!
      end
    }

    sortedpositions = @positions.keys().sort()
    start = RbStory.find(:first, :order => 'position desc').position
    i = 1
    sortedpositions.each{|pos|
      ref = @positions[pos]
      @stories[ref]['position'] = start + i
      i += 1
    }

    @stories.each{|ref, story|
      subject = story['subject']
      if subject.length > 255
        story['description'] = subject+"\n\n"+story['description']
        subject=story['subject'][0,253]
      end

      obj = RbStory.find(:first, :conditions => {"subject"=> subject, "project_id"=>@project.id})
      if !obj
        puts "Creating Story #{subject} #{story['position']}"
        obj = RbStory.new(:project => @project, :subject => subject, :tracker => @tracker, :author => @author)
      else
        puts "Updating Story #{subject} #{story['position']}"
      end
      obj.story_points = story['story_points']
      obj.position = story['position']
      obj.description = story['description'].gsub(/\<br(.*?)>/, "\n")
      obj.priority = IssuePriority.named(story['priority']).first
      obj.status = IssueStatus.find(:first, :conditions => ['name=?',story['status']])

      version = nil
      if story['version']
        version = @iterations[story['version']]
      else
        if story['release']
          version = @releases[story['release']]
        end
      end
      if version
        obj.fixed_version_id = RbSprint.find(:first, :conditions => {"name"=> version, "project_id"=>@project.id}).id
      end

      category = IssueCategory.find(:first, :conditions => {'name' => story['category'], "project_id"=>@project.id}) if story['category']
      obj.category = category if category

      puts "#{obj}"
      begin
        obj.save!
      rescue
      end
      story['obj'] = obj
    }

#    if @epictracker
#      @parents.each{|key, name|
#        parent = @stories[key]['obj']
#        if parent
#          parent.tracker = @epictracker
#          parent.save!
#          puts "Set tracker to #{@epictracker} for #{parent}"
#        else
#          puts "Parent #{key} not found"
#        end
#        
#      }
#      @stories.each{|ref, story|
#          obj = story['obj']
#          parent = @stories[story['parent']]
#          obj.parent_issue_id = parent.id if parent
#          obj.save!
#          puts "Set parent to #{parent} for #{obj}" if parent
#      }
#    end
  end

  def process(data)
    data['HierarchicalRequirement'].each{|hreq|
      process_story(hreq)
    }
    #puts "Iterations found: #{@iterations}"
    #puts "Releases found: #{@releases}"
    #puts "Categories found: #{@parents}"

    create_objects
  end

  def calc_prio(functional, dysfunctional)
    # 0 like - wouldnt mind
    # 1 expect - wouldnt mind
    # 2 like - annoy
    # 3 expect - annoy

    prio = 0
    #puts "#{functional} #{dysfunctional}"
    if 'expect' == "#{functional}"
      prio = 1
    end
    if 'annoy' == "#{dysfunctional}"
      prio += 2
    end
    case prio
    when 0
      prio = 'Low'
    when 1
      prio = 'Normal'
    when 2
      prio = 'High'
    when 3
      prio = 'Urgent'
    else
      prio = 'Low'
    end
    prio
  end

  def calc_state(state)
    #In-Progress
    #Defined
    #Accepted
    #Completed
    case "#{state}"
    when "Defined"
      rbstate = 'New'
    when "In-Progress"
      rbstate = 'In Work'
    when "Completed"
      rbstate = 'Done'
    when "Accepted"
      rbstate = 'Accepted'
    else
      rbstate = 'New'
    end
    rbstate
  end

  def process_story(story, level=0)
      #puts level, story['refObjectName']
      #puts "  level #{level}"
      #puts "  ref #{story['ref']}"
      #puts "  Id #{story['FormattedID']}"
      #puts "  Name #{story['Name']}"
      #puts "  Est #{story['PlanEstimate']}"
      #puts "  Rank #{story['Rank']}"
      #puts "  Dysfunc #{story['Dysfunctional']}"
      #puts "  Func #{story['Functional']}"
      #puts "  State #{story['ScheduleState']}"
      if story['Release']
        #puts "  Rel #{story['Release'][0]['refObjectName']}"
        #puts "  Rel #{story['Release'][0]['ref']}"
        @releases[story['Release'][0]['ref']] = story['Release'][0]['refObjectName']
        release = story['Release'][0]['ref']
      else
        release = nil
      end
      if story['Iteration']
        #puts "  Sprint #{story['Iteration'][0]['refObjectName']}"
        #puts "  Sprint #{story['Iteration'][0]['ref']}"
        @iterations[story['Iteration'][0]['ref']] = story['Iteration'][0]['refObjectName']
        version = story['Iteration'][0]['ref']
      else
        version = nil
      end

      parentname = nil
      if story['Parent']
        #puts "  Parent #{story['Parent'][0]['refObjectName']}"
        #puts "  Parent #{story['Parent'][0]['ref']}"
        parent = story['Parent'][0]['ref']
        name = story['Parent'][0]['refObjectName']
        epicname = name
        name = name[0,29] if name.length > 30
        @parents[parent] = name
      end
      description = "#{story['Description']}" +
        "\n\nif functional #{story['Functional']}\n" +
        "if dysfunctional #{story['Dysfunctional']}\n\n"
      story_points = 0
      story_points = story['PlanEstimate'][0].to_f if story['PlanEstimate']
      @positions[story['Rank'][0].to_f.to_i] = story['ref']
      @stories[story['ref']] = {
          'ref' => story['ref'],
          'subject' => "#{story['FormattedID']} #{story['Name']}",
          'description' => description,
          'story_points' => story_points,
          'priority' => calc_prio(story['Functional'], story['Dysfunctional']),
          'status' => calc_state(story['ScheduleState']),
          'version' => version,
          'release' => release,
          'category' => parentname,
          'parent' => parent
      }
      #p @stories[story['ref']]
      if story['Children']
        story['Children'].each{|child|
          #p child
          if child and child['HierarchicalRequirement']
            child['HierarchicalRequirement'].each{|subhreq|
              has_children=true
              process_story(subhreq, level+1)
            }
          end
        }
      end
  end

  def process_iterations(data)
      object = nil
      objects = data['Iteration'] if data['Iteration']
      objects = data['Release'] if data['Release']
      unless objects
        return
      end

      objects.each{|iteration|
          name = iteration['Name']
          startdate = iteration['StartDate']
          enddate = iteration['EndDate']
          startdate = iteration['ReleaseStartDate'] if iteration['ReleaseStartDate']
          enddate = iteration['ReleaseDate'] if iteration['ReleaseDate']
          subject = iteration['Theme']
          state = iteration['State']
          sprint = RbSprint.find(:first, :conditions => {"name"=> name, "project_id"=>@project.id})

          if sprint:
            puts "#{sprint} #{sprint.start_date} #{sprint.due_date}"
            #sprint.start_date = startdate
            sprint.sprint_start_date = Date.parse(startdate[0])
            sprint.due_date = Date.parse(enddate[0])
            puts "#{sprint} #{sprint.start_date} #{sprint.due_date}"
            sprint.save!
          else
            puts "Sprint not found: #{name}"
          end
      }
  end
end

namespace :redmine do
  namespace :backlogs do

    desc "Import Stories from Rally"
    task :import_rally => :environment do
      raise "Please specify XMLFILE environment" unless ENV['XMLFILE']

      trackers = Tracker.find(:all)
      trackers.each{|name|
        puts "#{name.name}"
      }
      tracker = Tracker.find(:first, :conditions => ["name=?", "Story"])
      raise "Please provide a tracker '#{name}' in your database'" unless tracker

      raise "Please provide a user with the author environment variable" unless ENV['author']

      Project.find(:all).each{|project| puts "#{project.name}" }
      project = Project.find(:first, :conditions => ["name=?", "#{ENV['project']}"])
      if ! project
        raise "Please provide a project using the 'project' environment variable"
      end

      puts "Importing #{ENV['XMLFILE']}"
      converter = Converter.new(project, tracker)
      data = XmlSimple.xml_in(ENV['XMLFILE'], {'KeyAttr' => 'name', 'SuppressEmpty' => nil, 'ForceArray' => true})
      converter.process(data)
      converter.process_iterations( XmlSimple.xml_in(ENV['ITERATIONSXML'], {'KeyAttr' => 'name', 'SuppressEmpty' => nil, 'ForceArray' => true})) if ENV['ITERATIONSXML']
      converter.process_iterations( XmlSimple.xml_in(ENV['RELEASESXML'], {'KeyAttr' => 'name', 'SuppressEmpty' => nil, 'ForceArray' => true})) if ENV['RELEASESXML']
    end
  end
end
