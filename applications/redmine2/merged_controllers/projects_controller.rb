class ProjectsController < ApplicationController
  menu_item :overview
  menu_item :settings, :only => :settings
  menu_item :projects, :only => [:index, :new, :copy, :create]
  before_action :find_project, :except => [ :index, :autocomplete, :list, :new, :create, :copy ]
  before_action :authorize, :except => [ :index, :autocomplete, :list, :new, :create, :copy, :archive, :unarchive, :destroy]
  before_action :authorize_global, :only => [:new, :create]
  before_action :require_admin, :only => [ :copy, :archive, :unarchive, :destroy ]
  accept_rss_auth :index
  accept_api_auth :index, :show, :create, :update, :destroy
  require_sudo_mode :destroy
  helper :custom_fields
  helper :issues
  helper :queries
  helper :repositories
  helper :members
  def index
    if params[:jump] && redirect_to_menu_item(params[:jump])
      return
    end
    scope = Project.visible.sorted
    respond_to do |format|
      format.html {
        unless params[:closed]
          scope = scope.active
        end
        @projects = scope.to_a
      }
      format.api  {
        @offset, @limit = api_offset_and_limit
        @project_count = scope.count
        @projects = scope.offset(@offset).limit(@limit).to_a
      }
      format.atom {
        projects = scope.reorder(:created_on => :desc).limit(Setting.feeds_limit.to_i).to_a
        render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
      }
    end
  end
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:action => 'index', :format => 'atom', :key => User.current.rss_key}) 
 end 
 form_tag({}, :method => :get) do 
 check_box_tag 'closed', 1, params[:closed], :onchange => "this.form.submit();" 
 l(:label_show_closed_projects) 
 end 
 render_project_action_links 
 l(:label_project_plural) 
 render_project_hierarchy(@projects) 
 if User.current.logged? 
 l(:label_my_projects) 
 end 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:key => User.current.rss_key} 
 end 
 html_title(l(:label_project_plural)) 
  def autocomplete
    respond_to do |format|
      format.js {
        if params[:q].present?
          @projects = Project.visible.like(params[:q]).to_a
        else
          @projects = User.current.projects.to_a
        end
      }
    end
  end
  def new
    @issue_custom_fields = IssueCustomField.sorted.to_a
    @trackers = Tracker.sorted.to_a
    @project = Project.new
    @project.safe_attributes = params[:project]
  end
 title l(:label_project_new) 
 labelled_form_for @project, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 submit_tag l(:button_create_and_continue), :name => 'continue' 
 end 
  def create
    @issue_custom_fields = IssueCustomField.sorted.to_a
    @trackers = Tracker.sorted.to_a
    @project = Project.new
    @project.safe_attributes = params[:project]
    if @project.save
      unless User.current.admin?
        @project.add_default_member(User.current)
      end
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          if params[:continue]
            attrs = {:parent_id => @project.parent_id}.reject {|k,v| v.nil?}
            redirect_to new_project_path(attrs)
          else
            redirect_to settings_project_path(@project)
          end
        }
        format.api  { render :action => 'show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id) }
 if User.current.allowed_to?(:add_subprojects, @project) 
 link_to l(:label_subproject_new), new_project_path(:parent_id => @project), :class => 'icon icon-add' 
 end 
 if User.current.allowed_to?(:close_project, @project) 
 if @project.active? 
 link_to l(:button_close), close_project_path(@project), :data => {:confirm => l(:text_are_you_sure)}, :method => :post, :class => 'icon icon-lock' 
 else 
 link_to l(:button_reopen), reopen_project_path(@project), :data => {:confirm => l(:text_are_you_sure)}, :method => :post, :class => 'icon icon-unlock' 
 end 
 end 
l(:label_overview)
 unless @project.active? 
 l(:text_project_closed) 
 end 
 if @project.description.present? 
 textilizable @project.description 
 end 
 if @project.homepage.present? || @project.visible_custom_field_values.any?(&:present?) 
 unless @project.homepage.blank? 
l(:field_homepage)
 link_to_if uri_with_safe_scheme?(@project.homepage), @project.homepage, @project.homepage 
 end 
 render_custom_field_values(@project) do |custom_field, formatted| 
 custom_field.name 
 formatted 
 end 
 end 
 if User.current.allowed_to?(:view_issues, @project) 
l(:label_issue_tracking)
 if @trackers.present? 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 @trackers.each do |tracker| 
 link_to tracker.name, project_issues_path(@project, :set_filter => 1, :tracker_id => tracker.id) 
 link_to @open_issues_by_tracker[tracker].to_i, project_issues_path(@project, :set_filter => 1, :tracker_id => tracker.id) 
 link_to (@total_issues_by_tracker[tracker].to_i - @open_issues_by_tracker[tracker].to_i), project_issues_path(@project, :set_filter => 1, :tracker_id => tracker.id, :status_id => 'c') 
 link_to @total_issues_by_tracker[tracker].to_i, project_issues_path(@project, :set_filter => 1, :tracker_id => tracker.id, :status_id => '*') 
 end 
 end 
 link_to l(:label_issue_view_all), project_issues_path(@project, :set_filter => 1) 
 if User.current.allowed_to?(:view_calendar, @project, :global => true) 
 link_to l(:label_calendar), project_calendar_path(@project) 
 end 
 if User.current.allowed_to?(:view_gantt, @project, :global => true) 
 link_to l(:label_gantt), project_gantt_path(@project) 
 end 
 end 
 if User.current.allowed_to?(:view_time_entries, @project) 
 l(:label_spent_time) 
 if @total_hours.present? 
 l_hours(@total_hours) 
 end 
 if User.current.allowed_to?(:log_time, @project) 
 link_to l(:button_log_time), new_project_time_entry_path(@project) 
 end 
 link_to(l(:label_details), project_time_entries_path(@project)) 
 link_to(l(:label_report), report_project_time_entries_path(@project)) 
 end 
 call_hook(:view_projects_show_left, :project => @project) 
 render :partial => 'members_box' 
 if @users_by_role.any? 
l(:label_member_plural)
 @users_by_role.keys.sort.each do |role| 
 role 
 @users_by_role[role].sort.collect{|u| link_to_user u}.join(", ").html_safe 
 end 
 end 
 if @news.any? && authorize_for('news', 'index') 
l(:label_news_latest)
 render :partial => 'news/news', :collection => @news 
 link_to_project(news.project) + ': ' unless @project 
 link_to news.title, news_path(news) 
 if news.comments_count > 0 
 l(:label_x_comments, :count => news.comments_count) 
 end 
 unless news.summary.blank? 
 news.summary 
 end 
 authoring news.created_on, news.author 
 link_to l(:label_news_view_all), project_news_index_path(@project) 
 end 
 if @subprojects.any? 
l(:label_subproject_plural)
 @subprojects.collect{|p| link_to p, project_path(p), :class => p.css_classes}.join(", ").html_safe 
 end 
 call_hook(:view_projects_show_right, :project => @project) 
 content_for :sidebar do 
 call_hook(:view_projects_show_sidebar_bottom, :project => @project) 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:controller => 'activities', :action => 'index', :id => @project, :format => 'atom', :key => User.current.rss_key}) 
 end 
 html_title(l(:label_overview)) 
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
 title l(:label_project_new) 
 labelled_form_for @project, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 submit_tag l(:button_create_and_continue), :name => 'continue' 
 end 
        format.api  { render_validation_errors(@project) }
      end
    end
  end
  def copy
    @issue_custom_fields = IssueCustomField.sorted.to_a
    @trackers = Tracker.sorted.to_a
    @source_project = Project.find(params[:id])
    if request.get?
      @project = Project.copy_from(@source_project)
      @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
    else
      Mailer.with_deliveries(params[:notifications] == '1') do
        @project = Project.new
        @project.safe_attributes = params[:project]
        if @project.copy(@source_project, :only => params[:only])
          flash[:notice] = l(:notice_successful_create)
          redirect_to settings_project_path(@project)
        elsif !@project.new_record?
          redirect_to settings_project_path(@project)
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
l(:label_project_new)
 labelled_form_for @project, :url => { :action => "copy" } do |f| 
 render :partial => 'form', :locals => { :f => f } 
 l(:button_copy) 
 check_box_tag 'only[]', 'members', true, :id => nil 
 l(:label_member_plural) 
 @source_project.members.count 
 check_box_tag 'only[]', 'versions', true, :id => nil 
 l(:label_version_plural) 
 @source_project.versions.count 
 check_box_tag 'only[]', 'issue_categories', true, :id => nil 
 l(:label_issue_category_plural) 
 @source_project.issue_categories.count 
 check_box_tag 'only[]', 'issues', true, :id => nil 
 l(:label_issue_plural) 
 @source_project.issues.count 
 check_box_tag 'only[]', 'queries', true, :id => nil 
 l(:label_query_plural) 
 @source_project.queries.count 
 check_box_tag 'only[]', 'boards', true, :id => nil 
 l(:label_board_plural) 
 @source_project.boards.count 
 check_box_tag 'only[]', 'wiki', true, :id => nil 
 l(:label_wiki_page_plural) 
 @source_project.wiki.nil? ? 0 : @source_project.wiki.pages.count 
 hidden_field_tag 'only[]', '' 
 check_box_tag 'notifications', 1, params[:notifications] 
 l(:label_project_copy_notifications) 
 @project.tracker_ids.each do |tracker_id| 
 hidden_field_tag 'project[tracker_ids][]', tracker_id 
 end 
 @project.issue_custom_field_ids.each do |issue_custom_field_id| 
 hidden_field_tag 'project[issue_custom_field_ids][]', issue_custom_field_id 
 end 
 submit_tag l(:button_copy) 
 end 
  def show
    if params[:jump] && redirect_to_project_menu_item(@project, params[:jump])
      return
    end
    @users_by_role = @project.users_by_role
    @subprojects = @project.children.visible.to_a
    @news = @project.news.limit(5).includes(:author, :project).reorder("#{News.table_name}.created_on DESC").to_a
    @trackers = @project.rolled_up_trackers.visible
    cond = @project.project_condition(Setting.display_subprojects_issues?)
    @open_issues_by_tracker = Issue.visible.open.where(cond).group(:tracker).count
    @total_issues_by_tracker = Issue.visible.where(cond).group(:tracker).count
    if User.current.allowed_to_view_all_time_entries?(@project)
      @total_hours = TimeEntry.visible.where(cond).sum(:hours).to_f
    end
    @key = User.current.rss_key
    respond_to do |format|
      format.html
      format.api
    end
  end
 if User.current.allowed_to?(:add_subprojects, @project) 
 link_to l(:label_subproject_new), new_project_path(:parent_id => @project), :class => 'icon icon-add' 
 end 
 if User.current.allowed_to?(:close_project, @project) 
 if @project.active? 
 link_to l(:button_close), close_project_path(@project), :data => {:confirm => l(:text_are_you_sure)}, :method => :post, :class => 'icon icon-lock' 
 else 
 link_to l(:button_reopen), reopen_project_path(@project), :data => {:confirm => l(:text_are_you_sure)}, :method => :post, :class => 'icon icon-unlock' 
 end 
 end 
