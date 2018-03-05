class TimelogController < ApplicationController
  menu_item :time_entries
  before_action :find_time_entry, :only => [:show, :edit, :update]
  before_action :check_editability, :only => [:edit, :update]
  before_action :find_time_entries, :only => [:bulk_edit, :bulk_update, :destroy]
  before_action :authorize, :only => [:show, :edit, :update, :bulk_edit, :bulk_update, :destroy]
  before_action :find_optional_issue, :only => [:new, :create]
  before_action :find_optional_project, :only => [:index, :report]
  accept_rss_auth :index
  accept_api_auth :index, :show, :create, :update, :destroy
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  helper :issues
  include TimelogHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :queries
  include QueriesHelper
  def index
    retrieve_time_entry_query
    scope = time_entry_scope.
      preload(:issue => [:project, :tracker, :status, :assigned_to, :priority]).
      preload(:project, :user)
    respond_to do |format|
      format.html {
        @entry_count = scope.count
        @entry_pages = Paginator.new @entry_count, per_page_option, params['page']
        @entries = scope.offset(@entry_pages.offset).limit(@entry_pages.per_page).to_a
        render :layout => !request.xhr?
      }
      format.api  {
        @entry_count = scope.count
        @offset, @limit = api_offset_and_limit
        @entries = scope.offset(@offset).limit(@limit).preload(:custom_values => :custom_field).to_a
      }
      format.atom {
        entries = scope.limit(Setting.feeds_limit.to_i).reorder("#{TimeEntry.table_name}.created_on DESC").to_a
        render_feed(entries, :title => l(:label_spent_time))
      }
      format.csv {
        @entries = scope.to_a
        send_data(query_to_csv(@entries, @query, params), :type => 'text/csv; header=present', :filename => 'timelog.csv')
      }
    end
  end
 link_to l(:button_log_time), 
            _new_time_entry_path(@project, @query.filtered_issue_id),
            :class => 'icon icon-time-add' if User.current.allowed_to?(:log_time, @project, :global => true) 
 @query.new_record? ? l(:label_spent_time) : @query.name 
 form_tag(_time_entries_path(@project, nil), :method => :get, :id => 'query_form') do 
 render :partial => 'date_range' 
 render :partial => 'queries/query_form' 
 hidden_field_tag 'set_filter', '1' 
 hidden_field_tag 'type', @query.type, :disabled => true, :id => 'query_type' 
 query_hidden_sort_tag(@query) 
 @query.new_record? ? "" : "collapsed" 
 l(:label_filter_plural) 
 @query.new_record? ? "" : "display: none;" 
 render :partial => 'queries/filters', :locals => {:query => @query} 
 javascript_tag do 
 raw_json Query.operators_labels 
 raw_json Query.operators_by_filter_type 
 raw_json query.available_filters_as_json 
 raw_json l(:label_day_plural) 
 raw_json queries_filter_path(:project_id => @query.project.try(:id), :type => @query.type) 
 query.filters.each do |field, options| 
 field 
 raw_json query.operator_for(field) 
 raw_json query.values_for(field) 
 end 
 end 
 label_tag('add_filter_select', l(:label_filter_add)) 
 select_tag 'add_filter_select', filters_options_for_select(query), :name => nil 
 hidden_field_tag 'f[]', '' 
 include_calendar_headers_tags 
 l(:label_options) 
 l(:field_column_names) 
 render_query_columns_selection(@query) 
 if @query.groupable_columns.any? 
 l(:field_group_by) 
 group_by_column_select_tag(@query) 
 end 
 if @query.available_block_columns.any? 
 l(:button_show) 
 available_block_columns_tags(@query) 
 end 
 if @query.available_totalable_columns.any? 
 l(:label_total_plural) 
 available_totalable_columns_tags(@query) 
 end 
 link_to_function l(:button_apply), '$("#query_form").submit()', :class => 'icon icon-checked' 
 link_to l(:button_clear), { :set_filter => 1, :sort => '', :project_id => @project }, :class => 'icon icon-reload'  
 if @query.new_record? 
 if User.current.allowed_to?(:save_queries, @project, :global => true) 
 link_to_function l(:button_save),
                           "$('#query_type').prop('disabled',false);$('#query_form').attr('action', '#{ @project ? new_project_query_path(@project) : new_query_path }').submit()",
                           :class => 'icon icon-save' 
 end 
 else 
 if @query.editable_by?(User.current) 
 link_to l(:button_edit), edit_query_path(@query), :class => 'icon icon-edit' 
 delete_link query_path(@query) 
 end 
 end 
 error_messages_for @query 
 query_params = request.query_parameters 
 link_to(l(:label_details), _time_entries_path(@project, nil, :params => query_params),
                                       :class => (action_name == 'index' ? 'selected' : nil)) 
 link_to(l(:label_report), _report_time_entries_path(@project, nil, :params => query_params),
                                       :class => (action_name == 'report' ? 'selected' : nil)) 
 end 
 if @query.valid? 
 if @entries.empty? 
 l(:label_no_data) 
 else 
 render_query_totals(@query) 
 render :partial => 'list', :locals => { :entries => @entries }
 form_tag({}, :data => {:cm_url => time_entries_context_menu_path}) do 
 hidden_field_tag 'back_url', url_for(:params => request.query_parameters), :id => nil 
 check_box_tag 'check_all', '', false, :class => 'toggle-selection',
        :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}" 
 @query.inline_columns.each do |column| 
 column_header(@query, column) 
 end 
 grouped_query_results(entries, @query) do |entry, group_name, group_count, group_totals| 
 if group_name 
 reset_cycle 
 @query.inline_columns.size + 2 
 group_name 
 if group_count 
 group_count 
 end 
 group_totals 
 link_to_function("#{l(:button_collapse_all)}/#{l(:button_expand_all)}",
                             "toggleAllRowGroups(this)", :class => 'toggle-all') 
 end 
 entry.id 
 cycle("odd", "even") 
 check_box_tag("ids[]", entry.id, false, :id => nil) 
 @query.inline_columns.each do |column| 
 content_tag('td', column_content(column, entry), :class => column.css_classes) 
 end 
 if entry.editable_by?(User.current) 
 link_to l(:button_edit), edit_time_entry_path(entry),
                    :title => l(:button_edit),
                    :class => 'icon-only icon-edit' 
 link_to l(:button_delete), time_entry_path(entry),
                    :data => {:confirm => l(:text_are_you_sure)},
                    :method => :delete,
                    :title => l(:button_delete),
                    :class => 'icon-only icon-del' 
 end 
 @query.block_columns.each do |column|
       if (text = column_content(column, issue)) && text.present? 
 current_cycle 
 @query.inline_columns.size + 1 
 column.css_classes 
 if query.block_columns.count > 1 
 column.caption 
 end 
 text 
 end 
 end 
 end 
 end 
 context_menu 
 pagination_links_full @entry_pages, @entry_count 
 other_formats_links do |f| 
 f.link_to_with_query_parameters 'Atom', :key => User.current.rss_key 
 f.link_to_with_query_parameters 'CSV', {}, :onclick => "showModal('csv-export-options', '330px'); return false;" 
 end 
 l(:label_export_options, :export_format => 'CSV') 
 form_tag(_time_entries_path(@project, nil, :format => 'csv'), :method => :get, :id => 'csv-export-form') do 
 query_as_hidden_field_tags @query 
 radio_button_tag 'c[]', '', true 
 l(:description_selected_columns) 
 radio_button_tag 'c[]', 'all_inline' 
 l(:description_all_columns) 
 submit_tag l(:button_export), :name => nil, :onclick => "hideModal(this);" 
 submit_tag l(:button_cancel), :name => nil, :onclick => "hideModal(this);", :type => 'button' 
 end 
 end 
 end 
 content_for :sidebar do 
 render_sidebar_queries(TimeEntryQuery, @project) 
 end 
 html_title(@query.new_record? ? l(:label_spent_time) : @query.name, l(:label_details)) 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:issue_id => @issue, :format => 'atom', :key => User.current.rss_key}, :title => l(:label_spent_time)) 
 end 
  def report
    retrieve_time_entry_query
    scope = time_entry_scope
    @report = Redmine::Helpers::TimeReport.new(@project, @issue, params[:criteria], params[:columns], scope)
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.csv  { send_data(report_to_csv(@report), :type => 'text/csv; header=present', :filename => 'timelog.csv') }
    end
  end
 link_to l(:button_log_time), 
            _new_time_entry_path(@project, @issue),
            :class => 'icon icon-time-add' if User.current.allowed_to?(:log_time, @project, :global => true) 
 @query.new_record? ? l(:label_spent_time) : @query.name 
 form_tag(_report_time_entries_path(@project, nil), :method => :get, :id => 'query_form') do 
 @report.criteria.each do |criterion| 
 hidden_field_tag 'criteria[]', criterion, :id => nil 
 end 
 render :partial => 'timelog/date_range' 
 render :partial => 'queries/query_form' 
 hidden_field_tag 'set_filter', '1' 
 hidden_field_tag 'type', @query.type, :disabled => true, :id => 'query_type' 
 query_hidden_sort_tag(@query) 
 @query.new_record? ? "" : "collapsed" 
 l(:label_filter_plural) 
 @query.new_record? ? "" : "display: none;" 
 render :partial => 'queries/filters', :locals => {:query => @query} 
 javascript_tag do 
 raw_json Query.operators_labels 
 raw_json Query.operators_by_filter_type 
 raw_json query.available_filters_as_json 
 raw_json l(:label_day_plural) 
 raw_json queries_filter_path(:project_id => @query.project.try(:id), :type => @query.type) 
 query.filters.each do |field, options| 
 field 
 raw_json query.operator_for(field) 
 raw_json query.values_for(field) 
 end 
 end 
 label_tag('add_filter_select', l(:label_filter_add)) 
 select_tag 'add_filter_select', filters_options_for_select(query), :name => nil 
 hidden_field_tag 'f[]', '' 
 include_calendar_headers_tags 
 l(:label_options) 
 l(:field_column_names) 
 render_query_columns_selection(@query) 
 if @query.groupable_columns.any? 
 l(:field_group_by) 
 group_by_column_select_tag(@query) 
 end 
 if @query.available_block_columns.any? 
 l(:button_show) 
 available_block_columns_tags(@query) 
 end 
 if @query.available_totalable_columns.any? 
 l(:label_total_plural) 
 available_totalable_columns_tags(@query) 
 end 
 link_to_function l(:button_apply), '$("#query_form").submit()', :class => 'icon icon-checked' 
 link_to l(:button_clear), { :set_filter => 1, :sort => '', :project_id => @project }, :class => 'icon icon-reload'  
 if @query.new_record? 
 if User.current.allowed_to?(:save_queries, @project, :global => true) 
 link_to_function l(:button_save),
                           "$('#query_type').prop('disabled',false);$('#query_form').attr('action', '#{ @project ? new_project_query_path(@project) : new_query_path }').submit()",
                           :class => 'icon icon-save' 
 end 
 else 
 if @query.editable_by?(User.current) 
 link_to l(:button_edit), edit_query_path(@query), :class => 'icon icon-edit' 
 delete_link query_path(@query) 
 end 
 end 
 error_messages_for @query 
 query_params = request.query_parameters 
 link_to(l(:label_details), _time_entries_path(@project, nil, :params => query_params),
                                       :class => (action_name == 'index' ? 'selected' : nil)) 
 link_to(l(:label_report), _report_time_entries_path(@project, nil, :params => query_params),
                                       :class => (action_name == 'report' ? 'selected' : nil)) 
 l(:label_details) 
 select_tag 'columns', options_for_select([[l(:label_year), 'year'],
                                                                            [l(:label_month), 'month'],
                                                                            [l(:label_week), 'week'],
                                                                            [l(:label_day_plural).titleize, 'day']], @report.columns),
                                                        :onchange => "this.form.submit();" 
 l(:button_add) 
 select_tag('criteria[]', options_for_select([[]] + (@report.available_criteria.keys - @report.criteria).collect{|k| [l_or_humanize(@report.available_criteria[k][:label]), k]}),
                                                          :onchange => "this.form.submit();",
                                                          :style => 'width: 200px',
                                                          :disabled => (@report.criteria.length >= 3),
                                                          :id => "criterias") 
 link_to l(:button_clear), {:params => request.query_parameters.merge(:criteria => nil)}, :class => 'icon icon-reload' 
 end 
 if @query.valid? 
 unless @report.criteria.empty? 
 if @report.hours.empty? 
 l(:label_no_data) 
 else 
 @report.criteria.each do |criteria| 
 l_or_humanize(@report.available_criteria[criteria][:label]) 
 end 
 columns_width = (40 / (@report.periods.length+1)).to_i 
 @report.periods.each do |period| 
 columns_width 
 period 
 end 
 columns_width 
 l(:label_total_time) 
 render :partial => 'report_criteria', :locals => {:criterias => @report.criteria, :hours => @report.hours, :level => 0} 
 @report.hours.collect {|h| h[criterias[level]].to_s}.uniq.each do |value| 
 hours_for_value = select_hours(hours, criterias[level], value) 
 next if hours_for_value.empty? 
 criterias.length > level+1 ? 'subtotal' : 'last-level' 
 ("<td></td>" * level).html_safe 
 format_criteria_value(@report.available_criteria[criterias[level]], value) 
 ("<td></td>" * (criterias.length - level - 1)).html_safe 
 total = 0 
 @report.periods.each do |period| 
 sum = sum_hours(select_hours(hours_for_value, @report.columns, period.to_s)); total += sum 
 html_hours(format_hours(sum)) if sum > 0 
 end 
 html_hours(format_hours(total)) if total > 0 
 if criterias.length > level+1 
 render(:partial => 'report_criteria', :locals => {:criterias => criterias, :hours => hours_for_value, :level => (level + 1)}) 
 end 
 end 
 l(:label_total_time) 
 ('<td></td>' * (@report.criteria.size - 1)).html_safe 
 total = 0 
 @report.periods.each do |period| 
 sum = sum_hours(select_hours(@report.hours, @report.columns, period.to_s)); total += sum 
 html_hours(format_hours(sum)) if sum > 0 
 end 
 html_hours(format_hours(total)) if total > 0 
 other_formats_links do |f| 
 f.link_to_with_query_parameters 'CSV' 
 end 
 end 
 end 
 end 
 content_for :sidebar do 
 render_sidebar_queries(TimeEntryQuery, @project) 
 end 
 html_title(@query.new_record? ? l(:label_spent_time) : @query.name, l(:label_report)) 
  def show
    respond_to do |format|
      format.html { head 406 }
      format.api
    end
  end
  def new
    @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => User.current.today)
    @time_entry.safe_attributes = params[:time_entry]
  end
 l(:label_spent_time) 
 labelled_form_for @time_entry, :url => time_entries_path, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 submit_tag l(:button_create_and_continue), :name => 'continue' 
 end 
  def create
    @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => User.current.today)
    @time_entry.safe_attributes = params[:time_entry]
    if @time_entry.project && !User.current.allowed_to?(:log_time, @time_entry.project)
      render_403
      return
    end
    call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
    if @time_entry.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          if params[:continue]
            options = {
              :time_entry => {
                :project_id => params[:time_entry][:project_id],
                :issue_id => @time_entry.issue_id,
                :activity_id => @time_entry.activity_id
              },
              :back_url => params[:back_url]
            }
            if params[:project_id] && @time_entry.project
              redirect_to new_project_time_entry_path(@time_entry.project, options)
            elsif params[:issue_id] && @time_entry.issue
              redirect_to new_issue_time_entry_path(@time_entry.issue, options)
            else
              redirect_to new_time_entry_path(options)
            end
          else
            redirect_back_or_default project_time_entries_path(@time_entry.project)
          end
        }
        format.api  { render :action => 'show', :status => :created, :location => time_entry_url(@time_entry) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
 l(:label_spent_time) 
 labelled_form_for @time_entry, :url => time_entries_path, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 submit_tag l(:button_create_and_continue), :name => 'continue' 
 end 
        format.api  { render_validation_errors(@time_entry) }
      end
    end
  end
  def edit
    @time_entry.safe_attributes = params[:time_entry]
  end
 l(:label_spent_time) 
 labelled_form_for @time_entry, :url => time_entry_path(@time_entry), :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
  def update
    @time_entry.safe_attributes = params[:time_entry]
    call_hook(:controller_timelog_edit_before_save, { :params => params, :time_entry => @time_entry })
    if @time_entry.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default project_time_entries_path(@time_entry.project)
        }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
 l(:label_spent_time) 
 labelled_form_for @time_entry, :url => time_entry_path(@time_entry), :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
        format.api  { render_validation_errors(@time_entry) }
      end
    end
  end
  def bulk_edit
    @available_activities = @projects.map(&:activities).reduce(:&)
    @custom_fields = TimeEntry.first.available_custom_fields.select {|field| field.format.bulk_edit_supported}
  end
 l(:label_bulk_edit_selected_time_entries) 
 if @unsaved_time_entries.present? 
 l(:notice_failed_to_save_time_entries,
        :count => @unsaved_time_entries.size,
        :total => @saved_time_entries.size,
        :ids => @unsaved_time_entries.map {|i| "##{i.id}"}.join(', ')) 
 bulk_edit_error_messages(@unsaved_time_entries).each do |message| 
 message 
 end 
 end 
 @time_entries.each do |entry| 
 content_tag 'li',
        link_to("#{format_date(entry.spent_on)} - #{entry.project}: #{l(:label_f_hour_plural, :value => entry.hours)}", edit_time_entry_path(entry)) 
 end 
 form_tag(bulk_update_time_entries_path, :id => 'bulk_edit_form') do 
 @time_entries.collect {|i| hidden_field_tag('ids[]', i.id, :id => nil)}.join.html_safe 
 l(:field_issue) 
 text_field :time_entry, :issue_id, :size => 6 
 l(:field_spent_on) 
 date_field :time_entry, :spent_on, :size => 10 
 calendar_for('time_entry_spent_on') 
 l(:field_hours) 
 text_field :time_entry, :hours, :size => 6 
 if @available_activities.any? 
 l(:field_activity) 
 select_tag('time_entry[activity_id]', content_tag('option', l(:label_no_change_option), :value => '') + options_from_collection_for_select(@available_activities, :id, :name)) 
 end 
 l(:field_comments) 
 text_field(:time_entry, :comments, :size => 100) 
 @custom_fields.each do |custom_field| 
 h(custom_field.name) 
 custom_field_tag_for_bulk_edit('time_entry', custom_field, @time_entries) 
 end 
 call_hook(:view_time_entries_bulk_edit_details_bottom, { :time_entries => @time_entries }) 
 submit_tag l(:button_submit) 
 end 
  def bulk_update
    attributes = parse_params_for_bulk_update(params[:time_entry])
    unsaved_time_entries = []
    saved_time_entries = []
    @time_entries.each do |time_entry|
      time_entry.reload
      time_entry.safe_attributes = attributes
      call_hook(:controller_time_entries_bulk_edit_before_save, { :params => params, :time_entry => time_entry })
      if time_entry.save
        saved_time_entries << time_entry
      else
        unsaved_time_entries << time_entry
      end
    end
    if unsaved_time_entries.empty?
      flash[:notice] = l(:notice_successful_update) unless saved_time_entries.empty?
      redirect_back_or_default project_time_entries_path(@projects.first)
    else
      @saved_time_entries = @time_entries
      @unsaved_time_entries = unsaved_time_entries
      @time_entries = TimeEntry.where(:id => unsaved_time_entries.map(&:id)).
        preload(:project => :time_entry_activities).
        preload(:user).to_a
      bulk_edit
      render :action => 'bulk_edit'
 l(:label_bulk_edit_selected_time_entries) 
 if @unsaved_time_entries.present? 
 l(:notice_failed_to_save_time_entries,
        :count => @unsaved_time_entries.size,
        :total => @saved_time_entries.size,
        :ids => @unsaved_time_entries.map {|i| "##{i.id}"}.join(', ')) 
 bulk_edit_error_messages(@unsaved_time_entries).each do |message| 
 message 
 end 
 end 
 @time_entries.each do |entry| 
 content_tag 'li',
        link_to("#{format_date(entry.spent_on)} - #{entry.project}: #{l(:label_f_hour_plural, :value => entry.hours)}", edit_time_entry_path(entry)) 
 end 
 form_tag(bulk_update_time_entries_path, :id => 'bulk_edit_form') do 
 @time_entries.collect {|i| hidden_field_tag('ids[]', i.id, :id => nil)}.join.html_safe 
 l(:field_issue) 
 text_field :time_entry, :issue_id, :size => 6 
 l(:field_spent_on) 
 date_field :time_entry, :spent_on, :size => 10 
 calendar_for('time_entry_spent_on') 
 l(:field_hours) 
 text_field :time_entry, :hours, :size => 6 
 if @available_activities.any? 
 l(:field_activity) 
 select_tag('time_entry[activity_id]', content_tag('option', l(:label_no_change_option), :value => '') + options_from_collection_for_select(@available_activities, :id, :name)) 
 end 
 l(:field_comments) 
 text_field(:time_entry, :comments, :size => 100) 
 @custom_fields.each do |custom_field| 
 h(custom_field.name) 
 custom_field_tag_for_bulk_edit('time_entry', custom_field, @time_entries) 
 end 
 call_hook(:view_time_entries_bulk_edit_details_bottom, { :time_entries => @time_entries }) 
 submit_tag l(:button_submit) 
 end 
    end
  end
  def destroy
    destroyed = TimeEntry.transaction do
      @time_entries.each do |t|
        unless t.destroy && t.destroyed?
          raise ActiveRecord::Rollback
        end
      end
    end
    respond_to do |format|
      format.html {
        if destroyed
          flash[:notice] = l(:notice_successful_delete)
        else
          flash[:error] = l(:notice_unable_delete_time_entry)
        end
        redirect_back_or_default project_time_entries_path(@projects.first), :referer => true
      }
      format.api  {
        if destroyed
          render_api_ok
        else
          render_validation_errors(@time_entries)
        end
      }
    end
  end
private
  def find_time_entry
    @time_entry = TimeEntry.find(params[:id])
    @project = @time_entry.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def check_editability
    unless @time_entry.editable_by?(User.current)
      render_403
      return false
    end
  end
  def find_time_entries
    @time_entries = TimeEntry.where(:id => params[:id] || params[:ids]).
      preload(:project => :time_entry_activities).
      preload(:user).to_a
    raise ActiveRecord::RecordNotFound if @time_entries.empty?
    raise Unauthorized unless @time_entries.all? {|t| t.editable_by?(User.current)}
    @projects = @time_entries.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def find_optional_issue
    if params[:issue_id].present?
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
      authorize
    else
      find_optional_project
    end
  end
  def time_entry_scope(options={})
    @query.results_scope(options)
  end
  def retrieve_time_entry_query
    retrieve_query(TimeEntryQuery, false, :defaults => Setting.time_entry_list_defaults.symbolize_keys)
  end
end
