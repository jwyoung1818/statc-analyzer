class VersionsController < ApplicationController
  menu_item :roadmap
  model_object Version
  before_action :find_model_object, :except => [:index, :new, :create, :close_completed]
  before_action :find_project_from_association, :except => [:index, :new, :create, :close_completed]
  before_action :find_project_by_project_id, :only => [:index, :new, :create, :close_completed]
  before_action :authorize
  accept_api_auth :index, :show, :create, :update, :destroy
  helper :custom_fields
  helper :projects
  def index
    respond_to do |format|
      format.html {
        @trackers = @project.trackers.sorted.to_a
        retrieve_selected_tracker_ids(@trackers, @trackers.select {|t| t.is_in_roadmap?})
        @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
        project_ids = @with_subprojects ? @project.self_and_descendants.collect(&:id) : [@project.id]
        @versions = @project.shared_versions.preload(:custom_values)
        @versions += @project.rolled_up_versions.visible.preload(:custom_values) if @with_subprojects
        @versions = @versions.to_a.uniq.sort
        unless params[:completed]
          @completed_versions = @versions.select(&:completed?).reverse
          @versions -= @completed_versions
        end
        @issues_by_version = {}
        if @selected_tracker_ids.any? && @versions.any?
          issues = Issue.visible.
            includes(:project, :tracker).
            preload(:status, :priority, :fixed_version).
            where(:tracker_id => @selected_tracker_ids, :project_id => project_ids, :fixed_version_id => @versions.map(&:id)).
            order("#{Project.table_name}.lft, #{Tracker.table_name}.position, #{Issue.table_name}.id")
          @issues_by_version = issues.group_by(&:fixed_version)
        end
        @versions.reject! {|version| !project_ids.include?(version.project_id) && @issues_by_version[version].blank?}
      }
      format.api {
        @versions = @project.shared_versions.to_a
      }
    end
  end
 link_to(l(:label_version_new), new_project_version_path(@project),
              :class => 'icon icon-add') if User.current.allowed_to?(:manage_versions, @project) 
l(:label_roadmap)
 if @versions.empty? 
 l(:label_no_data) 
 else 
 @versions.each do |version| 
 version.css_classes 
 if User.current.allowed_to?(:manage_versions, version.project) 
 link_to l(:button_edit), edit_version_path(version), :title => l(:button_edit), :class => 'icon-only icon-edit' 
 end 
 link_to_version version, :name => version_anchor(version) 
 render :partial => 'versions/overview', :locals => {:version => version} 
 if version.completed? 
 format_date(version.effective_date) 
 elsif version.effective_date 
 due_date_distance_in_words(version.effective_date) 
 format_date(version.effective_date) 
 end 
h version.description 
 if version.custom_field_values.any? 
 render_custom_field_values(version) do |custom_field, formatted| 
 custom_field.name 
 formatted 
 end 
 end 
 if version.visible_fixed_issues.count > 0 
 progress_bar([version.visible_fixed_issues.closed_percent, version.visible_fixed_issues.completed_percent],
                     :titles =>
                       ["%s: %0.0f%%" % [l(:label_closed_issues_plural), version.visible_fixed_issues.closed_percent],
                        "%s: %0.0f%%" % [l(:field_done_ratio), version.visible_fixed_issues.completed_percent]],
                     :legend => ('%0.0f%%' % version.visible_fixed_issues.completed_percent)) 
 link_to(l(:label_x_issues, :count => version.visible_fixed_issues.count),
                  version_filtered_issues_path(version, :status_id => '*')) 
 link_to_if(version.visible_fixed_issues.closed_count > 0,
                      l(:label_x_closed_issues_abbr, :count => version.visible_fixed_issues.closed_count),
                      version_filtered_issues_path(version, :status_id => 'c')) 
 link_to_if(version.visible_fixed_issues.open_count > 0,
                     l(:label_x_open_issues_abbr, :count => version.visible_fixed_issues.open_count),
                     version_filtered_issues_path(version, :status_id => 'o')) 
 else 
 l(:label_roadmap_no_issues) 
 end 
 render(:partial => "wiki/content",
               :locals => {:content => version.wiki_page.content}) if version.wiki_page 
 if (issues = @issues_by_version[version]) && issues.size > 0 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 l(:label_related_issues) 
 issues.each do |issue| 
 check_box_tag 'ids[]', issue.id, false, :id => nil 
 link_to_issue(issue, :project => (@project != issue.project)) 
 end 
 end 
 end 
 call_hook :view_projects_roadmap_version_bottom, :version => version 
 end 
 end 
 content_for :sidebar do 
 form_tag({}, :method => :get) do 
 l(:label_roadmap) 
 @trackers.each do |tracker| 
 check_box_tag("tracker_ids[]", tracker.id,
                        (@selected_tracker_ids.include? tracker.id.to_s),
                        :id => nil) 
 tracker.name 
 end 
 check_box_tag "completed", 1, params[:completed] 
 l(:label_show_completed_versions) 
 if @project.descendants.active.any? 
 hidden_field_tag 'with_subprojects', 0, :id => nil 
 check_box_tag 'with_subprojects', 1, @with_subprojects 
