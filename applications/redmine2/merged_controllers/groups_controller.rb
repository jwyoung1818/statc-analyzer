class GroupsController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin
  before_action :find_group, :except => [:index, :new, :create]
  accept_api_auth :index, :show, :create, :update, :destroy, :add_users, :remove_user
  require_sudo_mode :add_users, :remove_user, :create, :update, :destroy, :edit_membership, :destroy_membership
  helper :custom_fields
  helper :principal_memberships
  def index
    respond_to do |format|
      format.html {
        scope = Group.sorted
        scope = scope.like(params[:name]) if params[:name].present?
        @group_count = scope.count
        @group_pages = Paginator.new @group_count, per_page_option, params['page']
        @groups = scope.limit(@group_pages.per_page).offset(@group_pages.offset).to_a
        @user_count_by_group_id = user_count_by_group_id
      }
      format.api {
        scope = Group.sorted
        scope = scope.givable unless params[:builtin] == '1'
        @groups = scope.to_a
      }
    end
  end
 link_to l(:label_group_new), new_group_path, :class => 'icon icon-add' 
 title l(:label_group_plural) 
 form_tag(groups_path, :method => :get) do 
 l(:label_filter_plural) 
 l(:label_group) 
 text_field_tag 'name', params[:name], :size => 30 
 submit_tag l(:button_apply), :class => "small", :name => nil 
 link_to l(:button_clear), groups_path, :class => 'icon icon-reload' 
 end 
 if @groups.any? 
l(:label_group)
l(:label_user_plural)
 @groups.each do |group| 
 group.id 
 "builtin" if group.builtin? 
 link_to group, edit_group_path(group) 
 (@user_count_by_group_id[group.id] || 0) unless group.builtin? 
 delete_link group unless group.builtin? 
 end 
 pagination_links_full @group_pages, @group_count 
 else 
 l(:label_no_data) 
 end 
  def show
    respond_to do |format|
      format.html
      format.api
    end
  end
 title [l(:label_group_plural), groups_path], @group.name 
 @group.users.each do |user| 
 user 
 end 
  def new
    @group = Group.new
  end
 title [l(:label_group_plural), groups_path], l(:label_group_new) 
 labelled_form_for @group, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 f.submit l(:button_create) 
 f.submit l(:button_create_and_continue), :name => 'continue' 
 end 
  def create
    @group = Group.new
    @group.safe_attributes = params[:group]
    respond_to do |format|
      if @group.save
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ? new_group_path : groups_path)
        }
        format.api  { render :action => 'show', :status => :created, :location => group_url(@group) }
 title [l(:label_group_plural), groups_path], @group.name 
 @group.users.each do |user| 
 user 
 end 
      else
        format.html { render :action => "new" }
 title [l(:label_group_plural), groups_path], l(:label_group_new) 
 labelled_form_for @group, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 f.submit l(:button_create) 
 f.submit l(:button_create_and_continue), :name => 'continue' 
 end 
        format.api  { render_validation_errors(@group) }
      end
    end
  end
  def edit
  end
 title [l(:label_group_plural), groups_path], @group.name 
 render_tabs group_settings_tabs(@group) 
  def update
    @group.safe_attributes = params[:group]
    respond_to do |format|
      if @group.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to_referer_or(groups_path) }
        format.api  { render_api_ok }
      else
        format.html { render :action => "edit" }
 title [l(:label_group_plural), groups_path], @group.name 
 render_tabs group_settings_tabs(@group) 
        format.api  { render_validation_errors(@group) }
      end
    end
  end
  def destroy
    @group.destroy
    respond_to do |format|
      format.html { redirect_to_referer_or(groups_path) }
      format.api  { render_api_ok }
    end
  end
  def new_users
  end
 l(:label_user_new) 
 form_for(@group, :url => group_users_path(@group), :method => :post) do |f| 
 render :partial => 'new_users_form' 
 submit_tag l(:button_add) 
 end 
  def add_users
    @users = User.not_in_group(@group).where(:id => (params[:user_id] || params[:user_ids])).to_a
    @group.users << @users
    respond_to do |format|
      format.html { redirect_to edit_group_path(@group, :tab => 'users') }
      format.js
      format.api {
        if @users.any?
          render_api_ok
        else
          render_api_errors "#{l(:label_user)} #{l('activerecord.errors.messages.invalid')}"
        end
      }
    end
  end
  def remove_user
    @group.users.delete(User.find(params[:user_id])) if request.delete?
    respond_to do |format|
      format.html { redirect_to edit_group_path(@group, :tab => 'users') }
      format.js
      format.api { render_api_ok }
    end
  end
  def autocomplete_for_user
    respond_to do |format|
      format.js
    end
  end
  private
  def find_group
    @group = Group.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def user_count_by_group_id
    h = User.joins(:groups).group('group_id').count
    h.keys.each do |key|
      h[key.to_i] = h.delete(key)
    end
    h
  end
end