l(:label_overview)
 unless @project.active? 
 l(:text_project_closed) 
 end 
 if @project.description.present? 
 textilizable @project.description 
 end 
 if @project.homepage.present? || @project.visible_custom_field_values.any?(&:present?) 
 unless @project.homepage.blank? 
l(:field_homepage)
 link_to_if uri_with_safe_scheme?(@project.homepage), @project.homepage, @project.homepage 
 end 
 render_custom_field_values(@project) do |custom_field, formatted| 
 custom_field.name 
 formatted 
 end 
 end 
 if User.current.allowed_to?(:view_issues, @project) 
l(:label_issue_tracking)
 if @trackers.present? 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 @trackers.each do |tracker| 
 link_to tracker.name, project_issues_path(@project, :set_filter => 1, :tracker_id => tracker.id) 
 link_to @open_issues_by_tracker[tracker].to_i, project_issues_path(@project, :set_filter => 1, :tracker_id => tracker.id) 
 link_to (@total_issues_by_tracker[tracker].to_i - @open_issues_by_tracker[tracker].to_i), project_issues_path(@project, :set_filter => 1, :tracker_id => tracker.id, :status_id => 'c') 
 link_to @total_issues_by_tracker[tracker].to_i, project_issues_path(@project, :set_filter => 1, :tracker_id => tracker.id, :status_id => '*') 
 end 
 end 
 link_to l(:label_issue_view_all), project_issues_path(@project, :set_filter => 1) 
 if User.current.allowed_to?(:view_calendar, @project, :global => true) 
 link_to l(:label_calendar), project_calendar_path(@project) 
 end 
 if User.current.allowed_to?(:view_gantt, @project, :global => true) 
 link_to l(:label_gantt), project_gantt_path(@project) 
 end 
 end 
 if User.current.allowed_to?(:view_time_entries, @project) 
 l(:label_spent_time) 
 if @total_hours.present? 
 l_hours(@total_hours) 
 end 
 if User.current.allowed_to?(:log_time, @project) 
 link_to l(:button_log_time), new_project_time_entry_path(@project) 
 end 
 link_to(l(:label_details), project_time_entries_path(@project)) 
 link_to(l(:label_report), report_project_time_entries_path(@project)) 
 end 
 call_hook(:view_projects_show_left, :project => @project) 
 render :partial => 'members_box' 
 if @users_by_role.any? 