l(:label_subproject_plural)
 end 
 submit_tag l(:button_apply), :class => 'button-small', :name => nil 
 end 
 l(:label_version_plural) 
 @versions.each do |version| 
 link_to(format_version_name(version), "##{version_anchor(version)}") 
 end 
 if @completed_versions.present? 
 link_to_function l(:label_completed_versions),
                       '$("#toggle-completed-versions").toggleClass("collapsed"); $("#completed-versions").toggle()',
                       :id => 'toggle-completed-versions', :class => 'collapsible collapsed' 
 @completed_versions.each do |version| 
 link_to_version version 
 end 
 end 
 end 
 html_title(l(:label_roadmap)) 
 context_menu 
  def show
    respond_to do |format|
      format.html {
        @issues = @version.fixed_issues.visible.
          includes(:status, :tracker, :priority).
          preload(:project).
          reorder("#{Tracker.table_name}.position, #{Issue.table_name}.id").
          to_a
      }
      format.api
    end
  end
 link_to(l(:button_edit), edit_version_path(@version), :class => 'icon icon-edit') if User.current.allowed_to?(:manage_versions, @version.project) 
 link_to_if_authorized(l(:button_edit_associated_wikipage, :page_title => @version.wiki_page_title), {:controller => 'wiki', :action => 'edit', :project_id => @version.project, :id => Wiki.titleize(@version.wiki_page_title)}, :class => 'icon icon-edit') unless @version.wiki_page_title.blank? || @version.project.wiki.nil? 
 delete_link version_path(@version, :back_url => url_for(:controller => 'versions', :action => 'index', :project_id => @version.project)) if User.current.allowed_to?(:manage_versions, @version.project) 
 call_hook(:view_versions_show_contextual, { :version => @version, :project => @project }) 
 @version.name 
 @version.css_classes 
 render :partial => 'versions/overview', :locals => {:version => @version} 
 if version.completed? 
 format_date(version.effective_date) 
 elsif version.effective_date 
 due_date_distance_in_words(version.effective_date) 
 format_date(version.effective_date) 
 end 
