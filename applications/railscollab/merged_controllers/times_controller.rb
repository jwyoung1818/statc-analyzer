#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
# Portions Copyright (C) René Scheibe
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class TimesController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  before_filter :process_session
  before_filter :obtain_time,     :except => [:index, :by_task, :new, :create]
  before_filter :prepare_times,   :only   => [:index, :by_task, :export]
  after_filter  :user_track,      :only   => [:index, :by_task, :view]

  def index
    authorize! :manage_time, @active_project
    
    respond_to do |format|
      format.html {
        @project = @active_project
        @content_for_sidebar = 'index_sidebar'
    
        @times = @project.time_records.where(@time_conditions)
                                       .paginate(:page => @current_page, :per_page => Rails.configuration.times_per_page)
                                       .order("#{@sort_type} #{@sort_order}")
        
        @pagination = []
        @times.total_pages.times {|page| @pagination << page+1}
    
      }
      format.xml  {
        @times = @project.time_records.where(@time_conditions)
                                       .offset(params[:offset])
                                       .limit(params[:limit] || Rails.configuration.times_per_page) 
                                       .order("#{@sort_type} #{@sort_order}")
        
        render :xml => @times.to_xml(:root => 'times')
      }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

  @page_actions = []
  
  if can? :create_time, @active_project
    @page_actions << {:title => :add_time, :url => new_time_path}
  end
  
  @page_actions << {:title => :sort_by_finished_date, :url => "#{times_path}?orderBy=done_date"}
  @page_actions << {:title => :sort_by_hours, :url => "#{times_path}?orderBy=hours"}
  @page_actions << {:title => :report_by_task, :url => "#{by_task_times_path}?orderBy=hours"}

 if not @times.empty? 
 pagination_links "#{times_path}?", @pagination unless @pagination.length <= 1 
 t('log_date') 
 t('person') 
 t('hours') 
 t('summary') 
 time_now = Time.now 
 @times.each do |time| 

  class_name = if time.running?
    'timeRunning'
  elsif time.is_today?
    'timeToday'
  elsif time.is_yesterday?
    'timeYesterday'
  else
    'timeOlder'
  end

 class_name 
 if time.running? 
 t('time_running') 
 else 
 format_usertime(time.done_date, "done_date_format#{'_with_year' if time.done_date.year != Time.now.year}") 
 end 
 if time.assigned_to.nil? 
 else 
 h time.assigned_to.object_name 
 end 
 '*' if time.is_billable 
 if time.running? 
 seconds_to_time Time.now - time.start_date 
 else 
 time.hours 
 end 
 if !time.open_task.nil? 
 link_to(time.name, time.open_task.object_url, :class => 'assignedTo') 
 else 
 h time.name 
 end 
 action_list actions_for_time(time) 
 end 
 pagination_links "#{times_path}?", @pagination unless @pagination.length <= 1 
 else 
 t('no_times_in_project') 
 end 

end

  end

  def by_task
    authorize! :manage_time, @active_project

    respond_to do |format|
      format.html {
        @tasks = TimeRecord.find_by_task_lists(@active_project.task_lists, @time_conditions)
        @content_for_sidebar = 'index_sidebar'
      }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

  @page_actions = []
  
  if can? :create_time, @active_project
    @page_actions << {:title => :add_time, :url => new_time_path}
  end
  
  @page_actions << {:title => :sort_by_finished_date, :url => "#{times_path}?orderBy=done_date"}
  @page_actions << {:title => :sort_by_hours, :url => "#{times_path}?orderBy=hours"}
  @page_actions << {:title => :report_by_task, :url => "#{by_task_times_path}?orderBy=hours"}

 if not @tasks.empty? 
 @tasks.each do |list| 
 total_time = list[:tasks].inject(0) { |total, task| total + task[:hours] } 
 total_billable_time = list[:tasks].inject(0) { |total, task| total + task[:billable_hours] } 
 total_estimated_time = list[:tasks].inject(0) { |total, task| total + (task[:task].estimated_hours || 0) } 
 if total_time > 0 
 t('task_list_hours', :name => h(list[:list].object_name), :hours => total_time) 
 t('billable_hours', :hours => total_time) if total_billable_time > 0 
 t('task_estimated_hours', :hours => total_estimated_time) if total_estimated_time > 0 
 t('task_list_hours_info') 
 list[:tasks].each do |task_info| 
 task = task_info[:task] 
 t('task_list_task_hours', :name => h(task.object_name), :hours => task_info[:hours]) 
 t('billable_hours', :hours => task_info[:billable_hours]) if task_info[:billable_hours] > 0 
 t('task_estimated_hours', :hours => task.estimated_hours) if task.estimated_hours && task.estimated_hours > 0 
 t('log_date') 
 t('name') 
 t('details') 
 t('hours') 
 task_info[:times].each do |time| 
 if time.running? 
 t('time_running') 
 else 
 format_usertime(time.done_date, "done_date_format#{'_with_year' if time.done_date.year != Time.now.year}") 
 end 
 if time.assigned_to.nil? 
 else 
 h time.assigned_to.object_name 
 end 
 h time.name 
 '*' if time.is_billable 
 if time.running? 
 seconds_to_time Time.now - time.start_date 
 else 
 time.hours 
 end 
 end 
 end 
 end 
 end 
 else 
 t('no_times_in_project') 
 end 

