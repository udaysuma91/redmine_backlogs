include RbCommonHelper
include RbGenericboardsHelper

class RbGenericboardsAdminController < ApplicationController
  unloadable

  before_filter :find_rb_genericboard, :except => [:index, :new, :create]
  before_filter :authorize_global

  def index
    @rb_genericboards = RbGenericboard.order(:name)
  end

  def new
    @rb_genericboard = RbGenericboard.new
  end

  def create
    @rb_genericboard = RbGenericboard.new
    @rb_genericboard.safe_attributes = params[:rb_genericboard]
    respond_to do |format|
      if @rb_genericboard.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ? new_rb_genericboard_path : rb_genericboards_path)
        }
      else
        format.html { render :action => "new" }
      end
    end

  end

  def edit
  end

  def update
    @rb_genericboard.safe_attributes = params[:rb_genericboard]

    respond_to do |format|
      if @rb_genericboard.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to(rb_genericboards_path) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @rb_genericboard.destroy

    respond_to do |format|
      format.html { redirect_to(rb_genericboards_path) }
    end
  end

  def find_rb_genericboard
    @rb_genericboard = RbGenericboard.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
