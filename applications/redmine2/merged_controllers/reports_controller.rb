class ReportsController < ApplicationController
  menu_item :issues
  before_action :find_project, :authorize, :find_issue_statuses
  def issue_report
    @trackers = @project.rolled_up_trackers(false).visible
    @versions = @project.shared_versions.sort
    @priorities = IssuePriority.all.reverse
    @categories = @project.issue_categories
    @assignees = (Setting.issue_group_assignment? ? @project.principals : @project.users).sort
    @authors = @project.users.sort
    @subprojects = @project.descendants.visible
    @issues_by_tracker = Issue.by_tracker(@project)
    @issues_by_version = Issue.by_version(@project)
    @issues_by_priority = Issue.by_priority(@project)
    @issues_by_category = Issue.by_category(@project)
    @issues_by_assigned_to = Issue.by_assigned_to(@project)
    @issues_by_author = Issue.by_author(@project)
    @issues_by_subproject = Issue.by_subproject(@project) || []
    render :template => "reports/issue_report"
l(:label_report_plural)
l(:field_tracker)
 link_to l(:label_details),
        project_issues_report_details_path(@project, :detail => 'tracker'),
        :class => 'icon-only icon-zoom-in',
        :title => l(:label_details) 
 render :partial => 'simple', :locals => { :data => @issues_by_tracker, :field_name => "tracker_id", :rows => @trackers } 
 if @statuses.empty? or rows.empty? 
l(:label_no_data)
 else 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 for row in rows 
 link_to row.name, aggregate_path(@project, field_name, row) 
 aggregate_link data, { field_name => row.id, "closed" => 0 }, aggregate_path(@project, field_name, row, :status_id => "o") 
 aggregate_link data, { field_name => row.id, "closed" => 1 }, aggregate_path(@project, field_name, row, :status_id => "c") 
 aggregate_link data, { field_name => row.id }, aggregate_path(@project, field_name, row, :status_id => "*") 
 end 
 end 
l(:field_priority)
 link_to l(:label_details),
        project_issues_report_details_path(@project, :detail => 'priority'),
        :class => 'icon-only icon-zoom-in',
        :title => l(:label_details) 
 render :partial => 'simple', :locals => { :data => @issues_by_priority, :field_name => "priority_id", :rows => @priorities } 
 if @statuses.empty? or rows.empty? 
l(:label_no_data)
 else 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 for row in rows 
 link_to row.name, aggregate_path(@project, field_name, row) 
 aggregate_link data, { field_name => row.id, "closed" => 0 }, aggregate_path(@project, field_name, row, :status_id => "o") 
 aggregate_link data, { field_name => row.id, "closed" => 1 }, aggregate_path(@project, field_name, row, :status_id => "c") 
 aggregate_link data, { field_name => row.id }, aggregate_path(@project, field_name, row, :status_id => "*") 
 end 
 end 
l(:field_assigned_to)
 link_to l(:label_details),
        project_issues_report_details_path(@project, :detail => 'assigned_to'),
        :class => 'icon-only icon-zoom-in',
        :title => l(:label_details) 
 render :partial => 'simple', :locals => { :data => @issues_by_assigned_to, :field_name => "assigned_to_id", :rows => @assignees } 
 if @statuses.empty? or rows.empty? 
l(:label_no_data)
 else 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 for row in rows 
 link_to row.name, aggregate_path(@project, field_name, row) 
 aggregate_link data, { field_name => row.id, "closed" => 0 }, aggregate_path(@project, field_name, row, :status_id => "o") 
 aggregate_link data, { field_name => row.id, "closed" => 1 }, aggregate_path(@project, field_name, row, :status_id => "c") 
 aggregate_link data, { field_name => row.id }, aggregate_path(@project, field_name, row, :status_id => "*") 
 end 
 end 
l(:field_author)
 link_to l(:label_details),
        project_issues_report_details_path(@project, :detail => 'author'),
        :class => 'icon-only icon-zoom-in',
        :title => l(:label_details) 
 render :partial => 'simple', :locals => { :data => @issues_by_author, :field_name => "author_id", :rows => @authors } 
 if @statuses.empty? or rows.empty? 
l(:label_no_data)
 else 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 for row in rows 
 link_to row.name, aggregate_path(@project, field_name, row) 
 aggregate_link data, { field_name => row.id, "closed" => 0 }, aggregate_path(@project, field_name, row, :status_id => "o") 
 aggregate_link data, { field_name => row.id, "closed" => 1 }, aggregate_path(@project, field_name, row, :status_id => "c") 
 aggregate_link data, { field_name => row.id }, aggregate_path(@project, field_name, row, :status_id => "*") 
 end 
 end 
 call_hook(:view_reports_issue_report_split_content_left, :project => @project) 
l(:field_version)
 link_to l(:label_details),
        project_issues_report_details_path(@project, :detail => 'version'),
        :class => 'icon-only icon-zoom-in',
        :title => l(:label_details) 
 render :partial => 'simple', :locals => { :data => @issues_by_version, :field_name => "fixed_version_id", :rows => @versions } 
 if @statuses.empty? or rows.empty? 