l(:label_member_plural)
 @users_by_role.keys.sort.each do |role| 
 role 
 @users_by_role[role].sort.collect{|u| link_to_user u}.join(", ").html_safe 
 end 
 end 
 if @news.any? && authorize_for('news', 'index') 
l(:label_news_latest)
 render :partial => 'news/news', :collection => @news 
 link_to_project(news.project) + ': ' unless @project 
 link_to news.title, news_path(news) 
 if news.comments_count > 0 
 l(:label_x_comments, :count => news.comments_count) 
 end 
 unless news.summary.blank? 
 news.summary 
 end 
 authoring news.created_on, news.author 
 link_to l(:label_news_view_all), project_news_index_path(@project) 
 end 
 if @subprojects.any? 
l(:label_subproject_plural)
 @subprojects.collect{|p| link_to p, project_path(p), :class => p.css_classes}.join(", ").html_safe 
 end 
 call_hook(:view_projects_show_right, :project => @project) 
 content_for :sidebar do 
 call_hook(:view_projects_show_sidebar_bottom, :project => @project) 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:controller => 'activities', :action => 'index', :id => @project, :format => 'atom', :key => User.current.rss_key}) 
 end 
 html_title(l(:label_overview)) 
  def settings
    @issue_custom_fields = IssueCustomField.sorted.to_a
    @issue_category ||= IssueCategory.new
    @member ||= @project.members.new
    @trackers = Tracker.sorted.to_a
    @version_status = params[:version_status] || 'open'
    @version_name = params[:version_name]
    @versions = @project.shared_versions.status(@version_status).like(@version_name)
  end
