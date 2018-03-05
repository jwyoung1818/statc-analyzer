class MembersController < ApplicationController
  model_object Member
  before_action :find_model_object, :except => [:index, :new, :create, :autocomplete]
  before_action :find_project_from_association, :except => [:index, :new, :create, :autocomplete]
  before_action :find_project_by_project_id, :only => [:index, :new, :create, :autocomplete]
  before_action :authorize
  accept_api_auth :index, :show, :create, :update, :destroy
  require_sudo_mode :create, :update, :destroy
  def index
    scope = @project.memberships
    @offset, @limit = api_offset_and_limit
    @member_count = scope.count
    @member_pages = Paginator.new @member_count, @limit, params['page']
    @offset ||= @member_pages.offset
    @members =  scope.order(:id).limit(@limit).offset(@offset).to_a
    respond_to do |format|
      format.html { head 406 }
      format.api
    end
  end
  def show
    respond_to do |format|
      format.html { head 406 }
      format.api
    end
  end
  def new
    @member = Member.new
  end
 l(:label_member_new) 
 form_for @member, :as => :membership, :url => project_memberships_path(@project), :method => :post do |f| 
 render :partial => 'new_form' 
 submit_tag l(:button_add), :name => nil 
 end 
  def create
    members = []
    if params[:membership]
      user_ids = Array.wrap(params[:membership][:user_id] || params[:membership][:user_ids])
      user_ids << nil if user_ids.empty?
      user_ids.each do |user_id|
        member = Member.new(:project => @project, :user_id => user_id)
        member.set_editable_role_ids(params[:membership][:role_ids])
        members << member
      end
      @project.members << members
    end
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.js {
        @members = members
        @member = Member.new
      }
      format.api {
        @member = members.first
        if @member.valid?
          render :action => 'show', :status => :created, :location => membership_url(@member)
        else
          render_validation_errors(@member)
        end
      }
    end
  end
  def edit
    @roles = Role.givable.to_a
  end
 title "#{@member.principal} - #{@member.project}" 
 render :partial => 'edit' 
 form_for(@member, :url => membership_path(@member),
                      :as => :membership,
                      :remote => request.xhr?,
                      :method => :put) do |f| 
 @roles.each do |role| 
 check_box_tag('membership[role_ids][]',
                        role.id, @member.roles.to_a.include?(role),
                        :id => nil,
                        :disabled => !@member.role_editable?(role)) 
 role 
 end 
 hidden_field_tag 'membership[role_ids][]', '', :id => nil 
 submit_tag l(:button_save), :class => "small" 
 link_to_function l(:button_cancel),
                         "$('#member-#{@member.id}-roles').show(); $('#member-#{@member.id}-form').empty(); return false;" if request.xhr? 
 end 
  def update
    if params[:membership]
      @member.set_editable_role_ids(params[:membership][:role_ids])
    end
    saved = @member.save
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.js
      format.api {
        if saved
          render_api_ok
        else
          render_validation_errors(@member)
        end
      }
    end
  end
  def destroy
    if @member.deletable?
      @member.destroy
    end
    respond_to do |format|
      format.html { redirect_to_settings_in_projects }
      format.js
      format.api {
        if @member.destroyed?
          render_api_ok
        else
          head :unprocessable_entity
        end
      }
    end
  end
  def autocomplete
    respond_to do |format|
      format.js
    end
  end
  private
  def redirect_to_settings_in_projects
    redirect_to settings_project_path(@project, :tab => 'members')
  end
end
