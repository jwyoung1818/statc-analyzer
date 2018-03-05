class CalendarsController < ApplicationController
  menu_item :calendar
  before_action :find_optional_project
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  def show
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end
    @year ||= User.current.today.year
    @month ||= User.current.today.month
    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    retrieve_query
    @query.group_by = nil
    @query.sort_criteria = nil
    if @query.valid?
      events = []
      events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                              )
      events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])
      @calendar.events = events
    end
    render :action => 'show', :layout => false if request.xhr?
 @query.new_record? ? l(:label_calendar) : @query.name 
 form_tag({:controller => 'calendars', :action => 'show', :project_id => @project},
             :method => :get, :id => 'query_form') do 
 hidden_field_tag 'set_filter', '1' 
 @query.new_record? ? "" : "collapsed" 
 l(:label_filter_plural) 
 @query.new_record? ? "" : "display: none;" 
 render :partial => 'queries/filters', :locals => {:query => @query} 
 link_to_previous_month(@year, @month, :accesskey => accesskey(:previous)) 
 link_to_next_month(@year, @month, :accesskey => accesskey(:next)) 
 label_tag('month', l(:label_month)) 
 select_month(@month, :prefix => "month", :discard_type => true) 
 label_tag('year', l(:label_year)) 
 select_year(@year, :prefix => "year", :discard_type => true) 
 link_to_function l(:button_apply), '$("#query_form").submit()', :class => 'icon icon-checked' 
 link_to l(:button_clear), { :project_id => @project, :set_filter => 1 }, :class => 'icon icon-reload' 
 end 
 error_messages_for 'query' 
 if @query.valid? 
 render :partial => 'common/calendar', :locals => {:calendar => @calendar} 
 call_hook(:view_calendars_show_bottom, :year => @year, :month => @month, :project => @project, :query => @query) 
 l(:text_tip_issue_begin_day) 
 l(:text_tip_issue_end_day) 
 l(:text_tip_issue_begin_end_day) 
 end 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 end 
 html_title(l(:label_calendar)) 
  end
end
