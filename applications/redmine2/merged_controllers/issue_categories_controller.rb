class IssueCategoriesController < ApplicationController
  menu_item :settings
  model_object IssueCategory
  before_action :find_model_object, :except => [:index, :new, :create]
  before_action :find_project_from_association, :except => [:index, :new, :create]
  before_action :find_project_by_project_id, :only => [:index, :new, :create]
  before_action :authorize
  accept_api_auth :index, :show, :create, :update, :destroy
  def index
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.api { @categories = @project.issue_categories.to_a }
    end
  end
  def show
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.api
    end
  end
  def new
    @category = @project.issue_categories.build
    @category.safe_attributes = params[:issue_category]
    respond_to do |format|
      format.html
      format.js
    end
  end
l(:label_issue_category_new)
 labelled_form_for @category, :as => :issue_category,
                      :url => project_issue_categories_path(@project) do |f| 
 render :partial => 'issue_categories/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 end 
  def create
    @category = @project.issue_categories.build
    @category.safe_attributes = params[:issue_category]
    if @category.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to_settings_in_projects
        end
        format.js
        format.api { render :action => 'show', :status => :created, :location => issue_category_path(@category) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new'}
l(:label_issue_category_new)
 labelled_form_for @category, :as => :issue_category,
                      :url => project_issue_categories_path(@project) do |f| 
 render :partial => 'issue_categories/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 end 
        format.js   { render :action => 'new'}
l(:label_issue_category_new)
 labelled_form_for @category, :as => :issue_category,
                      :url => project_issue_categories_path(@project) do |f| 
 render :partial => 'issue_categories/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 end 
        format.api { render_validation_errors(@category) }
      end
    end
  end
  def edit
  end
l(:label_issue_category)
 labelled_form_for @category, :as => :issue_category,
                     :url => issue_category_path(@category), :html => {:method => :put} do |f| 
 render :partial => 'issue_categories/form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 end 
  def update
    @category.safe_attributes = params[:issue_category]
    if @category.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to_settings_in_projects
        }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
l(:label_issue_category)
 labelled_form_for @category, :as => :issue_category,
                     :url => issue_category_path(@category), :html => {:method => :put} do |f| 
 render :partial => 'issue_categories/form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 end 
        format.api { render_validation_errors(@category) }
      end
    end
  end
  def destroy
    @issue_count = @category.issues.size
    if @issue_count == 0 || params[:todo] || api_request?
      reassign_to = nil
      if params[:reassign_to_id] && (params[:todo] == 'reassign' || params[:todo].blank?)
        reassign_to = @project.issue_categories.find_by_id(params[:reassign_to_id])
      end
      @category.destroy(reassign_to)
      respond_to do |format|
        format.html { redirect_to_settings_in_projects }
        format.api { render_api_ok }
      end
      return
    end
    @categories = @project.issue_categories - [@category]
  end
l(:label_issue_category)
h @category.name 
 form_tag(issue_category_path(@category), :method => :delete) do 
 l(:text_issue_category_destroy_question, @issue_count) 
 radio_button_tag 'todo', 'nullify', true 
 l(:text_issue_category_destroy_assignments) 
 if @categories.size > 0 
 radio_button_tag 'todo', 'reassign', false 
 l(:text_issue_category_reassign_to) 
 label_tag "reassign_to_id", l(:description_issue_category_reassign), :class => "hidden-for-sighted" 
 select_tag 'reassign_to_id', options_from_collection_for_select(@categories, 'id', 'name') 
 end 
 submit_tag l(:button_apply) 
 link_to l(:button_cancel), :controller => 'projects', :action => 'settings', :id => @project, :tab => 'categories' 
 end 
  private
  def redirect_to_settings_in_projects
    redirect_to settings_project_path(@project, :tab => 'categories')
  end
  def find_model_object
    super
    @category = @object
  end
end
