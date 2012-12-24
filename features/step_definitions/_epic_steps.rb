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

Then /^the (\d+)(?:st|nd|rd|th) epic in (.+) should be (.+)$/ do |position, backlog, subject|
  sprint = (backlog == 'the product backlog' ? nil : Version.find_by_name(backlog))
  epic = RbEpic.find_by_rank(position.to_i, RbEpic.find_options(:project => @project, :sprint => sprint))

  epic.should_not be_nil
  epic.subject.should == subject
end

