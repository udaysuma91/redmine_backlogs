include RbCommonHelper

#                rb_issue_release_index GET                /rb/issue_release(.:format)                                                       rb_issue_release#index
#                                       POST               /rb/issue_release(.:format)                                                       rb_issue_release#create
#                  new_rb_issue_release GET                /rb/issue_release/new(.:format)                                                   rb_issue_release#new
#                 edit_rb_issue_release GET                /rb/issue_release/:id/edit(.:format)                                              rb_issue_release#edit
#                      rb_issue_release GET                /rb/issue_release/:id(.:format)                                                   rb_issue_release#show
#                                       PATCH              /rb/issue_release/:id(.:format)                                                   rb_issue_release#update
#                                       PUT                /rb/issue_release/:id(.:format)                                                   rb_issue_release#update
#                                       DELETE             /rb/issue_release/:id(.:format)                                                   rb_issue_release#destroy


# Responsible for exposing issue-release CRUD. It SHOULD NOT be used
# for display
class RbIssueReleaseController < RbApplicationController

  def index
    # should not be hit
  end

  def create
    # create a new relation with a release
    @IssueRelease = RbIssueRelease.new
#    @relation.issue = @issue
    @IssueRelease.safe_attributes = params[:issue_release]
    @IssueRelease.init_journals(User.current)
    saved = @IssueRelease.save

    respond_to do |format|
      format.html { redirect_to issue_path(@issue) }
      format.js {
        @IssueReleases = @issue.reload.issue_releases.select {|ir| ir.issue(@issue) && ir.issue(@issue).visible? }
      }
    end
  end
  
  def new
    @issue_release = RbIssueRelease.new
    # should not be hit
  end
  
  def edit
    # should not be hit
  end
  
  def show
    # should not be hit
  end
  
  def update
    # update the relation to the release
  end
  
  def destroy
    # delete the relation to the release
  end
  
end