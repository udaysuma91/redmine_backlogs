include RbCommonHelper
include RbFormHelper
include ProjectsHelper

class RbReleasePlanningsController < ApplicationController

  before_filter :load_project
  
  def new
    if @project.release_planning.present?
      redirect_to edit_release_planing_rb_path(:id => @project.release_planning.id, :project_id => @project)
    else
      @release_planning = RbReleasePlanning.new
    end
  end

  def create
    @release_planning = RbReleasePlanning.new(release_planning_params)
    @release_planning.project_id = @project.id
    if @release_planning.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to releases_path_rb_path(project_id: @project)
    else
      render action: :new
    end
  end

  def edit
    @release_planning = RbReleasePlanning.find(params[:id])
  end

  def update
   @release_planning = RbReleasePlanning.find(params[:id])
   if @release_planning.update(release_planning_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to releases_path_rb_path(project_id: @project)
    else
      render action: :edit
    end
  end
  
  private

  def load_project
    @project = Project.find(params[:project_id])
  end
    
  def release_planning_params
    params.require(:release_planning).permit(:name, :description, :project_id)
  end
end