l(:label_settings)
 render_tabs project_settings_tabs 
 html_title(l(:label_settings)) 
  def edit
  end
  def update
    @project.safe_attributes = params[:project]
    if @project.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to settings_project_path(@project, params[:tab])
        }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html {
          settings
          render :action => 'settings'
l(:label_settings)
 render_tabs project_settings_tabs 
 html_title(l(:label_settings)) 
        }
        format.api  { render_validation_errors(@project) }
      end
    end
  end
  def archive
    unless @project.archive
      flash[:error] = l(:error_can_not_archive_project)
    end
    redirect_to_referer_or admin_projects_path(:status => params[:status])
  end
  def unarchive
    unless @project.active?
      @project.unarchive
    end
    redirect_to_referer_or admin_projects_path(:status => params[:status])
  end
  def close
    @project.close
    redirect_to project_path(@project)
  end
  def reopen
    @project.reopen
    redirect_to project_path(@project)
  end
  def destroy
    @project_to_destroy = @project
    if api_request? || params[:confirm]
      @project_to_destroy.destroy
      respond_to do |format|
        format.html { redirect_to admin_projects_path }
        format.api  { render_api_ok }
      end
    end
    @project = nil
  end
 title l(:label_confirmation) 
 form_tag(project_path(@project_to_destroy), :method => :delete) do 
h @project_to_destroy 
l(:text_project_destroy_confirmation)
 if @project_to_destroy.descendants.any? 
 l(:text_subprojects_destroy_warning,
          content_tag('strong', @project_to_destroy.descendants.collect{|p| p.to_s}.join(', '))).html_safe 
 end 
 check_box_tag 'confirm', 1 
 l(:general_text_Yes) 
 submit_tag l(:button_delete) 
 link_to l(:button_cancel), :controller => 'admin', :action => 'projects' 
 end 
end