l(:label_no_data)
 else 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 for row in rows 
 link_to row.name, aggregate_path(@project, field_name, row) 
 aggregate_link data, { field_name => row.id, "closed" => 0 }, aggregate_path(@project, field_name, row, :status_id => "o") 
 aggregate_link data, { field_name => row.id, "closed" => 1 }, aggregate_path(@project, field_name, row, :status_id => "c") 
 aggregate_link data, { field_name => row.id }, aggregate_path(@project, field_name, row, :status_id => "*") 
 end 
 end 
 if @project.children.any? 
l(:field_subproject)
 link_to l(:label_details),
        project_issues_report_details_path(@project, :detail => 'subproject'),
        :class => 'icon-only icon-zoom-in',
        :title => l(:label_details) 
 render :partial => 'simple', :locals => { :data => @issues_by_subproject, :field_name => "project_id", :rows => @subprojects } 
 if @statuses.empty? or rows.empty? 
l(:label_no_data)
 else 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 for row in rows 
 link_to row.name, aggregate_path(@project, field_name, row) 
 aggregate_link data, { field_name => row.id, "closed" => 0 }, aggregate_path(@project, field_name, row, :status_id => "o") 
 aggregate_link data, { field_name => row.id, "closed" => 1 }, aggregate_path(@project, field_name, row, :status_id => "c") 
 aggregate_link data, { field_name => row.id }, aggregate_path(@project, field_name, row, :status_id => "*") 
 end 
 end 
 end 
l(:field_category)
 link_to l(:label_details),
        project_issues_report_details_path(@project, :detail => 'category'),
        :class => 'icon-only icon-zoom-in',
        :title => l(:label_details) 
 render :partial => 'simple', :locals => { :data => @issues_by_category, :field_name => "category_id", :rows => @categories } 
 if @statuses.empty? or rows.empty? 
l(:label_no_data)
 else 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 for row in rows 
 link_to row.name, aggregate_path(@project, field_name, row) 
 aggregate_link data, { field_name => row.id, "closed" => 0 }, aggregate_path(@project, field_name, row, :status_id => "o") 
 aggregate_link data, { field_name => row.id, "closed" => 1 }, aggregate_path(@project, field_name, row, :status_id => "c") 
 aggregate_link data, { field_name => row.id }, aggregate_path(@project, field_name, row, :status_id => "*") 
 end 
 end 
 call_hook(:view_reports_issue_report_split_content_right, :project => @project) 
  end
  def issue_report_details
    case params[:detail]
    when "tracker"
      @field = "tracker_id"
      @rows = @project.rolled_up_trackers(false).visible
      @data = Issue.by_tracker(@project)
      @report_title = l(:field_tracker)
    when "version"
      @field = "fixed_version_id"
      @rows = @project.shared_versions.sort
      @data = Issue.by_version(@project)
      @report_title = l(:field_version)
    when "priority"
      @field = "priority_id"
      @rows = IssuePriority.all.reverse
      @data = Issue.by_priority(@project)
      @report_title = l(:field_priority)
    when "category"
      @field = "category_id"
      @rows = @project.issue_categories
      @data = Issue.by_category(@project)
      @report_title = l(:field_category)
    when "assigned_to"
      @field = "assigned_to_id"
      @rows = (Setting.issue_group_assignment? ? @project.principals : @project.users).sort
      @data = Issue.by_assigned_to(@project)
      @report_title = l(:field_assigned_to)
    when "author"
      @field = "author_id"
      @rows = @project.users.sort
      @data = Issue.by_author(@project)
      @report_title = l(:field_author)
    when "subproject"
      @field = "project_id"
      @rows = @project.descendants.visible
      @data = Issue.by_subproject(@project) || []
      @report_title = l(:field_subproject)
    else
      render_404
    end
  end
l(:label_report_plural)
@report_title
 render :partial => 'details', :locals => { :data => @data, :field_name => @field, :rows => @rows } 
 if @statuses.empty? or rows.empty? 
l(:label_no_data)
 else 
 for status in @statuses 
 status.name 
 end 
l(:label_open_issues_plural)
l(:label_closed_issues_plural)
l(:label_total)
 for row in rows 
 link_to row.name, aggregate_path(@project, field_name, row) 
 for status in @statuses 
 aggregate_link data, { field_name => row.id, "status_id" => status.id }, aggregate_path(@project, field_name, row, :status_id => status.id) 
 end 
 aggregate_link data, { field_name => row.id, "closed" => 0 }, aggregate_path(@project, field_name, row, :status_id => "o") 
 aggregate_link data, { field_name => row.id, "closed" => 1 }, aggregate_path(@project, field_name, row, :status_id => "c") 
 aggregate_link data, { field_name => row.id }, aggregate_path(@project, field_name, row, :status_id => "*") 
 end 
 end 
 link_to l(:button_back), project_issues_report_path(@project) 
  private
  def find_issue_statuses
    @statuses = @project.rolled_up_statuses.sorted.to_a
  end
end