h version.description 
 if version.custom_field_values.any? 
 render_custom_field_values(version) do |custom_field, formatted| 
 custom_field.name 
 formatted 
 end 
 end 
 if version.visible_fixed_issues.count > 0 
 progress_bar([version.visible_fixed_issues.closed_percent, version.visible_fixed_issues.completed_percent],
                     :titles =>
                       ["%s: %0.0f%%" % [l(:label_closed_issues_plural), version.visible_fixed_issues.closed_percent],
                        "%s: %0.0f%%" % [l(:field_done_ratio), version.visible_fixed_issues.completed_percent]],
                     :legend => ('%0.0f%%' % version.visible_fixed_issues.completed_percent)) 
 link_to(l(:label_x_issues, :count => version.visible_fixed_issues.count),
                  version_filtered_issues_path(version, :status_id => '*')) 
 link_to_if(version.visible_fixed_issues.closed_count > 0,
                      l(:label_x_closed_issues_abbr, :count => version.visible_fixed_issues.closed_count),
                      version_filtered_issues_path(version, :status_id => 'c')) 
 link_to_if(version.visible_fixed_issues.open_count > 0,
                     l(:label_x_open_issues_abbr, :count => version.visible_fixed_issues.open_count),
                     version_filtered_issues_path(version, :status_id => 'o')) 
 else 
 l(:label_roadmap_no_issues) 
 end 
 render(:partial => "wiki/content", :locals => {:content => @version.wiki_page.content}) if @version.wiki_page 
 if @version.visible_fixed_issues.estimated_hours > 0 || User.current.allowed_to?(:view_time_entries, @project) 
 l(:label_time_tracking) 
 l(:field_estimated_hours) 
 link_to html_hours(l_hours(@version.visible_fixed_issues.estimated_hours)),
                                        project_issues_path(@version.project, :set_filter => 1, :status_id => '*', :fixed_version_id => @version.id, :c => [:tracker, :status, :subject, :estimated_hours], :t => [:estimated_hours]) 
 if User.current.allowed_to_view_all_time_entries?(@project) 
 l(:label_spent_time) 
 link_to html_hours(l_hours(@version.spent_hours)),
                                        project_time_entries_path(@version.project, :set_filter => 1, :"issue.fixed_version_id" => @version.id) 
 end 
 end 
 render_issue_status_by(@version, params[:status_by]) if @version.fixed_issues.exists? 
 if @issues.present? 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 l(:label_related_issues) 
 @issues.each do |issue| 
 check_box_tag 'ids[]', issue.id, false, :id => nil 
 link_to_issue(issue, :project => (@project != issue.project)) 
 end 
 end 
 context_menu 
 end 
 call_hook :view_versions_show_bottom, :version => @version 
 html_title @version.name 
  def new
    @version = @project.versions.build
    @version.safe_attributes = params[:version]
    respond_to do |format|
      format.html
      format.js
    end
  end
l(:label_version_new)
 labelled_form_for @version, :url => project_versions_path(@project), :html => {:multipart => true} do |f| 
 render :partial => 'versions/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 end 
  def create
    @version = @project.versions.build
    if params[:version]
      attributes = params[:version].dup
      attributes.delete('sharing') unless attributes.nil? || @version.allowed_sharings.include?(attributes['sharing'])
      @version.safe_attributes = attributes
    end
    if request.post?
      if @version.save
        respond_to do |format|
          format.html do
            flash[:notice] = l(:notice_successful_create)
            redirect_back_or_default settings_project_path(@project, :tab => 'versions')
          end
          format.js
          format.api do
            render :action => 'show', :status => :created, :location => version_url(@version)
 link_to(l(:button_edit), edit_version_path(@version), :class => 'icon icon-edit') if User.current.allowed_to?(:manage_versions, @version.project) 
 link_to_if_authorized(l(:button_edit_associated_wikipage, :page_title => @version.wiki_page_title), {:controller => 'wiki', :action => 'edit', :project_id => @version.project, :id => Wiki.titleize(@version.wiki_page_title)}, :class => 'icon icon-edit') unless @version.wiki_page_title.blank? || @version.project.wiki.nil? 
 delete_link version_path(@version, :back_url => url_for(:controller => 'versions', :action => 'index', :project_id => @version.project)) if User.current.allowed_to?(:manage_versions, @version.project) 
 call_hook(:view_versions_show_contextual, { :version => @version, :project => @project }) 
 @version.name 
 @version.css_classes 
 render :partial => 'versions/overview', :locals => {:version => @version} 
 if version.completed? 
 format_date(version.effective_date) 
 elsif version.effective_date 
 due_date_distance_in_words(version.effective_date) 
 format_date(version.effective_date) 
 end 
