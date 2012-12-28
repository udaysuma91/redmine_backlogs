Given /^I am viewing the epic backlog$/ do
  visit url_for(:controller => :projects, :action => :show, :id => @project.identifier, :only_path=>true)
  visit url_for(:controller => :rb_master_backlogs, :action => :show, :project_id => @project.identifier, :only_path=>true, :scope=>'epic')
  verify_request_status(200)
end

Given /^I am viewing the epicboard$/ do
  visit url_for(:controller => :projects, :action => :show, :id => @project.identifier, :only_path=>true)
  visit url_for(:controller => :rb_epicboards, :action => :show, :project_id => @project.identifier, :only_path=>true)
  verify_request_status(200)
end

Given /^I want to create an epic$/ do
  @story_params = initialize_epic_params
end

When /^I (try to )?create the epic$/ do |attempt|
  page.driver.post(
                      url_for(:controller => :rb_stories,
                              :action => :create,
                              :only_path => true),
                      @story_params
                  )
  verify_request_status(200) if attempt == ''
end

Given /^I want to edit the epic with subject (.+)$/ do |subject|
  @story = RbEpic.find(:first, :conditions => ["subject=?", subject])
  @story.should_not be_nil
  @story_params = HashWithIndifferentAccess.new(@story.attributes)
end

Then /^the (\d+)(?:st|nd|rd|th) epic in (.+) should be (.+)$/ do |position, backlog, subject|
  sprint = (backlog == 'the product backlog' ? nil : Version.find_by_name(backlog))
  epic = RbEpic.find_by_rank(position.to_i, RbEpic.find_options(:project => @project, :sprint => sprint))

  epic.should_not be_nil
  epic.subject.should == subject
end

Then /^I should see (\d+) epics in the epic backlog$/ do |count|
  page.all(:css, "#product_backlog_container .backlog .story").length.should == count.to_i
end
