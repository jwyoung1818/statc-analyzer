class UsersController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin, :except => :show
  before_action ->{ find_user(false) }, :only => :show
  before_action :find_user, :only => [:edit, :update, :destroy]
  accept_api_auth :index, :show, :create, :update, :destroy
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :principal_memberships
  helper :activities
  include ActivitiesHelper
  require_sudo_mode :create, :update, :destroy
  def index
    sort_init 'login', 'asc'
    sort_update %w(login firstname lastname admin created_on last_login_on)
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end
    @status = params[:status] || 1
    scope = User.logged.status(@status).preload(:email_address)
    scope = scope.like(params[:name]) if params[:name].present?
    scope = scope.in_group(params[:group_id]) if params[:group_id].present?
    @user_count = scope.count
    @user_pages = Paginator.new @user_count, @limit, params['page']
    @offset ||= @user_pages.offset
    @users =  scope.order(sort_clause).limit(@limit).offset(@offset).to_a
    respond_to do |format|
      format.html {
        @groups = Group.givable.sort
        render :layout => !request.xhr?
      }
      format.api
    end
  end
 link_to l(:label_user_new), new_user_path, :class => 'icon icon-add' 
l(:label_user_plural)
 form_tag(users_path, :method => :get) do 
 l(:label_filter_plural) 
 l(:field_status) 
 select_tag 'status', users_status_options_for_select(@status), :class => "small", :onchange => "this.form.submit(); return false;"  
 if @groups.present? 
 l(:label_group) 
 select_tag 'group_id', content_tag('option') + options_from_collection_for_select(@groups, :id, :name, params[:group_id].to_i), :onchange => "this.form.submit(); return false;"  
 end 
 l(:label_user) 
 text_field_tag 'name', params[:name], :size => 30 
 submit_tag l(:button_apply), :class => "small", :name => nil 
 link_to l(:button_clear), users_path, :class => 'icon icon-reload' 
 end 
 if @users.any? 
 sort_header_tag('login', :caption => l(:field_login)) 
 sort_header_tag('firstname', :caption => l(:field_firstname)) 
 sort_header_tag('lastname', :caption => l(:field_lastname)) 
 l(:field_mail) 
 sort_header_tag('admin', :caption => l(:field_admin), :default_order => 'desc') 
 sort_header_tag('created_on', :caption => l(:field_created_on), :default_order => 'desc') 
 sort_header_tag('last_login_on', :caption => l(:field_last_login_on), :default_order => 'desc') 
 for user in @users 
 user.css_classes 
 avatar(user, :size => "14") 
 link_to user.login, edit_user_path(user) 
 user.firstname 
 user.lastname 
 mail_to(user.mail) 
 checked_image user.admin? 
 format_time(user.created_on) 
 format_time(user.last_login_on) unless user.last_login_on.nil? 
 change_status_link(user) 
 delete_link user_path(user, :back_url => request.original_fullpath) unless User.current == user 
 end 
 pagination_links_full @user_pages, @user_count 
 else 
 l(:label_no_data) 
 end 
 html_title(l(:label_user_plural)) 
  def show
    unless @user.visible?
      render_404
      return
    end
    @memberships = @user.memberships.preload(:roles, :project).where(Project.visible_condition(User.current)).to_a
    respond_to do |format|
      format.html {
        events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
        @events_by_day = events.group_by {|event| User.current.time_to_date(event.event_datetime)}
        render :layout => 'base'
 current_language 
 html_title 
 Redmine::Info.app_name 
 csrf_meta_tag 
 favicon 
 stylesheet_link_tag 'jquery/jquery-ui-1.11.0', 'application', 'responsive', :media => 'all' 
 stylesheet_link_tag 'rtl', :media => 'all' if l(:direction) == 'rtl' 
 javascript_heads 
 heads_for_theme 
 call_hook :view_layouts_base_html_head 
 yield :header_tags 
 body_css_classes 
 call_hook :view_layouts_base_body_top 
 if User.current.logged? || !Setting.login_required? 
 form_tag({:controller => 'search', :action => 'index', :id => @project}, :method => :get ) do 
 hidden_field_tag(controller.default_search_scope, 1, :id => nil) if controller.default_search_scope 
 label_tag 'flyout-search', '&#9906;'.html_safe, :class => 'search-magnifier search-magnifier--flyout' 
 text_field_tag 'q', @question, :id => 'flyout-search', :class => 'small js-search-input', :placeholder => l(:label_search) 
 end 
 end 
 if User.current.logged? 
 if !Setting.gravatar_enabled? 
 end 
 if Setting.gravatar_enabled? 
 link_to(avatar(User.current, :size => "80"), user_path(User.current)) 
 end 
 link_to_user(User.current, :format => :username) 
 end 
 if display_main_menu?(@project) 
 l(:label_project) 
 end 
 l(:label_general) 
 l(:label_profile) 
 render_menu :account_menu 
 content_tag('div', "#{l(:label_logged_as)} #{link_to_user(User.current, :format => :username)}".html_safe, :id => 'loggedas') if User.current.logged? 
 render_menu :top_menu if User.current.logged? || !Setting.login_required? 
 if User.current.logged? || !Setting.login_required? 
 form_tag({:controller => 'search', :action => 'index', :id => @project}, :method => :get ) do 
 hidden_field_tag 'scope', default_search_project_scope, :id => nil 
 hidden_field_tag(controller.default_search_scope, 1, :id => nil) if controller.default_search_scope 
 link_to l(:label_search), {:controller => 'search', :action => 'index', :id => @project}, :accesskey => accesskey(:search) 
 text_field_tag 'q', @question, :size => 20, :class => 'small', :accesskey => accesskey(:quick_search) 
 end 
 render_project_jump_box 
 end 
 page_header_title 
 if display_main_menu?(@project) 
 render_main_menu(@project) 
 end 
 sidebar_content? ? '' : 'nosidebar' 
 yield :sidebar 
 view_layouts_base_sidebar_hook_response 
 render_flash_messages 
 yield 
 call_hook :view_layouts_base_content 
 l(:label_loading) 
 link_to Redmine::Info.app_name, Redmine::Info.url 
 call_hook :view_layouts_base_body_bottom 
      }
      format.api
    end
  end
  def new
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
    @user.safe_attributes = params[:user]
    @auth_sources = AuthSource.all
  end
 title [l(:label_user_plural), users_path], l(:label_user_new) 
 labelled_form_for @user, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 if email_delivery_enabled? 
 check_box_tag 'send_information', 1, params[:send_information] 
 l(:label_send_information) 
 end 
 submit_tag l(:button_create) 
 submit_tag l(:button_create_and_continue), :name => 'continue' 
 end 
 if @auth_sources.present? && @auth_sources.any?(&:searchable?) 
 javascript_tag do 
 escape_javascript autocomplete_for_new_user_auth_sources_path 
 end 
 end 
  def create
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option, :admin => false)
    @user.safe_attributes = params[:user]
    @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] unless @user.auth_source_id
    @user.pref.safe_attributes = params[:pref]
    if @user.save
      Mailer.account_information(@user, @user.password).deliver if params[:send_information]
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_user_successful_create, :id => view_context.link_to(@user.login, user_path(@user)))
          if params[:continue]
            attrs = {:generate_password => @user.generate_password }
            redirect_to new_user_path(:user => attrs)
          else
            redirect_to edit_user_path(@user)
          end
        }
        format.api  { render :action => 'show', :status => :created, :location => user_url(@user) }
 link_to(l(:button_edit), edit_user_path(@user), :class => 'icon icon-edit') if User.current.admin? && @user.logged? 
 avatar @user, :size => "50" 
 @user.name 
 if User.current.admin? 