end

  end

  def show
    authorize! :show, @time
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
     render :partial => 'times/show', :collection => [@time] 
 
 
 
 

end

  end

  def new
    authorize! :create_time, @active_project

    @time = @active_project.time_records.build
    @open_task_lists = @active_project.task_lists.is_open
    @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
    @task_filter = Proc.new {|task| task.is_completed? }
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 form_tag times_path 
  error_messages_for :time 
 t('summary') 
 text_field 'time', 'name', :id => 'timeFormName', :class => 'long' 
 if @open_task_lists.length > 0 
 t('open_tasks') 
 task_collection_select 'time', 'open_task_id', @open_task_lists, @task_filter, :id => 'timeOpenTasks' 
 end 
 if @time.start_date.nil? 
 t('hours') 
 text_field 'time', 'hours', :id => 'timeFormHours', :class => 'short' 
 end 
 t('description') 
 text_area 'time', 'description', :id => 'timeFormDesc', :class => 'short', :rows => 10, :cols => 40 
 if @time.start_date.nil? 
 t('done_date') 
 date_select 'time', 'done_date', :id => 'timeDoneDate', :class => 'short' 
 end 
 if @logged_user.member_of_owner? 
 t('private_time') 
 t('private_time_info') 
 yesno_toggle 'time', 'is_private', :id => 'timeFormIsPrivate', :class => 'checkbox'  
 t('billable_time') 
 t('billable_time_info') 
 yesno_toggle 'time', 'is_billable', :id => 'timeFormIsBillable', :class => 'checkbox'  
 end 
 t('assign_to') 
 assign_project_select 'time', 'assigned_to_id', @active_project, :id => 'timeFormAssignedTo' 
 
 t('add_time') 

end

  end
  
  def create
    authorize! :create_time, @active_project

    @time = @active_project.time_records.build
    
    @time.attributes = params[:time]
    @time.start_date = Time.current unless @time.done_date
    @time.created_by = @logged_user
    
    respond_to do |format|
      if @time.save
        add_running_time(@time)
        
        format.html {
          error_status(false, :success_added_time)
          redirect_back_or_default(@time)
        }
        format.js   { respond_with_time(@time) }
        format.xml  { render :xml => @time.to_xml(:root => 'time'), :status => :created, :location => @time }
      else
        @open_task_lists = @active_project.task_lists.is_open
        @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
        @task_filter = Proc.new {|task| task.is_completed? }
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 form_tag times_path 
  error_messages_for :time 
 t('summary') 
 text_field 'time', 'name', :id => 'timeFormName', :class => 'long' 
 if @open_task_lists.length > 0 
 t('open_tasks') 
 task_collection_select 'time', 'open_task_id', @open_task_lists, @task_filter, :id => 'timeOpenTasks' 
 end 
 if @time.start_date.nil? 
 t('hours') 
 text_field 'time', 'hours', :id => 'timeFormHours', :class => 'short' 
 end 
 t('description') 
 text_area 'time', 'description', :id => 'timeFormDesc', :class => 'short', :rows => 10, :cols => 40 
 if @time.start_date.nil? 
 t('done_date') 
 date_select 'time', 'done_date', :id => 'timeDoneDate', :class => 'short' 
 end 
 if @logged_user.member_of_owner? 
 t('private_time') 
 t('private_time_info') 
 yesno_toggle 'time', 'is_private', :id => 'timeFormIsPrivate', :class => 'checkbox'  
 t('billable_time') 
 t('billable_time_info') 
 yesno_toggle 'time', 'is_billable', :id => 'timeFormIsBillable', :class => 'checkbox'  
 end 
 t('assign_to') 
 assign_project_select 'time', 'assigned_to_id', @active_project, :id => 'timeFormAssignedTo' 
 
 t('add_time') 

