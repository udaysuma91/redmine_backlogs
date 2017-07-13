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
  before_action :find_issue, :authorize, :only => [:index, :create, :new]
  before_action :find_release, :only => [:show, :update, :destroy]

  def index
    # should not be hit
  end

  def create
    # create a new relation with a release
    @IssueRelease = RbIssueRelease.new
    @IssueRelease.safe_attributes = params[:issue_release]
    @IssueRelease.init_journals(User.current)
    saved = @IssueRelease.save

    respond_to do |format|
      format.html { redirect_to issue_path(@issue) }
      format.js {
        @Releases = @issue.reload.releases.select {|ir| ir.issue(@issue) && ir.issue(@issue).visible? }
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
  
  private
  
  def find_issue
    @issue = Issue.find(params[:issue_release][:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_relation
    @relation = IssueRelation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end