h version.description 
 if version.custom_field_values.any? 
 render_custom_field_values(version) do |custom_field, formatted| 
 custom_field.name 
 formatted 
 end 
 end 
 if version.visible_fixed_issues.count > 0 
 progress_bar([version.visible_fixed_issues.closed_percent, version.visible_fixed_issues.completed_percent],
                     :titles =>
                       ["%s: %0.0f%%" % [l(:label_closed_issues_plural), version.visible_fixed_issues.closed_percent],
                        "%s: %0.0f%%" % [l(:field_done_ratio), version.visible_fixed_issues.completed_percent]],
                     :legend => ('%0.0f%%' % version.visible_fixed_issues.completed_percent)) 
 link_to(l(:label_x_issues, :count => version.visible_fixed_issues.count),
                  version_filtered_issues_path(version, :status_id => '*')) 
 link_to_if(version.visible_fixed_issues.closed_count > 0,
                      l(:label_x_closed_issues_abbr, :count => version.visible_fixed_issues.closed_count),
                      version_filtered_issues_path(version, :status_id => 'c')) 
 link_to_if(version.visible_fixed_issues.open_count > 0,
                     l(:label_x_open_issues_abbr, :count => version.visible_fixed_issues.open_count),
                     version_filtered_issues_path(version, :status_id => 'o')) 
 else 
 l(:label_roadmap_no_issues) 
 end 
 render(:partial => "wiki/content", :locals => {:content => @version.wiki_page.content}) if @version.wiki_page 
 if @version.visible_fixed_issues.estimated_hours > 0 || User.current.allowed_to?(:view_time_entries, @project) 
 l(:label_time_tracking) 
 l(:field_estimated_hours) 
 link_to html_hours(l_hours(@version.visible_fixed_issues.estimated_hours)),
                                        project_issues_path(@version.project, :set_filter => 1, :status_id => '*', :fixed_version_id => @version.id, :c => [:tracker, :status, :subject, :estimated_hours], :t => [:estimated_hours]) 
 if User.current.allowed_to_view_all_time_entries?(@project) 
 l(:label_spent_time) 
 link_to html_hours(l_hours(@version.spent_hours)),
                                        project_time_entries_path(@version.project, :set_filter => 1, :"issue.fixed_version_id" => @version.id) 
 end 
 end 
 render_issue_status_by(@version, params[:status_by]) if @version.fixed_issues.exists? 
 if @issues.present? 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 l(:label_related_issues) 
 @issues.each do |issue| 
 check_box_tag 'ids[]', issue.id, false, :id => nil 
 link_to_issue(issue, :project => (@project != issue.project)) 
 end 
 end 
 context_menu 
 end 
 call_hook :view_versions_show_bottom, :version => @version 
 html_title @version.name 
          end
        end
      else
        respond_to do |format|
          format.html { render :action => 'new' }
l(:label_version_new)
 labelled_form_for @version, :url => project_versions_path(@project), :html => {:multipart => true} do |f| 
 render :partial => 'versions/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 end 
          format.js   { render :action => 'new' }
l(:label_version_new)
 labelled_form_for @version, :url => project_versions_path(@project), :html => {:multipart => true} do |f| 
 render :partial => 'versions/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 end 
          format.api  { render_validation_errors(@version) }
        end
      end
    end
  end
  def edit
  end
l(:label_version)
 labelled_form_for @version, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 end 
  def update
    if params[:version]
      attributes = params[:version].dup
      attributes.delete('sharing') unless @version.allowed_sharings.include?(attributes['sharing'])
      @version.safe_attributes = attributes
      if @version.save
        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_successful_update)
            redirect_back_or_default settings_project_path(@project, :tab => 'versions')
          }
          format.api  { render_api_ok }
        end
      else
        respond_to do |format|
          format.html { render :action => 'edit' }
