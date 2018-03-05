class IssueStatusesController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin, :except => :index
  before_action :require_admin_or_api_request, :only => :index
  accept_api_auth :index
  def index
    @issue_statuses = IssueStatus.sorted.to_a
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.api
    end
  end
 link_to l(:label_issue_status_new), new_issue_status_path, :class => 'icon icon-add' 
 link_to(l(:label_update_issue_done_ratios), update_issue_done_ratio_issue_statuses_path, :class => 'icon icon-multiple', :method => 'post', :data => {:confirm => l(:text_are_you_sure)}) if Issue.use_status_for_done_ratio? 
l(:label_issue_status_plural)
l(:field_status)
 if Issue.use_status_for_done_ratio? 
l(:field_done_ratio)
 end 
l(:field_is_closed)
 for status in @issue_statuses 
 link_to status.name, edit_issue_status_path(status) 
 if Issue.use_status_for_done_ratio? 
 status.default_done_ratio 
 end 
 checked_image status.is_closed? 
 reorder_handle(status) 
 delete_link issue_status_path(status) 
 end 
 html_title(l(:label_issue_status_plural)) 
 javascript_tag do 
 end 
  def new
    @issue_status = IssueStatus.new
  end
 title [l(:label_issue_status_plural), issue_statuses_path], l(:label_issue_status_new) 
 labelled_form_for @issue_status do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 end 
  def create
    @issue_status = IssueStatus.new
    @issue_status.safe_attributes = params[:issue_status]
    if @issue_status.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to issue_statuses_path
    else
      render :action => 'new'
 title [l(:label_issue_status_plural), issue_statuses_path], l(:label_issue_status_new) 
 labelled_form_for @issue_status do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 end 
    end
  end
  def edit
    @issue_status = IssueStatus.find(params[:id])
  end
 title [l(:label_issue_status_plural), issue_statuses_path], @issue_status.name 
 labelled_form_for @issue_status do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
  def update
    @issue_status = IssueStatus.find(params[:id])
    @issue_status.safe_attributes = params[:issue_status]
    if @issue_status.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to issue_statuses_path(:page => params[:page])
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
 title [l(:label_issue_status_plural), issue_statuses_path], @issue_status.name 
 labelled_form_for @issue_status do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
        format.js { head 422 }
      end
    end
  end
  def destroy
    IssueStatus.find(params[:id]).destroy
    redirect_to issue_statuses_path
  rescue
    flash[:error] = l(:error_unable_delete_issue_status)
    redirect_to issue_statuses_path
  end
  def update_issue_done_ratio
    if request.post? && IssueStatus.update_issue_done_ratios
      flash[:notice] = l(:notice_issue_done_ratios_updated)
    else
      flash[:error] =  l(:error_issue_done_ratios_not_updated)
    end
    redirect_to issue_statuses_path
  end
end