l(:field_login)
 @user.login 
 end 
 unless @user.pref.hide_mail 
l(:field_mail)
 mail_to(@user.mail, nil, :encode => 'javascript') 
 end 
 @user.visible_custom_field_values.each do |custom_value| 
 if !custom_value.value.blank? 
 custom_value.custom_field.name 
 show_value(custom_value) 
 end 
 end 
l(:label_registered_on)
 format_date(@user.created_on) 
 unless @user.last_login_on.nil? 
l(:field_last_login_on)
 format_date(@user.last_login_on) 
 end 
l(:label_issue_plural)
 link_to l(:label_assigned_issues),
        issues_path(:set_filter => 1, :assigned_to_id => ([@user.id] + @user.group_ids).join("|"), :sort => 'priority:desc,updated_on:desc') 
 Issue.visible.open.assigned_to(@user).count 
 link_to l(:label_reported_issues),
        issues_path(:set_filter => 1, :status_id => '*', :author_id => @user.id) 
 Issue.visible.where(:author_id => @user.id).count 
 unless @memberships.empty? 
l(:label_project_plural)
 for membership in @memberships 
 link_to_project(membership.project) 
 membership.roles.sort.collect(&:to_s).join(', ') 
 format_date(membership.created_on) 
 end 
 end 
 call_hook :view_account_left_bottom, :user => @user 
 unless @events_by_day.empty? 
 link_to l(:label_activity), :controller => 'activities',
                :action => 'index', :id => nil, :user_id => @user,
                :from => @events_by_day.keys.first 
 @events_by_day.keys.sort.reverse_each do |day| 
 format_activity_day(day) 
 sort_activity_events(@events_by_day[day]).each do |e, in_group| 
 e.event_type 
 e.event_type 
 "grouped" if in_group 
 User.current.logged? && e.respond_to?(:event_author) && User.current == e.event_author ? 'me' : nil 
 format_time(e.event_datetime, false) 
 content_tag('span', e.project, :class => 'project') 
 link_to format_activity_title(e.event_title), e.event_url 
 "grouped" if in_group 
 format_activity_description(e.event_description) 
 end 
 end 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:controller => 'activities', :action => 'index', :id => nil, :user_id => @user, :key => User.current.rss_key} 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, :controller => 'activities', :action => 'index', :user_id => @user, :format => :atom, :key => User.current.rss_key) 
 end 
 end 
 call_hook :view_account_right_bottom, :user => @user 
 html_title @user.name 
      end
    else
      @auth_sources = AuthSource.all
      @user.password = @user.password_confirmation = nil
      respond_to do |format|
        format.html { render :action => 'new' }
 title [l(:label_user_plural), users_path], l(:label_user_new) 
 labelled_form_for @user, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 if email_delivery_enabled? 
 check_box_tag 'send_information', 1, params[:send_information] 
 l(:label_send_information) 
 end 
 submit_tag l(:button_create) 
 submit_tag l(:button_create_and_continue), :name => 'continue' 
 end 
 if @auth_sources.present? && @auth_sources.any?(&:searchable?) 
 javascript_tag do 
 escape_javascript autocomplete_for_new_user_auth_sources_path 
 end 
 end 
        format.api  { render_validation_errors(@user) }
      end
    end
  end
  def edit
    @auth_sources = AuthSource.all
    @membership ||= Member.new
  end
 link_to l(:label_profile), user_path(@user), :class => 'icon icon-user' 
 additional_emails_link(@user) 
 change_status_link(@user) 
 delete_link user_path(@user) if User.current != @user 
 title [l(:label_user_plural), users_path], @user.login 
 render_tabs user_settings_tabs 
  def update
    if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
      @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
    end
    @user.safe_attributes = params[:user]
    was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
    @user.pref.safe_attributes = params[:pref]
    if @user.save
      @user.pref.save
      if was_activated
        Mailer.account_activated(@user).deliver
      elsif @user.active? && params[:send_information] && @user != User.current
        Mailer.account_information(@user, @user.password).deliver
      end
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to_referer_or edit_user_path(@user)
        }
        format.api  { render_api_ok }
      end
    else
      @auth_sources = AuthSource.all
      @membership ||= Member.new
      @user.password = @user.password_confirmation = nil
      respond_to do |format|
        format.html { render :action => :edit }
 link_to l(:label_profile), user_path(@user), :class => 'icon icon-user' 
 additional_emails_link(@user) 
 change_status_link(@user) 
 delete_link user_path(@user) if User.current != @user 
 title [l(:label_user_plural), users_path], @user.login 
 render_tabs user_settings_tabs 
        format.api  { render_validation_errors(@user) }
      end
    end
  end
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_back_or_default(users_path) }
      format.api  { render_api_ok }
    end
  end
  private
  def find_user(logged = true)
    if params[:id] == 'current'
      require_login || return
      @user = User.current
    elsif logged
      @user = User.logged.find(params[:id])
    else
      @user = User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