end
 }
        format.js   { respond_with_time(@time) }
        format.xml  { render :xml => @time.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    authorize! :edit, @time

    @open_task_lists = @active_project.task_lists.is_open
    @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
    @open_task_lists << @time.task_list unless @time.task_list.nil? || @open_task_lists.include?(@time.task_list)
    @task_filter = Proc.new {|task| task.is_completed? && task != @time.task}
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 form_tag time_path(:id => @time.id), :method => :put 
  error_messages_for :time 
 t('summary') 
 text_field 'time', 'name', :id => 'timeFormName', :class => 'long' 
 if @open_task_lists.length > 0 
 t('open_tasks') 
 task_collection_select 'time', 'open_task_id', @open_task_lists, @task_filter, :id => 'timeOpenTasks' 
 end 
 if @time.start_date.nil? 
 t('hours') 
 text_field 'time', 'hours', :id => 'timeFormHours', :class => 'short' 
 end 
 t('description') 
 text_area 'time', 'description', :id => 'timeFormDesc', :class => 'short', :rows => 10, :cols => 40 
 if @time.start_date.nil? 
 t('done_date') 
 date_select 'time', 'done_date', :id => 'timeDoneDate', :class => 'short' 
 end 
 if @logged_user.member_of_owner? 
 t('private_time') 
 t('private_time_info') 
 yesno_toggle 'time', 'is_private', :id => 'timeFormIsPrivate', :class => 'checkbox'  
 t('billable_time') 
 t('billable_time_info') 
 yesno_toggle 'time', 'is_billable', :id => 'timeFormIsBillable', :class => 'checkbox'  
 end 
 t('assign_to') 
 assign_project_select 'time', 'assigned_to_id', @active_project, :id => 'timeFormAssignedTo' 
 
 t('edit_time') 

end

  end

  def update
    authorize! :edit, @time

    @time.attributes = params[:time]
    @time.updated_by = @logged_user
    
    respond_to do |format|
      if @time.save
        format.html {
          error_status(false, :success_edited_time)
          redirect_back_or_default(@time)
        }
        format.xml  { head :ok }
      else
        @open_task_lists = @active_project.task_lists.is_open
        @open_task_lists = @open_task_lists.is_public unless @logged_user.member_of_owner?
        @open_task_lists << @time.task_list unless @time.task_list.nil? || @open_task_lists.include?(@time.task_list)
        @task_filter = Proc.new {|task| task.is_completed? && task != @time.task}
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 form_tag time_path(:id => @time.id), :method => :put 
  error_messages_for :time 
 t('summary') 
 text_field 'time', 'name', :id => 'timeFormName', :class => 'long' 
 if @open_task_lists.length > 0 
 t('open_tasks') 
 task_collection_select 'time', 'open_task_id', @open_task_lists, @task_filter, :id => 'timeOpenTasks' 
 end 
 if @time.start_date.nil? 
 t('hours') 
 text_field 'time', 'hours', :id => 'timeFormHours', :class => 'short' 
 end 
 t('description') 
 text_area 'time', 'description', :id => 'timeFormDesc', :class => 'short', :rows => 10, :cols => 40 
 if @time.start_date.nil? 
 t('done_date') 
 date_select 'time', 'done_date', :id => 'timeDoneDate', :class => 'short' 
 end 
 if @logged_user.member_of_owner? 
 t('private_time') 
 t('private_time_info') 
 yesno_toggle 'time', 'is_private', :id => 'timeFormIsPrivate', :class => 'checkbox'  
 t('billable_time') 
 t('billable_time_info') 
 yesno_toggle 'time', 'is_billable', :id => 'timeFormIsBillable', :class => 'checkbox'  
 end 
 t('assign_to') 
 assign_project_select 'time', 'assigned_to_id', @active_project, :id => 'timeFormAssignedTo' 
 
 t('edit_time') 

end
 }
        format.xml  { render :xml => @time.errors, :status => :unprocessable_entity }
      end
    end
  end

  def stop
    authorize! :edit, @time
    
    @time.hours = @time.hours # Save calculated hours before setting done_date
    @time.done_date = Time.current
    @time.updated_by = @logged_user
    @time.save
    
    remove_running_time(@time)
    
    respond_to do |format|
      format.html {
        error_status(false, :success_stopped_time)
        redirect_back_or_default(@time)
      }
      format.js { respond_with_time(@time) }
      format.xml  { head :ok }
    end
    
  end

  def destroy
    authorize! :delete, @time
    
    remove_running_time(@time)
    
    @time.updated_by = @logged_user
    @time.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_time)
        redirect_back_or_default(times_url)
      }
      format.js { respond_with_time(@time) }
      format.xml  { head :ok }
    end
  end

private

  def respond_with_time(time)
    if time.errors
      render :json => {:id => time.id, :time => time, :task => time.task, :content => render_to_string({:partial => 'listed', :collection => [time]})}
    else
      render :json => {:id => time.id, :time => time, :task => time.task, :errors => time.errors}, :status => :unprocessable_entity
    end
  end

  def obtain_time
    begin
      @time = @active_project.time_records.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_time)
      redirect_back_or_default times_path
      return false
    end

    true
  end

  def prepare_times
    @current_page = params[:page].to_i
    @current_page = 1 unless @current_page > 0
    
    @time_conditions = @logged_user.member_of_owner? ? {} : {'is_private' => false}
    @sort_type = params[:orderBy]
    @sort_type = 'created_on' unless ['done_date', 'hours'].include?(params[:orderBy])
    @sort_order = 'DESC'
  end
  
  def add_running_time(time)
    @running_times.each { |chk| return if chk.id == time.id }
    @running_times << time
  end
  
  def remove_running_time(time)
    @running_times.reject! { |chk| chk.id == time.id ? true : false }
  end
end