l(:label_version)
 labelled_form_for @version, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 end 
          format.api  { render_validation_errors(@version) }
        end
      end
    end
  end
  def close_completed
    if request.put?
      @project.close_completed_versions
    end
    redirect_to settings_project_path(@project, :tab => 'versions')
  end
  def destroy
    if @version.deletable?
      @version.destroy
      respond_to do |format|
        format.html { redirect_back_or_default settings_project_path(@project, :tab => 'versions') }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html {
          flash[:error] = l(:notice_unable_delete_version)
          redirect_to settings_project_path(@project, :tab => 'versions')
        }
        format.api  { head :unprocessable_entity }
      end
    end
  end
  def status_by
    respond_to do |format|
      format.html { render :action => 'show' }
 link_to(l(:button_edit), edit_version_path(@version), :class => 'icon icon-edit') if User.current.allowed_to?(:manage_versions, @version.project) 
 link_to_if_authorized(l(:button_edit_associated_wikipage, :page_title => @version.wiki_page_title), {:controller => 'wiki', :action => 'edit', :project_id => @version.project, :id => Wiki.titleize(@version.wiki_page_title)}, :class => 'icon icon-edit') unless @version.wiki_page_title.blank? || @version.project.wiki.nil? 
 delete_link version_path(@version, :back_url => url_for(:controller => 'versions', :action => 'index', :project_id => @version.project)) if User.current.allowed_to?(:manage_versions, @version.project) 
 call_hook(:view_versions_show_contextual, { :version => @version, :project => @project }) 
 @version.name 
 @version.css_classes 
 render :partial => 'versions/overview', :locals => {:version => @version} 
 if version.completed? 
 format_date(version.effective_date) 
 elsif version.effective_date 
 due_date_distance_in_words(version.effective_date) 
 format_date(version.effective_date) 
 end 
h version.description 
 if version.custom_field_values.any? 
 render_custom_field_values(version) do |custom_field, formatted| 
 custom_field.name 
 formatted 
 end 
 end 
 if version.visible_fixed_issues.count > 0 
 progress_bar([version.visible_fixed_issues.closed_percent, version.visible_fixed_issues.completed_percent],
                     :titles =>
                       ["%s: %0.0f%%" % [l(:label_closed_issues_plural), version.visible_fixed_issues.closed_percent],
                        "%s: %0.0f%%" % [l(:field_done_ratio), version.visible_fixed_issues.completed_percent]],
                     :legend => ('%0.0f%%' % version.visible_fixed_issues.completed_percent)) 
 link_to(l(:label_x_issues, :count => version.visible_fixed_issues.count),
                  version_filtered_issues_path(version, :status_id => '*')) 
 link_to_if(version.visible_fixed_issues.closed_count > 0,
                      l(:label_x_closed_issues_abbr, :count => version.visible_fixed_issues.closed_count),
                      version_filtered_issues_path(version, :status_id => 'c')) 
 link_to_if(version.visible_fixed_issues.open_count > 0,
                     l(:label_x_open_issues_abbr, :count => version.visible_fixed_issues.open_count),
                     version_filtered_issues_path(version, :status_id => 'o')) 
 else 
 l(:label_roadmap_no_issues) 
 end 
 render(:partial => "wiki/content", :locals => {:content => @version.wiki_page.content}) if @version.wiki_page 
 if @version.visible_fixed_issues.estimated_hours > 0 || User.current.allowed_to?(:view_time_entries, @project) 
 l(:label_time_tracking) 
 l(:field_estimated_hours) 
 link_to html_hours(l_hours(@version.visible_fixed_issues.estimated_hours)),
                                        project_issues_path(@version.project, :set_filter => 1, :status_id => '*', :fixed_version_id => @version.id, :c => [:tracker, :status, :subject, :estimated_hours], :t => [:estimated_hours]) 
 if User.current.allowed_to_view_all_time_entries?(@project) 
 l(:label_spent_time) 
 link_to html_hours(l_hours(@version.spent_hours)),
                                        project_time_entries_path(@version.project, :set_filter => 1, :"issue.fixed_version_id" => @version.id) 
 end 
 end 
 render_issue_status_by(@version, params[:status_by]) if @version.fixed_issues.exists? 
 if @issues.present? 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 l(:label_related_issues) 
 @issues.each do |issue| 
 check_box_tag 'ids[]', issue.id, false, :id => nil 
 link_to_issue(issue, :project => (@project != issue.project)) 
 end 
 end 
 context_menu 
 end 
 call_hook :view_versions_show_bottom, :version => @version 
 html_title @version.name 
      format.js
    end
  end
  private
  def retrieve_selected_tracker_ids(selectable_trackers, default_trackers=nil)
    if ids = params[:tracker_ids]
      @selected_tracker_ids = (ids.is_a? Array) ? ids.collect { |id| id.to_i.to_s } : ids.split('/').collect { |id| id.to_i.to_s }
    else
      @selected_tracker_ids = (default_trackers || selectable_trackers).collect {|t| t.id.to_s }
    end
  end
end
