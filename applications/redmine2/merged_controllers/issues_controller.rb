class IssuesController < ApplicationController
  default_search_scope :issues
  before_action :find_issue, :only => [:show, :edit, :update]
  before_action :find_issues, :only => [:bulk_edit, :bulk_update, :destroy]
  before_action :authorize, :except => [:index, :new, :create]
  before_action :find_optional_project, :only => [:index, :new, :create]
  before_action :build_new_issue_from_params, :only => [:new, :create]
  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  helper :journals
  helper :projects
  helper :custom_fields
  helper :issue_relations
  helper :watchers
  helper :attachments
  helper :queries
  include QueriesHelper
  helper :repositories
  helper :timelog
  def index
    retrieve_query
    if @query.valid?
      respond_to do |format|
        format.html {
          @issue_count = @query.issue_count
          @issue_pages = Paginator.new @issue_count, per_page_option, params['page']
          @issues = @query.issues(:offset => @issue_pages.offset, :limit => @issue_pages.per_page)
          render :layout => !request.xhr?
        }
        format.api  {
          @offset, @limit = api_offset_and_limit
          @query.column_names = %w(author)
          @issue_count = @query.issue_count
          @issues = @query.issues(:offset => @offset, :limit => @limit)
          Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
        }
        format.atom {
          @issues = @query.issues(:limit => Setting.feeds_limit.to_i)
          render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}")
        }
        format.csv  {
          @issues = @query.issues(:limit => Setting.issues_export_limit.to_i)
          send_data(query_to_csv(@issues, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'issues.csv')
        }
        format.pdf  {
          @issues = @query.issues(:limit => Setting.issues_export_limit.to_i)
          send_file_headers! :type => 'application/pdf', :filename => 'issues.pdf'
        }
      end
    else
      respond_to do |format|
        format.html { render :layout => !request.xhr? }
        format.any(:atom, :csv, :pdf) { head 422 }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
 if User.current.allowed_to?(:add_issues, @project, :global => true) && (@project.nil? || Issue.allowed_target_trackers(@project).any?) 
 link_to l(:label_issue_new), _new_project_issue_path(@project), :class => 'icon icon-add new-issue' 
 end 
 @query.new_record? ? l(:label_issue_plural) : @query.name 
 html_title(@query.new_record? ? l(:label_issue_plural) : @query.name) 
 form_tag(_project_issues_path(@project), :method => :get, :id => 'query_form') do 
 render :partial => 'queries/query_form' 
 end 
 if @query.valid? 
 if @issues.empty? 
 l(:label_no_data) 
 else 
 render_query_totals(@query) 
 render :partial => 'issues/list', :locals => {:issues => @issues, :query => @query} 
 query_options = nil unless defined?(query_options) 
 query_options ||= {} 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 hidden_field_tag 'back_url', url_for(:params => request.query_parameters), :id => nil 
 query.css_classes 
 check_box_tag 'check_all', '', false, :class => 'toggle-selection',
              :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}" 
 query.inline_columns.each do |column| 
 column_header(query, column, query_options) 
 end 
 grouped_issue_list(issues, query) do |issue, level, group_name, group_count, group_totals| 
 if group_name 
 reset_cycle 
 query.inline_columns.size + 1 
 group_name 
 group_count 
 group_totals 
 link_to_function("#{l(:button_collapse_all)}/#{l(:button_expand_all)}",
                             "toggleAllRowGroups(this)", :class => 'toggle-all') 
 end 
 issue.id 
 cycle('odd', 'even') 
 issue.css_classes 
 level > 0 ? "idnt idnt-#{level}" : nil 
 check_box_tag("ids[]", issue.id, false, :id => nil) 
 query.inline_columns.each do |column| 
 content_tag('td', column_content(column, issue), :class => column.css_classes) 
 end 
 query.block_columns.each do |column|
       if (text = column_content(column, issue)) && text.present? 
 current_cycle 
 query.inline_columns.size + 1 
 column.css_classes 
 if query.block_columns.count > 1 
 column.caption 
 end 
 text 
 end 
 end 
 end 
 end 
 pagination_links_full @issue_pages, @issue_count 
 end 
 other_formats_links do |f| 
 f.link_to_with_query_parameters 'Atom', :key => User.current.rss_key 
 f.link_to_with_query_parameters 'CSV', {}, :onclick => "showModal('csv-export-options', '350px'); return false;" 
 f.link_to_with_query_parameters 'PDF' 
 end 
 l(:label_export_options, :export_format => 'CSV') 
 form_tag(_project_issues_path(@project, :format => 'csv'), :method => :get, :id => 'csv-export-form') do 
 query_as_hidden_field_tags(@query) 
 radio_button_tag 'c[]', '', true 
 l(:description_selected_columns) 
 radio_button_tag 'c[]', 'all_inline' 
 l(:description_all_columns) 
 check_box_tag 'c[]', 'description', @query.has_column?(:description) 
 l(:field_description) 
 check_box_tag 'c[]', 'last_notes', @query.has_column?(:last_notes) 
 l(:label_last_notes) 
 if @issue_count > Setting.issues_export_limit.to_i 
 l(:setting_issues_export_limit) 
 Setting.issues_export_limit.to_i 
 end 
 submit_tag l(:button_export), :name => nil, :onclick => "hideModal(this);" 
 submit_tag l(:button_cancel), :name => nil, :onclick => "hideModal(this);", :type => 'button' 
 end 
 end 
 call_hook(:view_issues_index_bottom, { :issues => @issues, :project => @project, :query => @query }) 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 l(:label_issue_plural) 
 link_to l(:label_issue_view_all), _project_issues_path(@project, :set_filter => 1) 
 if @project 
 link_to l(:field_summary), project_issues_report_path(@project) 
 end 
 if User.current.allowed_to?(:import_issues, @project, :global => true) 
 link_to l(:button_import), new_issues_import_path 
 end 
 call_hook(:view_issues_sidebar_issues_bottom) 
 call_hook(:view_issues_sidebar_planning_bottom) 
 render_sidebar_queries(IssueQuery, @project) 
 call_hook(:view_issues_sidebar_queries_bottom) 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom,
                                {:query_id => @query, :format => 'atom',
                                 :page => nil, :key => User.current.rss_key},
                                :title => l(:label_issue_plural)) 
 auto_discovery_link_tag(:atom,
                                {:controller => 'journals', :action => 'index',
                                 :query_id => @query, :format => 'atom',
                                 :page => nil, :key => User.current.rss_key},
                                :title => l(:label_changes_details)) 
 end 
 context_menu 
  def show
    @journals = @issue.visible_journals_with_index
    @changesets = @issue.changesets.visible.preload(:repository, :user).to_a
    @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
    if User.current.wants_comments_in_reverse_order?
      @journals.reverse!
      @changesets.reverse!
    end
    if User.current.allowed_to?(:view_time_entries, @project)
      Issue.load_visible_spent_hours([@issue])
      Issue.load_visible_total_spent_hours([@issue])
    end
    respond_to do |format|
      format.html {
        @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
        @priorities = IssuePriority.active
        @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
        @relation = IssueRelation.new
        retrieve_previous_and_next_issue_ids
        render :template => 'issues/show'
 render :partial => 'action_menu' 
 link_to l(:button_edit), edit_issue_path(@issue), :onclick => 'showAndScrollTo("update", "issue_notes"); return false;', :class => 'icon icon-edit', :accesskey => accesskey(:edit) if @issue.editable? 
 link_to l(:button_log_time), new_issue_time_entry_path(@issue), :class => 'icon icon-time-add' if User.current.allowed_to?(:log_time, @project) 
 watcher_link(@issue, User.current) 
 link_to l(:button_copy), project_copy_issue_path(@project, @issue), :class => 'icon icon-copy' if User.current.allowed_to?(:copy_issues, @project) && Issue.allowed_target_projects.any? 
 link_to l(:button_delete), issue_path(@issue), :data => {:confirm => issues_destroy_confirmation_message(@issue)}, :method => :delete, :class => 'icon icon-del' if @issue.deletable? 
 issue_heading(@issue) 
 @issue.css_classes 
 if @prev_issue_id || @next_issue_id 
 link_to_if @prev_issue_id,
                     "\xc2\xab #{l(:label_previous)}",
                     (@prev_issue_id ? issue_path(@prev_issue_id) : nil),
                     :title => "##{@prev_issue_id}",
                     :accesskey => accesskey(:previous) 
 if @issue_position && @issue_count 
 link_to_if @query_path,
                         l(:label_item_position, :position => @issue_position, :count => @issue_count),
                         @query_path 
 end 
 link_to_if @next_issue_id,
                     "#{l(:label_next)} \xc2\xbb",
                     (@next_issue_id ? issue_path(@next_issue_id) : nil),
                     :title => "##{@next_issue_id}",
                     :accesskey => accesskey(:next) 
 end 
 avatar(@issue.author, :size => "50", :title => l(:field_author)) 
 avatar(@issue.assigned_to, :size => "22", :class => "gravatar gravatar-child", :title => l(:field_assigned_to)) if @issue.assigned_to 
 render_issue_subject_with_tree(@issue) 
 authoring @issue.created_on, @issue.author 
 if @issue.created_on != @issue.updated_on 
 l(:label_updated_time, time_tag(@issue.updated_on)).html_safe 
 end 
 issue_fields_rows do |rows|
  rows.left l(:field_status), @issue.status.name, :class => 'status'
  rows.left l(:field_priority), @issue.priority.name, :class => 'priority'
  unless @issue.disabled_core_fields.include?('assigned_to_id')
    rows.left l(:field_assigned_to), (@issue.assigned_to ? link_to_user(@issue.assigned_to) : "-"), :class => 'assigned-to'
  end
  unless @issue.disabled_core_fields.include?('category_id') || (@issue.category.nil? && @issue.project.issue_categories.none?)
    rows.left l(:field_category), (@issue.category ? @issue.category.name : "-"), :class => 'category'
  end
  unless @issue.disabled_core_fields.include?('fixed_version_id') || (@issue.fixed_version.nil? && @issue.assignable_versions.none?)
    rows.left l(:field_fixed_version), (@issue.fixed_version ? link_to_version(@issue.fixed_version) : "-"), :class => 'fixed-version'
  end
  unless @issue.disabled_core_fields.include?('start_date')
    rows.right l(:field_start_date), format_date(@issue.start_date), :class => 'start-date'
  end
  unless @issue.disabled_core_fields.include?('due_date')
    rows.right l(:field_due_date), format_date(@issue.due_date), :class => 'due-date'
  end
  unless @issue.disabled_core_fields.include?('done_ratio')
    rows.right l(:field_done_ratio), progress_bar(@issue.done_ratio, :legend => "#{@issue.done_ratio}%"), :class => 'progress'
  end
  unless @issue.disabled_core_fields.include?('estimated_hours')
    rows.right l(:field_estimated_hours), issue_estimated_hours_details(@issue), :class => 'estimated-hours'
  end
  if User.current.allowed_to?(:view_time_entries, @project) && @issue.total_spent_hours > 0
    rows.right l(:label_spent_time), issue_spent_hours_details(@issue), :class => 'spent-time'
  end
end 
 render_half_width_custom_fields_rows(@issue) 
 call_hook(:view_issues_show_details_bottom, :issue => @issue) 
 if @issue.description? || @issue.attachments.any? 
 if @issue.description? 
 link_to l(:button_quote), quoted_issue_path(@issue), :remote => true, :method => 'post', :class => 'icon icon-comment' if @issue.notes_addable? 
l(:field_description)
 textilizable @issue, :description, :attachments => @issue.attachments 
 end 
 link_to_attachments @issue, :thumbnails => true 
 end 
 render_full_width_custom_fields_rows(@issue) 
 call_hook(:view_issues_show_description_bottom, :issue => @issue) 
 if !@issue.leaf? || User.current.allowed_to?(:manage_subtasks, @project) 
 link_to_new_subtask(@issue) if User.current.allowed_to?(:manage_subtasks, @project) 
l(:label_subtask_plural)
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 render_descendants_tree(@issue) unless @issue.leaf? 
 end 
 end 
 if @relations.present? || User.current.allowed_to?(:manage_issue_relations, @project) 
 render :partial => 'relations' 
 if User.current.allowed_to?(:manage_issue_relations, @project) 
 toggle_link l(:button_add), 'new-relation-form', {:focus => 'relation_issue_to_id'} 
 end 
l(:label_related_issues)
 if @relations.present? 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 render_issue_relations(@issue, @relations) 
 end 
 end 
 form_for @relation, {
                 :as => :relation, :remote => true,
                 :url => issue_relations_path(@issue),
                 :method => :post,
                 :html => {:id => 'new-relation-form', :style => 'display: none;'}
               } do |f| 
 render :partial => 'issue_relations/form', :locals => {:f => f}
 end 
 end 
 if @changesets.present? 
l(:label_associated_revisions)
 render :partial => 'changesets', :locals => { :changesets => @changesets} 
 changesets.each do |changeset| 
 link_to_revision(changeset, changeset.repository,
                            :text => "#{l(:label_revision)} #{changeset.format_identifier}") 
 if changeset.filechanges.any? && User.current.allowed_to?(:browse_repository, changeset.project) 
 link_to(l(:label_diff),
               :controller => 'repositories',
               :action => 'diff',
               :id     => changeset.project,
               :repository_id => changeset.repository.identifier_param,
               :path   => "",
               :rev    => changeset.identifier) 
 end 
 authoring(changeset.committed_on, changeset.author) 
 format_changeset_comments changeset 
 end 
 end 
 if @journals.present? 
l(:label_history)
 render :partial => 'history', :locals => { :issue => @issue, :journals => @journals } 
 reply_links = issue.notes_addable? 
 for journal in journals 
 journal.id 
 journal.css_classes 
 journal.indice 
 render_journal_actions(issue, journal, :reply_links => reply_links) 
 journal.indice 
 journal.indice 
 avatar(journal.user, :size => "24") 
 authoring journal.created_on, journal.user, :label => :label_updated_time_by 
 render_private_notes_indicator(journal) 
 if journal.details.any? 
 details_to_strings(journal.visible_details).each do |string| 
 string 
 end 
 if Setting.thumbnails_enabled? && (thumbnail_attachments = journal_thumbnail_attachments(journal)).any? 
 thumbnail_attachments.each do |attachment| 
 thumbnail_tag(attachment) 
 end 
 end 
 end 
 render_notes(issue, journal, :reply_links => reply_links) unless journal.notes.blank? 
 call_hook(:view_issues_history_journal_bottom, { :journal => journal }) 
 end 
 heads_for_wiki_formatter if User.current.allowed_to?(:edit_issue_notes, issue.project) || User.current.allowed_to?(:edit_own_issue_notes, issue.project) 
 end 
 render :partial => 'action_menu' 
 link_to l(:button_edit), edit_issue_path(@issue), :onclick => 'showAndScrollTo("update", "issue_notes"); return false;', :class => 'icon icon-edit', :accesskey => accesskey(:edit) if @issue.editable? 
 link_to l(:button_log_time), new_issue_time_entry_path(@issue), :class => 'icon icon-time-add' if User.current.allowed_to?(:log_time, @project) 
 watcher_link(@issue, User.current) 
 link_to l(:button_copy), project_copy_issue_path(@project, @issue), :class => 'icon icon-copy' if User.current.allowed_to?(:copy_issues, @project) && Issue.allowed_target_projects.any? 
 link_to l(:button_delete), issue_path(@issue), :data => {:confirm => issues_destroy_confirmation_message(@issue)}, :method => :delete, :class => 'icon icon-del' if @issue.deletable? 
 if @issue.editable? 
 l(:button_edit) 
 render :partial => 'edit' 
 labelled_form_for @issue, :html => {:id => 'issue-form', :multipart => true} do |f| 
 error_messages_for 'issue', 'time_entry' 
 render :partial => 'conflict' if @conflict 
 if @issue.attributes_editable? 
 l(:label_change_properties) 
 render :partial => 'form', :locals => {:f => f} 
 end 
 if User.current.allowed_to?(:log_time, @project) 
 l(:button_log_time) 
 labelled_fields_for :time_entry, @time_entry do |time_entry| 
 time_entry.hours_field :hours, :size => 6, :label => :label_spent_time 
 l(:field_hours) 
 time_entry.select :activity_id, activity_collection_for_select_options 
 time_entry.text_field :comments, :size => 60 
 @time_entry.custom_field_values.each do |value| 
 custom_field_tag_with_label :time_entry, value 
 end 
 end 
 end 
 if @issue.notes_addable? 
 l(:field_notes) 
 f.text_area :notes, :cols => 60, :rows => 10, :class => 'wiki-edit', :no_label => true 
 wikitoolbar_for 'issue_notes' 
 if @issue.safe_attribute? 'private_notes' 
 f.check_box :private_notes, :no_label => true 
 l(:field_private_notes) 
 end 
 call_hook(:view_issues_edit_notes_bottom, { :issue => @issue, :notes => @notes, :form => f }) 
 l(:label_attachment_plural) 
 if @issue.attachments.any? && @issue.safe_attribute?('deleted_attachment_ids') 
 link_to l(:label_edit_attachments), '#', :onclick => "$('#existing-attachments').toggle(); return false;" 
 @issue.deleted_attachment_ids.blank? ? 'display:none;' : '' 
 @issue.attachments.each do |attachment| 
 text_field_tag '', attachment.filename, :class => "icon icon-attachment filename", :disabled => true 
 check_box_tag 'issue[deleted_attachment_ids][]',
                                attachment.id,
                                @issue.deleted_attachment_ids.include?(attachment.id),
                                :id => nil, :class => "deleted_attachment" 
 l(:button_delete) 
 end 
 end 
 render :partial => 'attachments/form', :locals => {:container => @issue} 
 end 
 f.hidden_field :lock_version 
 hidden_field_tag 'last_journal_id', params[:last_journal_id] || @issue.last_journal_id 
 submit_tag l(:button_submit) 
 preview_link preview_edit_issue_path(:project_id => @project, :id => @issue), 'issue-form' 
 link_to l(:button_cancel), issue_path(id: @issue.id), :onclick => params[:action] == 'show' ? "$('#update').hide(); return false;" : '' 
 hidden_field_tag 'prev_issue_id', @prev_issue_id if @prev_issue_id 
 hidden_field_tag 'next_issue_id', @next_issue_id if @next_issue_id 
 hidden_field_tag 'issue_position', @issue_position if @issue_position 
 hidden_field_tag 'issue_count', @issue_count if @issue_count 
 end 
 end 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:key => User.current.rss_key} 
 f.link_to 'PDF' 
 end 
 html_title "#{@issue.tracker.name} ##{@issue.id}: #{@issue.subject}" 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 l(:label_issue_plural) 
 link_to l(:label_issue_view_all), _project_issues_path(@project, :set_filter => 1) 
 if @project 
 link_to l(:field_summary), project_issues_report_path(@project) 
 end 
 if User.current.allowed_to?(:import_issues, @project, :global => true) 
 link_to l(:button_import), new_issues_import_path 
 end 
 call_hook(:view_issues_sidebar_issues_bottom) 
 call_hook(:view_issues_sidebar_planning_bottom) 
 render_sidebar_queries(IssueQuery, @project) 
 call_hook(:view_issues_sidebar_queries_bottom) 
 if User.current.allowed_to?(:add_issue_watchers, @project) ||
    (@issue.watchers.present? && User.current.allowed_to?(:view_issue_watchers, @project)) 
 render :partial => 'watchers/watchers', :locals => {:watched => @issue} 
 end 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:format => 'atom', :key => User.current.rss_key}, :title => "#{@issue.project} - #{@issue.tracker} ##{@issue.id}: #{@issue.subject}") 
 end 
 context_menu 
      }
      format.api
      format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf  {
        send_file_headers! :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf"
      }
    end
  end
  def new
    respond_to do |format|
      format.html { render :action => 'new', :layout => !request.xhr? }
 title l(:label_issue_new) 
 call_hook(:view_issues_new_top, {:issue => @issue}) 
 labelled_form_for @issue, :url => _project_issues_path(@project),
                             :html => {:id => 'issue-form', :multipart => true} do |f| 
 error_messages_for 'issue' 
 hidden_field_tag 'copy_from', params[:copy_from] if params[:copy_from] 
 render :partial => 'issues/form', :locals => {:f => f} 
 if @copy_from && Setting.link_copied_issue == 'ask' 
 l(:label_link_copied_issue) 
 check_box_tag 'link_copy', '1', @link_copy 
 end 
 if @copy_from && @copy_from.attachments.any? 
 l(:label_copy_attachments) 
 check_box_tag 'copy_attachments', '1', @copy_attachments 
 end 
 if @copy_from && !@copy_from.leaf? 
 l(:label_copy_subtasks) 
 check_box_tag 'copy_subtasks', '1', @copy_subtasks 
 end 
 l(:label_attachment_plural) 
 render :partial => 'attachments/form', :locals => {:container => @issue} 
 render :partial => 'issues/watchers_form' 
 submit_tag l(:button_create) 
 submit_tag l(:button_create_and_continue), :name => 'continue' 
 preview_link preview_new_issue_path(:project_id => @issue.project), 'issue-form' 
 end 
 content_for :header_tags do 
 robot_exclusion_tag 
 end 
      format.js
    end
  end
  def create
    unless User.current.allowed_to?(:add_issues, @issue.project, :global => true)
      raise ::Unauthorized
    end
    call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    if @issue.save
      call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})
      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@issue)
          flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("##{@issue.id}", issue_path(@issue), :title => @issue.subject))
          redirect_after_create
        }
        format.api  { render :action => 'show', :status => :created, :location => issue_url(@issue) }
 render :partial => 'action_menu' 
 link_to l(:button_edit), edit_issue_path(@issue), :onclick => 'showAndScrollTo("update", "issue_notes"); return false;', :class => 'icon icon-edit', :accesskey => accesskey(:edit) if @issue.editable? 
 link_to l(:button_log_time), new_issue_time_entry_path(@issue), :class => 'icon icon-time-add' if User.current.allowed_to?(:log_time, @project) 
 watcher_link(@issue, User.current) 
 link_to l(:button_copy), project_copy_issue_path(@project, @issue), :class => 'icon icon-copy' if User.current.allowed_to?(:copy_issues, @project) && Issue.allowed_target_projects.any? 
 link_to l(:button_delete), issue_path(@issue), :data => {:confirm => issues_destroy_confirmation_message(@issue)}, :method => :delete, :class => 'icon icon-del' if @issue.deletable? 
 issue_heading(@issue) 
 @issue.css_classes 
 if @prev_issue_id || @next_issue_id 
 link_to_if @prev_issue_id,
                     "\xc2\xab #{l(:label_previous)}",
                     (@prev_issue_id ? issue_path(@prev_issue_id) : nil),
                     :title => "##{@prev_issue_id}",
                     :accesskey => accesskey(:previous) 
 if @issue_position && @issue_count 
 link_to_if @query_path,
                         l(:label_item_position, :position => @issue_position, :count => @issue_count),
                         @query_path 
 end 
 link_to_if @next_issue_id,
                     "#{l(:label_next)} \xc2\xbb",
                     (@next_issue_id ? issue_path(@next_issue_id) : nil),
                     :title => "##{@next_issue_id}",
                     :accesskey => accesskey(:next) 
 end 
 avatar(@issue.author, :size => "50", :title => l(:field_author)) 
 avatar(@issue.assigned_to, :size => "22", :class => "gravatar gravatar-child", :title => l(:field_assigned_to)) if @issue.assigned_to 
 render_issue_subject_with_tree(@issue) 
 authoring @issue.created_on, @issue.author 
 if @issue.created_on != @issue.updated_on 
 l(:label_updated_time, time_tag(@issue.updated_on)).html_safe 
 end 
 issue_fields_rows do |rows|
  rows.left l(:field_status), @issue.status.name, :class => 'status'
  rows.left l(:field_priority), @issue.priority.name, :class => 'priority'
  unless @issue.disabled_core_fields.include?('assigned_to_id')
    rows.left l(:field_assigned_to), (@issue.assigned_to ? link_to_user(@issue.assigned_to) : "-"), :class => 'assigned-to'
  end
  unless @issue.disabled_core_fields.include?('category_id') || (@issue.category.nil? && @issue.project.issue_categories.none?)
    rows.left l(:field_category), (@issue.category ? @issue.category.name : "-"), :class => 'category'
  end
  unless @issue.disabled_core_fields.include?('fixed_version_id') || (@issue.fixed_version.nil? && @issue.assignable_versions.none?)
    rows.left l(:field_fixed_version), (@issue.fixed_version ? link_to_version(@issue.fixed_version) : "-"), :class => 'fixed-version'
  end
  unless @issue.disabled_core_fields.include?('start_date')
    rows.right l(:field_start_date), format_date(@issue.start_date), :class => 'start-date'
  end
  unless @issue.disabled_core_fields.include?('due_date')
    rows.right l(:field_due_date), format_date(@issue.due_date), :class => 'due-date'
  end
  unless @issue.disabled_core_fields.include?('done_ratio')
    rows.right l(:field_done_ratio), progress_bar(@issue.done_ratio, :legend => "#{@issue.done_ratio}%"), :class => 'progress'
  end
  unless @issue.disabled_core_fields.include?('estimated_hours')
    rows.right l(:field_estimated_hours), issue_estimated_hours_details(@issue), :class => 'estimated-hours'
  end
  if User.current.allowed_to?(:view_time_entries, @project) && @issue.total_spent_hours > 0
    rows.right l(:label_spent_time), issue_spent_hours_details(@issue), :class => 'spent-time'
  end
end 
 render_half_width_custom_fields_rows(@issue) 
 call_hook(:view_issues_show_details_bottom, :issue => @issue) 
 if @issue.description? || @issue.attachments.any? 
 if @issue.description? 
 link_to l(:button_quote), quoted_issue_path(@issue), :remote => true, :method => 'post', :class => 'icon icon-comment' if @issue.notes_addable? 
l(:field_description)
 textilizable @issue, :description, :attachments => @issue.attachments 
 end 
 link_to_attachments @issue, :thumbnails => true 
 end 
 render_full_width_custom_fields_rows(@issue) 
 call_hook(:view_issues_show_description_bottom, :issue => @issue) 
 if !@issue.leaf? || User.current.allowed_to?(:manage_subtasks, @project) 
 link_to_new_subtask(@issue) if User.current.allowed_to?(:manage_subtasks, @project) 
l(:label_subtask_plural)
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 render_descendants_tree(@issue) unless @issue.leaf? 
 end 
 end 
 if @relations.present? || User.current.allowed_to?(:manage_issue_relations, @project) 
 render :partial => 'relations' 
 if User.current.allowed_to?(:manage_issue_relations, @project) 
 toggle_link l(:button_add), 'new-relation-form', {:focus => 'relation_issue_to_id'} 
 end 
l(:label_related_issues)
 if @relations.present? 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 render_issue_relations(@issue, @relations) 
 end 
 end 
 form_for @relation, {
                 :as => :relation, :remote => true,
                 :url => issue_relations_path(@issue),
                 :method => :post,
                 :html => {:id => 'new-relation-form', :style => 'display: none;'}
               } do |f| 
 render :partial => 'issue_relations/form', :locals => {:f => f}
 end 
 end 
 if @changesets.present? 
l(:label_associated_revisions)
 render :partial => 'changesets', :locals => { :changesets => @changesets} 
 changesets.each do |changeset| 
 link_to_revision(changeset, changeset.repository,
                            :text => "#{l(:label_revision)} #{changeset.format_identifier}") 
 if changeset.filechanges.any? && User.current.allowed_to?(:browse_repository, changeset.project) 
 link_to(l(:label_diff),
               :controller => 'repositories',
               :action => 'diff',
               :id     => changeset.project,
               :repository_id => changeset.repository.identifier_param,
               :path   => "",
               :rev    => changeset.identifier) 
 end 
 authoring(changeset.committed_on, changeset.author) 
 format_changeset_comments changeset 
 end 
 end 
 if @journals.present? 
l(:label_history)
 render :partial => 'history', :locals => { :issue => @issue, :journals => @journals } 
 reply_links = issue.notes_addable? 
 for journal in journals 
 journal.id 
 journal.css_classes 
 journal.indice 
 render_journal_actions(issue, journal, :reply_links => reply_links) 
 journal.indice 
 journal.indice 
 avatar(journal.user, :size => "24") 
 authoring journal.created_on, journal.user, :label => :label_updated_time_by 
 render_private_notes_indicator(journal) 
 if journal.details.any? 
 details_to_strings(journal.visible_details).each do |string| 
 string 
 end 
 if Setting.thumbnails_enabled? && (thumbnail_attachments = journal_thumbnail_attachments(journal)).any? 
 thumbnail_attachments.each do |attachment| 
 thumbnail_tag(attachment) 
 end 
 end 
 end 
 render_notes(issue, journal, :reply_links => reply_links) unless journal.notes.blank? 
 call_hook(:view_issues_history_journal_bottom, { :journal => journal }) 
 end 
 heads_for_wiki_formatter if User.current.allowed_to?(:edit_issue_notes, issue.project) || User.current.allowed_to?(:edit_own_issue_notes, issue.project) 
 end 
 render :partial => 'action_menu' 
 link_to l(:button_edit), edit_issue_path(@issue), :onclick => 'showAndScrollTo("update", "issue_notes"); return false;', :class => 'icon icon-edit', :accesskey => accesskey(:edit) if @issue.editable? 
 link_to l(:button_log_time), new_issue_time_entry_path(@issue), :class => 'icon icon-time-add' if User.current.allowed_to?(:log_time, @project) 
 watcher_link(@issue, User.current) 
 link_to l(:button_copy), project_copy_issue_path(@project, @issue), :class => 'icon icon-copy' if User.current.allowed_to?(:copy_issues, @project) && Issue.allowed_target_projects.any? 
 link_to l(:button_delete), issue_path(@issue), :data => {:confirm => issues_destroy_confirmation_message(@issue)}, :method => :delete, :class => 'icon icon-del' if @issue.deletable? 
 if @issue.editable? 
 l(:button_edit) 
 render :partial => 'edit' 
 labelled_form_for @issue, :html => {:id => 'issue-form', :multipart => true} do |f| 
 error_messages_for 'issue', 'time_entry' 
 render :partial => 'conflict' if @conflict 
 if @issue.attributes_editable? 
 l(:label_change_properties) 
 render :partial => 'form', :locals => {:f => f} 
 end 
 if User.current.allowed_to?(:log_time, @project) 
 l(:button_log_time) 
 labelled_fields_for :time_entry, @time_entry do |time_entry| 
 time_entry.hours_field :hours, :size => 6, :label => :label_spent_time 
 l(:field_hours) 
 time_entry.select :activity_id, activity_collection_for_select_options 
 time_entry.text_field :comments, :size => 60 
 @time_entry.custom_field_values.each do |value| 
 custom_field_tag_with_label :time_entry, value 
 end 
 end 
 end 
 if @issue.notes_addable? 
 l(:field_notes) 
 f.text_area :notes, :cols => 60, :rows => 10, :class => 'wiki-edit', :no_label => true 
 wikitoolbar_for 'issue_notes' 
 if @issue.safe_attribute? 'private_notes' 
 f.check_box :private_notes, :no_label => true 
 l(:field_private_notes) 
 end 
 call_hook(:view_issues_edit_notes_bottom, { :issue => @issue, :notes => @notes, :form => f }) 
 l(:label_attachment_plural) 
 if @issue.attachments.any? && @issue.safe_attribute?('deleted_attachment_ids') 
 link_to l(:label_edit_attachments), '#', :onclick => "$('#existing-attachments').toggle(); return false;" 
 @issue.deleted_attachment_ids.blank? ? 'display:none;' : '' 
 @issue.attachments.each do |attachment| 
 text_field_tag '', attachment.filename, :class => "icon icon-attachment filename", :disabled => true 
 check_box_tag 'issue[deleted_attachment_ids][]',
                                attachment.id,
                                @issue.deleted_attachment_ids.include?(attachment.id),
                                :id => nil, :class => "deleted_attachment" 
 l(:button_delete) 
 end 
 end 
 render :partial => 'attachments/form', :locals => {:container => @issue} 
 end 
 f.hidden_field :lock_version 
 hidden_field_tag 'last_journal_id', params[:last_journal_id] || @issue.last_journal_id 
 submit_tag l(:button_submit) 
 preview_link preview_edit_issue_path(:project_id => @project, :id => @issue), 'issue-form' 
 link_to l(:button_cancel), issue_path(id: @issue.id), :onclick => params[:action] == 'show' ? "$('#update').hide(); return false;" : '' 
 hidden_field_tag 'prev_issue_id', @prev_issue_id if @prev_issue_id 
 hidden_field_tag 'next_issue_id', @next_issue_id if @next_issue_id 
 hidden_field_tag 'issue_position', @issue_position if @issue_position 
 hidden_field_tag 'issue_count', @issue_count if @issue_count 
 end 
 end 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:key => User.current.rss_key} 
 f.link_to 'PDF' 
 end 
 html_title "#{@issue.tracker.name} ##{@issue.id}: #{@issue.subject}" 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 l(:label_issue_plural) 
 link_to l(:label_issue_view_all), _project_issues_path(@project, :set_filter => 1) 
 if @project 
 link_to l(:field_summary), project_issues_report_path(@project) 
 end 
 if User.current.allowed_to?(:import_issues, @project, :global => true) 
 link_to l(:button_import), new_issues_import_path 
 end 
 call_hook(:view_issues_sidebar_issues_bottom) 
 call_hook(:view_issues_sidebar_planning_bottom) 
 render_sidebar_queries(IssueQuery, @project) 
 call_hook(:view_issues_sidebar_queries_bottom) 
 if User.current.allowed_to?(:add_issue_watchers, @project) ||
    (@issue.watchers.present? && User.current.allowed_to?(:view_issue_watchers, @project)) 
 render :partial => 'watchers/watchers', :locals => {:watched => @issue} 
 end 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:format => 'atom', :key => User.current.rss_key}, :title => "#{@issue.project} - #{@issue.tracker} ##{@issue.id}: #{@issue.subject}") 
 end 
 context_menu 
      end
      return
    else
      respond_to do |format|
        format.html {
          if @issue.project.nil?
            render_error :status => 422
          else
            render :action => 'new'
 title l(:label_issue_new) 
 call_hook(:view_issues_new_top, {:issue => @issue}) 
 labelled_form_for @issue, :url => _project_issues_path(@project),
                             :html => {:id => 'issue-form', :multipart => true} do |f| 
 error_messages_for 'issue' 
 hidden_field_tag 'copy_from', params[:copy_from] if params[:copy_from] 
 render :partial => 'issues/form', :locals => {:f => f} 
 if @copy_from && Setting.link_copied_issue == 'ask' 
 l(:label_link_copied_issue) 
 check_box_tag 'link_copy', '1', @link_copy 
 end 
 if @copy_from && @copy_from.attachments.any? 
 l(:label_copy_attachments) 
 check_box_tag 'copy_attachments', '1', @copy_attachments 
 end 
 if @copy_from && !@copy_from.leaf? 
 l(:label_copy_subtasks) 
 check_box_tag 'copy_subtasks', '1', @copy_subtasks 
 end 
 l(:label_attachment_plural) 
 render :partial => 'attachments/form', :locals => {:container => @issue} 
 render :partial => 'issues/watchers_form' 
 submit_tag l(:button_create) 
 submit_tag l(:button_create_and_continue), :name => 'continue' 
 preview_link preview_new_issue_path(:project_id => @issue.project), 'issue-form' 
 end 
 content_for :header_tags do 
 robot_exclusion_tag 
 end 
          end
        }
        format.api  { render_validation_errors(@issue) }
      end
    end
  end
  def edit
    return unless update_issue_from_params
    respond_to do |format|
      format.html { }
      format.js
    end
  end
 "#{@issue.tracker_was} ##{@issue.id}" 
 render :partial => 'edit' 
 labelled_form_for @issue, :html => {:id => 'issue-form', :multipart => true} do |f| 
 error_messages_for 'issue', 'time_entry' 
 render :partial => 'conflict' if @conflict 
 if @issue.attributes_editable? 
 l(:label_change_properties) 
 render :partial => 'form', :locals => {:f => f} 
 end 
 if User.current.allowed_to?(:log_time, @project) 
 l(:button_log_time) 
 labelled_fields_for :time_entry, @time_entry do |time_entry| 
 time_entry.hours_field :hours, :size => 6, :label => :label_spent_time 
 l(:field_hours) 
 time_entry.select :activity_id, activity_collection_for_select_options 
 time_entry.text_field :comments, :size => 60 
 @time_entry.custom_field_values.each do |value| 
 custom_field_tag_with_label :time_entry, value 
 end 
 end 
 end 
 if @issue.notes_addable? 
 l(:field_notes) 
 f.text_area :notes, :cols => 60, :rows => 10, :class => 'wiki-edit', :no_label => true 
 wikitoolbar_for 'issue_notes' 
 if @issue.safe_attribute? 'private_notes' 
 f.check_box :private_notes, :no_label => true 
 l(:field_private_notes) 
 end 
 call_hook(:view_issues_edit_notes_bottom, { :issue => @issue, :notes => @notes, :form => f }) 
 l(:label_attachment_plural) 
 if @issue.attachments.any? && @issue.safe_attribute?('deleted_attachment_ids') 
 link_to l(:label_edit_attachments), '#', :onclick => "$('#existing-attachments').toggle(); return false;" 
 @issue.deleted_attachment_ids.blank? ? 'display:none;' : '' 
 @issue.attachments.each do |attachment| 
 text_field_tag '', attachment.filename, :class => "icon icon-attachment filename", :disabled => true 
 check_box_tag 'issue[deleted_attachment_ids][]',
                                attachment.id,
                                @issue.deleted_attachment_ids.include?(attachment.id),
                                :id => nil, :class => "deleted_attachment" 
 l(:button_delete) 
 end 
 end 
 render :partial => 'attachments/form', :locals => {:container => @issue} 
 end 
 f.hidden_field :lock_version 
 hidden_field_tag 'last_journal_id', params[:last_journal_id] || @issue.last_journal_id 
 submit_tag l(:button_submit) 
 preview_link preview_edit_issue_path(:project_id => @project, :id => @issue), 'issue-form' 
 link_to l(:button_cancel), issue_path(id: @issue.id), :onclick => params[:action] == 'show' ? "$('#update').hide(); return false;" : '' 
 hidden_field_tag 'prev_issue_id', @prev_issue_id if @prev_issue_id 
 hidden_field_tag 'next_issue_id', @next_issue_id if @next_issue_id 
 hidden_field_tag 'issue_position', @issue_position if @issue_position 
 hidden_field_tag 'issue_count', @issue_count if @issue_count 
 end 
 content_for :header_tags do 
 robot_exclusion_tag 
 end 
  def update
    return unless update_issue_from_params
    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    saved = false
    begin
      saved = save_issue_with_child_records
    rescue ActiveRecord::StaleObjectError
      @conflict = true
      if params[:last_journal_id]
        @conflict_journals = @issue.journals_after(params[:last_journal_id]).to_a
        @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
      end
    end
    if saved
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?
      respond_to do |format|
        format.html { redirect_back_or_default issue_path(@issue, previous_and_next_issue_ids_params) }
        format.api  { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
 "#{@issue.tracker_was} ##{@issue.id}" 
 render :partial => 'edit' 
 labelled_form_for @issue, :html => {:id => 'issue-form', :multipart => true} do |f| 
 error_messages_for 'issue', 'time_entry' 
 render :partial => 'conflict' if @conflict 
 if @issue.attributes_editable? 
 l(:label_change_properties) 
 render :partial => 'form', :locals => {:f => f} 
 end 
 if User.current.allowed_to?(:log_time, @project) 
 l(:button_log_time) 
 labelled_fields_for :time_entry, @time_entry do |time_entry| 
 time_entry.hours_field :hours, :size => 6, :label => :label_spent_time 
 l(:field_hours) 
 time_entry.select :activity_id, activity_collection_for_select_options 
 time_entry.text_field :comments, :size => 60 
 @time_entry.custom_field_values.each do |value| 
 custom_field_tag_with_label :time_entry, value 
 end 
 end 
 end 
 if @issue.notes_addable? 
 l(:field_notes) 
 f.text_area :notes, :cols => 60, :rows => 10, :class => 'wiki-edit', :no_label => true 
 wikitoolbar_for 'issue_notes' 
 if @issue.safe_attribute? 'private_notes' 
 f.check_box :private_notes, :no_label => true 
 l(:field_private_notes) 
 end 
 call_hook(:view_issues_edit_notes_bottom, { :issue => @issue, :notes => @notes, :form => f }) 
 l(:label_attachment_plural) 
 if @issue.attachments.any? && @issue.safe_attribute?('deleted_attachment_ids') 
 link_to l(:label_edit_attachments), '#', :onclick => "$('#existing-attachments').toggle(); return false;" 
 @issue.deleted_attachment_ids.blank? ? 'display:none;' : '' 
 @issue.attachments.each do |attachment| 
 text_field_tag '', attachment.filename, :class => "icon icon-attachment filename", :disabled => true 
 check_box_tag 'issue[deleted_attachment_ids][]',
                                attachment.id,
                                @issue.deleted_attachment_ids.include?(attachment.id),
                                :id => nil, :class => "deleted_attachment" 
 l(:button_delete) 
 end 
 end 
 render :partial => 'attachments/form', :locals => {:container => @issue} 
 end 
 f.hidden_field :lock_version 
 hidden_field_tag 'last_journal_id', params[:last_journal_id] || @issue.last_journal_id 
 submit_tag l(:button_submit) 
 preview_link preview_edit_issue_path(:project_id => @project, :id => @issue), 'issue-form' 
 link_to l(:button_cancel), issue_path(id: @issue.id), :onclick => params[:action] == 'show' ? "$('#update').hide(); return false;" : '' 
 hidden_field_tag 'prev_issue_id', @prev_issue_id if @prev_issue_id 
 hidden_field_tag 'next_issue_id', @next_issue_id if @next_issue_id 
 hidden_field_tag 'issue_position', @issue_position if @issue_position 
 hidden_field_tag 'issue_count', @issue_count if @issue_count 
 end 
 content_for :header_tags do 
 robot_exclusion_tag 
 end 
        format.api  { render_validation_errors(@issue) }
      end
    end
  end
  def bulk_edit
    @issues.sort!
    @copy = params[:copy].present?
    @notes = params[:notes]
    if @copy
      unless User.current.allowed_to?(:copy_issues, @projects)
        raise ::Unauthorized
      end
    else
      unless @issues.all?(&:attributes_editable?)
        raise ::Unauthorized
      end
    end
    edited_issues = Issue.where(:id => @issues.map(&:id)).to_a
    @values_by_custom_field = {}
    edited_issues.each do |issue|
      issue.custom_field_values.each do |c|
        if c.value_present?
          @values_by_custom_field[c.custom_field] ||= []
          @values_by_custom_field[c.custom_field] << issue.id
        end
      end
    end
    @allowed_projects = Issue.allowed_target_projects
    if params[:issue]
      @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:issue][:project_id].to_s}
      if @target_project
        target_projects = [@target_project]
        edited_issues.each {|issue| issue.project = @target_project}
      end
    end
    target_projects ||= @projects
    @trackers = target_projects.map {|p| Issue.allowed_target_trackers(p) }.reduce(:&)
    if params[:issue]
      @target_tracker = @trackers.detect {|t| t.id.to_s == params[:issue][:tracker_id].to_s}
      if @target_tracker
        edited_issues.each {|issue| issue.tracker = @target_tracker}
      end
    end
    if @copy
      @available_statuses = []
    else
      @available_statuses = edited_issues.map(&:new_statuses_allowed_to).reduce(:&)
    end
    if params[:issue]
      @target_status = @available_statuses.detect {|t| t.id.to_s == params[:issue][:status_id].to_s}
      if @target_status
        edited_issues.each {|issue| issue.status = @target_status}
      end
    end
    edited_issues.each do |issue|
      issue.custom_field_values.each do |c|
        if c.value_present? && @values_by_custom_field[c.custom_field]
          @values_by_custom_field[c.custom_field].delete(issue.id)
        end
      end
    end
    @values_by_custom_field.delete_if {|k,v| v.blank?}
    @custom_fields = edited_issues.map{|i|i.editable_custom_fields}.reduce(:&).select {|field| field.format.bulk_edit_supported}
    @assignables = target_projects.map(&:assignable_users).reduce(:&)
    @versions = target_projects.map {|p| p.shared_versions.open}.reduce(:&)
    @categories = target_projects.map {|p| p.issue_categories}.reduce(:&)
    if @copy
      @attachments_present = @issues.detect {|i| i.attachments.any?}.present?
      @subtasks_present = @issues.detect {|i| !i.leaf?}.present?
      @watchers_present = User.current.allowed_to?(:add_issue_watchers, @projects) && Watcher.where(:watchable_type => 'Issue', :watchable_id => @issues.map(&:id)).exists?
    end
    @safe_attributes = edited_issues.map(&:safe_attribute_names).reduce(:&)
    @issue_params = params[:issue] || {}
    @issue_params[:custom_field_values] ||= {}
  end
 @copy ? l(:button_copy) : l(:label_bulk_edit_selected_issues) 
 if @saved_issues && @unsaved_issues.present? 
 l(:notice_failed_to_save_issues,
        :count => @unsaved_issues.size,
        :total => @saved_issues.size,
        :ids => @unsaved_issues.map {|i| "##{i.id}"}.join(', ')) 
 bulk_edit_error_messages(@unsaved_issues).each do |message| 
 message 
 end 
 end 
 @issues.each do |issue| 
 content_tag 'li', link_to_issue(issue) 
 end 
 form_tag(bulk_update_issues_path, :id => 'bulk_edit_form') do 
 @issues.collect {|i| hidden_field_tag('ids[]', i.id, :id => nil)}.join("\n").html_safe 
 l(:label_change_properties) 
 if @allowed_projects.present? 
 l(:field_project) 
 select_tag('issue[project_id]',
                 project_tree_options_for_select(@allowed_projects,
                   :include_blank => ((!@copy || (@projects & @allowed_projects == @projects)) ? l(:label_no_change_option) : false),
                   :selected => @target_project),
                 :onchange => "updateBulkEditFrom('#{escape_javascript url_for(:action => 'bulk_edit', :format => 'js')}')") 
 end 
 l(:field_tracker) 
 select_tag('issue[tracker_id]',
                 content_tag('option', l(:label_no_change_option), :value => '') +
                   options_from_collection_for_select(@trackers, :id, :name, @issue_params[:tracker_id]),
                   :onchange => "updateBulkEditFrom('#{escape_javascript url_for(:action => 'bulk_edit', :format => 'js')}')") 
 if @available_statuses.any? 
 l(:field_status) 
 select_tag('issue[status_id]',
                 content_tag('option', l(:label_no_change_option), :value => '') +
                   options_from_collection_for_select(@available_statuses, :id, :name, @issue_params[:status_id]),
                   :onchange => "updateBulkEditFrom('#{escape_javascript url_for(:action => 'bulk_edit', :format => 'js')}')") 
 end 
 if @safe_attributes.include?('priority_id') 
 l(:field_priority) 
 select_tag('issue[priority_id]',
                 content_tag('option', l(:label_no_change_option), :value => '') +
                   options_from_collection_for_select(IssuePriority.active, :id, :name, @issue_params[:priority_id])) 
 end 
 if @safe_attributes.include?('assigned_to_id') 
 l(:field_assigned_to) 
 select_tag('issue[assigned_to_id]',
                 content_tag('option', l(:label_no_change_option), :value => '') +
                   content_tag('option', l(:label_nobody), :value => 'none', :selected => (@issue_params[:assigned_to_id] == 'none')) +
                   principals_options_for_select(@assignables, @issue_params[:assigned_to_id])) 
 end 
 if @safe_attributes.include?('category_id') 
 l(:field_category) 
 select_tag('issue[category_id]', content_tag('option', l(:label_no_change_option), :value => '') +
                                content_tag('option', l(:label_none), :value => 'none', :selected => (@issue_params[:category_id] == 'none')) +
                                options_from_collection_for_select(@categories, :id, :name, @issue_params[:category_id])) 
 end 
 if @safe_attributes.include?('fixed_version_id') 
 l(:field_fixed_version) 
 select_tag('issue[fixed_version_id]', content_tag('option', l(:label_no_change_option), :value => '') +
                                   content_tag('option', l(:label_none), :value => 'none', :selected => (@issue_params[:fixed_version_id] == 'none')) +
                                   version_options_for_select(@versions.sort, @issue_params[:fixed_version_id])) 
 end 
 @custom_fields.each do |custom_field| 
 custom_field.name 
 custom_field_tag_for_bulk_edit('issue', custom_field, @issues, @issue_params[:custom_field_values][custom_field.id.to_s]) 
 end 
 if @copy && Setting.link_copied_issue == 'ask' 
 l(:label_link_copied_issue) 
 hidden_field_tag 'link_copy', '0' 
 check_box_tag 'link_copy', '1', params[:link_copy] != 0 
 end 
 if @copy && (@attachments_present || @subtasks_present || @watchers_present) 
 l(:button_copy) 
 if @attachments_present 
 hidden_field_tag 'copy_attachments', '0' 
 check_box_tag 'copy_attachments', '1', params[:copy_attachments] != '0' 
 l(:label_attachment_plural) 
 end 
 if @subtasks_present 
 hidden_field_tag 'copy_subtasks', '0' 
 check_box_tag 'copy_subtasks', '1', params[:copy_subtasks] != '0' 
 l(:label_subtask_plural) 
 end 
 if @watchers_present 
 hidden_field_tag 'copy_watchers', '0' 
 check_box_tag 'copy_watchers', '1',  params[:copy_watchers] != '0' 
 l(:label_issue_watchers) 
 end 
 end 
 call_hook(:view_issues_bulk_edit_details_bottom, { :issues => @issues }) 
 if @safe_attributes.include?('is_private') 
 l(:field_is_private) 
 select_tag('issue[is_private]', content_tag('option', l(:label_no_change_option), :value => '') +
                                content_tag('option', l(:general_text_Yes), :value => '1', :selected => (@issue_params[:is_private] == '1')) +
                                content_tag('option', l(:general_text_No), :value => '0', :selected => (@issue_params[:is_private] == '0'))) 
 end 
 if @safe_attributes.include?('parent_issue_id') && @project 
 l(:field_parent_issue) 
 text_field_tag 'issue[parent_issue_id]', '', :size => 10, :value => @issue_params[:parent_issue_id] 
 check_box_tag 'issue[parent_issue_id]', 'none', (@issue_params[:parent_issue_id] == 'none'), :id => nil, :data => {:disables => '#issue_parent_issue_id'} 
 l(:button_clear) 
 javascript_tag "observeAutocompleteField('issue_parent_issue_id', '#{escape_javascript auto_complete_issues_path(:project_id => @project, :scope => Setting.cross_project_subtasks)}')" 
 end 
 if @safe_attributes.include?('start_date') 
 l(:field_start_date) 
 date_field_tag 'issue[start_date]', '', :value => @issue_params[:start_date], :size => 10 
 calendar_for('issue_start_date') 
 check_box_tag 'issue[start_date]', 'none', (@issue_params[:start_date] == 'none'), :id => nil, :data => {:disables => '#issue_start_date'} 
 l(:button_clear) 
 end 
 if @safe_attributes.include?('due_date') 
 l(:field_due_date) 
 date_field_tag 'issue[due_date]', '', :value => @issue_params[:due_date], :size => 10 
 calendar_for('issue_due_date') 
 check_box_tag 'issue[due_date]', 'none', (@issue_params[:due_date] == 'none'), :id => nil, :data => {:disables => '#issue_due_date'} 
 l(:button_clear) 
 end 
 if @safe_attributes.include?('estimated_hours') 
 l(:field_estimated_hours) 
 text_field_tag 'issue[estimated_hours]', '', :value => @issue_params[:estimated_hours], :size => 10 
 check_box_tag 'issue[estimated_hours]', 'none', (@issue_params[:estimated_hours] == 'none'), :id => nil, :data => {:disables => '#issue_estimated_hours'} 
 l(:button_clear) 
 end 
 if @safe_attributes.include?('done_ratio') && Issue.use_field_for_done_ratio? 
 l(:field_done_ratio) 
 select_tag 'issue[done_ratio]', options_for_select([[l(:label_no_change_option), '']] + (0..10).to_a.collect {|r| ["#{r*10} %", r*10] }, @issue_params[:done_ratio]) 
 end 
 l(:field_notes) 
 text_area_tag 'notes', @notes, :cols => 60, :rows => 10, :class => 'wiki-edit' 
 wikitoolbar_for 'notes' 
 if @values_by_custom_field.present? 
 l(:warning_fields_cleared_on_bulk_edit) 
 safe_join(@values_by_custom_field.map {|field, ids| content_tag "span", "#{field.name} (#{ids.size})"}, ', ') 
 end 
 if @copy 
 hidden_field_tag 'copy', '1' 
 submit_tag l(:button_copy) 
 submit_tag l(:button_copy_and_follow), :name => 'follow' 
 elsif @target_project 
 submit_tag l(:button_move) 
 submit_tag l(:button_move_and_follow), :name => 'follow' 
 else 
 submit_tag l(:button_submit) 
 end 
 end 
 javascript_tag do 
 end 
  def bulk_update
    @issues.sort!
    @copy = params[:copy].present?
    attributes = parse_params_for_bulk_update(params[:issue])
    copy_subtasks = (params[:copy_subtasks] == '1')
    copy_attachments = (params[:copy_attachments] == '1')
    copy_watchers = (params[:copy_watchers] == '1')
    if @copy
      unless User.current.allowed_to?(:copy_issues, @projects)
        raise ::Unauthorized
      end
      target_projects = @projects
      if attributes['project_id'].present?
        target_projects = Project.where(:id => attributes['project_id']).to_a
      end
      unless User.current.allowed_to?(:add_issues, target_projects)
        raise ::Unauthorized
      end
      unless User.current.allowed_to?(:add_issue_watchers, @projects)
        copy_watchers = false
      end
    else
      unless @issues.all?(&:attributes_editable?)
        raise ::Unauthorized
      end
    end
    unsaved_issues = []
    saved_issues = []
    if @copy && copy_subtasks
      @issues.reject! {|issue| @issues.detect {|other| issue.is_descendant_of?(other)}}
    end
    @issues.each do |orig_issue|
      orig_issue.reload
      if @copy
        issue = orig_issue.copy({},
          :attachments => copy_attachments,
          :subtasks => copy_subtasks,
          :watchers => copy_watchers,
          :link => link_copy?(params[:link_copy])
        )
      else
        issue = orig_issue
      end
      journal = issue.init_journal(User.current, params[:notes])
      issue.safe_attributes = attributes
      call_hook(:controller_issues_bulk_edit_before_save, { :params => params, :issue => issue })
      if issue.save
        saved_issues << issue
      else
        unsaved_issues << orig_issue
      end
    end
    if unsaved_issues.empty?
      flash[:notice] = l(:notice_successful_update) unless saved_issues.empty?
      if params[:follow]
        if @issues.size == 1 && saved_issues.size == 1
          redirect_to issue_path(saved_issues.first)
        elsif saved_issues.map(&:project).uniq.size == 1
          redirect_to project_issues_path(saved_issues.map(&:project).first)
        end
      else
        redirect_back_or_default _project_issues_path(@project)
      end
    else
      @saved_issues = @issues
      @unsaved_issues = unsaved_issues
      @issues = Issue.visible.where(:id => @unsaved_issues.map(&:id)).to_a
      bulk_edit
      render :action => 'bulk_edit'
 @copy ? l(:button_copy) : l(:label_bulk_edit_selected_issues) 
 if @saved_issues && @unsaved_issues.present? 
 l(:notice_failed_to_save_issues,
        :count => @unsaved_issues.size,
        :total => @saved_issues.size,
        :ids => @unsaved_issues.map {|i| "##{i.id}"}.join(', ')) 
 bulk_edit_error_messages(@unsaved_issues).each do |message| 
 message 
 end 
 end 
 @issues.each do |issue| 
 content_tag 'li', link_to_issue(issue) 
 end 
 form_tag(bulk_update_issues_path, :id => 'bulk_edit_form') do 
 @issues.collect {|i| hidden_field_tag('ids[]', i.id, :id => nil)}.join("\n").html_safe 
 l(:label_change_properties) 
 if @allowed_projects.present? 
 l(:field_project) 
 select_tag('issue[project_id]',
                 project_tree_options_for_select(@allowed_projects,
                   :include_blank => ((!@copy || (@projects & @allowed_projects == @projects)) ? l(:label_no_change_option) : false),
                   :selected => @target_project),
                 :onchange => "updateBulkEditFrom('#{escape_javascript url_for(:action => 'bulk_edit', :format => 'js')}')") 
 end 
 l(:field_tracker) 
 select_tag('issue[tracker_id]',
                 content_tag('option', l(:label_no_change_option), :value => '') +
                   options_from_collection_for_select(@trackers, :id, :name, @issue_params[:tracker_id]),
                   :onchange => "updateBulkEditFrom('#{escape_javascript url_for(:action => 'bulk_edit', :format => 'js')}')") 
 if @available_statuses.any? 
 l(:field_status) 
 select_tag('issue[status_id]',
                 content_tag('option', l(:label_no_change_option), :value => '') +
                   options_from_collection_for_select(@available_statuses, :id, :name, @issue_params[:status_id]),
                   :onchange => "updateBulkEditFrom('#{escape_javascript url_for(:action => 'bulk_edit', :format => 'js')}')") 
 end 
 if @safe_attributes.include?('priority_id') 
 l(:field_priority) 
 select_tag('issue[priority_id]',
                 content_tag('option', l(:label_no_change_option), :value => '') +
                   options_from_collection_for_select(IssuePriority.active, :id, :name, @issue_params[:priority_id])) 
 end 
 if @safe_attributes.include?('assigned_to_id') 
 l(:field_assigned_to) 
 select_tag('issue[assigned_to_id]',
                 content_tag('option', l(:label_no_change_option), :value => '') +
                   content_tag('option', l(:label_nobody), :value => 'none', :selected => (@issue_params[:assigned_to_id] == 'none')) +
                   principals_options_for_select(@assignables, @issue_params[:assigned_to_id])) 
 end 
 if @safe_attributes.include?('category_id') 
 l(:field_category) 
 select_tag('issue[category_id]', content_tag('option', l(:label_no_change_option), :value => '') +
                                content_tag('option', l(:label_none), :value => 'none', :selected => (@issue_params[:category_id] == 'none')) +
                                options_from_collection_for_select(@categories, :id, :name, @issue_params[:category_id])) 
 end 
 if @safe_attributes.include?('fixed_version_id') 
 l(:field_fixed_version) 
 select_tag('issue[fixed_version_id]', content_tag('option', l(:label_no_change_option), :value => '') +
                                   content_tag('option', l(:label_none), :value => 'none', :selected => (@issue_params[:fixed_version_id] == 'none')) +
                                   version_options_for_select(@versions.sort, @issue_params[:fixed_version_id])) 
 end 
 @custom_fields.each do |custom_field| 
 custom_field.name 
 custom_field_tag_for_bulk_edit('issue', custom_field, @issues, @issue_params[:custom_field_values][custom_field.id.to_s]) 
 end 
 if @copy && Setting.link_copied_issue == 'ask' 
 l(:label_link_copied_issue) 
 hidden_field_tag 'link_copy', '0' 
 check_box_tag 'link_copy', '1', params[:link_copy] != 0 
 end 
 if @copy && (@attachments_present || @subtasks_present || @watchers_present) 
 l(:button_copy) 
 if @attachments_present 
 hidden_field_tag 'copy_attachments', '0' 
 check_box_tag 'copy_attachments', '1', params[:copy_attachments] != '0' 
 l(:label_attachment_plural) 
 end 
 if @subtasks_present 
 hidden_field_tag 'copy_subtasks', '0' 
 check_box_tag 'copy_subtasks', '1', params[:copy_subtasks] != '0' 
 l(:label_subtask_plural) 
 end 
 if @watchers_present 
 hidden_field_tag 'copy_watchers', '0' 
 check_box_tag 'copy_watchers', '1',  params[:copy_watchers] != '0' 
 l(:label_issue_watchers) 
 end 
 end 
 call_hook(:view_issues_bulk_edit_details_bottom, { :issues => @issues }) 
 if @safe_attributes.include?('is_private') 
 l(:field_is_private) 
 select_tag('issue[is_private]', content_tag('option', l(:label_no_change_option), :value => '') +
                                content_tag('option', l(:general_text_Yes), :value => '1', :selected => (@issue_params[:is_private] == '1')) +
                                content_tag('option', l(:general_text_No), :value => '0', :selected => (@issue_params[:is_private] == '0'))) 
 end 
 if @safe_attributes.include?('parent_issue_id') && @project 
 l(:field_parent_issue) 
 text_field_tag 'issue[parent_issue_id]', '', :size => 10, :value => @issue_params[:parent_issue_id] 
 check_box_tag 'issue[parent_issue_id]', 'none', (@issue_params[:parent_issue_id] == 'none'), :id => nil, :data => {:disables => '#issue_parent_issue_id'} 
 l(:button_clear) 
 javascript_tag "observeAutocompleteField('issue_parent_issue_id', '#{escape_javascript auto_complete_issues_path(:project_id => @project, :scope => Setting.cross_project_subtasks)}')" 
 end 
 if @safe_attributes.include?('start_date') 
 l(:field_start_date) 
 date_field_tag 'issue[start_date]', '', :value => @issue_params[:start_date], :size => 10 
 calendar_for('issue_start_date') 
 check_box_tag 'issue[start_date]', 'none', (@issue_params[:start_date] == 'none'), :id => nil, :data => {:disables => '#issue_start_date'} 
 l(:button_clear) 
 end 
 if @safe_attributes.include?('due_date') 
 l(:field_due_date) 
 date_field_tag 'issue[due_date]', '', :value => @issue_params[:due_date], :size => 10 
 calendar_for('issue_due_date') 
 check_box_tag 'issue[due_date]', 'none', (@issue_params[:due_date] == 'none'), :id => nil, :data => {:disables => '#issue_due_date'} 
 l(:button_clear) 
 end 
 if @safe_attributes.include?('estimated_hours') 
 l(:field_estimated_hours) 
 text_field_tag 'issue[estimated_hours]', '', :value => @issue_params[:estimated_hours], :size => 10 
 check_box_tag 'issue[estimated_hours]', 'none', (@issue_params[:estimated_hours] == 'none'), :id => nil, :data => {:disables => '#issue_estimated_hours'} 
 l(:button_clear) 
 end 
 if @safe_attributes.include?('done_ratio') && Issue.use_field_for_done_ratio? 
 l(:field_done_ratio) 
 select_tag 'issue[done_ratio]', options_for_select([[l(:label_no_change_option), '']] + (0..10).to_a.collect {|r| ["#{r*10} %", r*10] }, @issue_params[:done_ratio]) 
 end 
 l(:field_notes) 
 text_area_tag 'notes', @notes, :cols => 60, :rows => 10, :class => 'wiki-edit' 
 wikitoolbar_for 'notes' 
 if @values_by_custom_field.present? 
 l(:warning_fields_cleared_on_bulk_edit) 
 safe_join(@values_by_custom_field.map {|field, ids| content_tag "span", "#{field.name} (#{ids.size})"}, ', ') 
 end 
 if @copy 
 hidden_field_tag 'copy', '1' 
 submit_tag l(:button_copy) 
 submit_tag l(:button_copy_and_follow), :name => 'follow' 
 elsif @target_project 
 submit_tag l(:button_move) 
 submit_tag l(:button_move_and_follow), :name => 'follow' 
 else 
 submit_tag l(:button_submit) 
 end 
 end 
 javascript_tag do 
 end 
    end
  end
  def destroy
    raise Unauthorized unless @issues.all?(&:deletable?)
    issues_and_descendants_ids = Issue.self_and_descendants(@issues).pluck(:id)
    time_entries = TimeEntry.where(:issue_id => issues_and_descendants_ids)
    @hours = time_entries.sum(:hours).to_f
    if @hours > 0
      case params[:todo]
      when 'destroy'
      when 'nullify'
        if Setting.timelog_required_fields.include?('issue_id')
          flash.now[:error] = l(:field_issue) + " " + ::I18n.t('activerecord.errors.messages.blank')
          return
        else
        time_entries.update_all(:issue_id => nil)
        end
      when 'reassign'
        reassign_to = @project && @project.issues.find_by_id(params[:reassign_to_id])
        if reassign_to.nil?
          flash.now[:error] = l(:error_issue_not_found_in_project)
          return
        elsif issues_and_descendants_ids.include?(reassign_to.id)
          flash.now[:error] = l(:error_cannot_reassign_time_entries_to_an_issue_about_to_be_deleted)
          return
        else
          time_entries.update_all(:issue_id => reassign_to.id, :project_id => reassign_to.project_id)
        end
      else
        return unless api_request?
      end
    end
    @issues.each do |issue|
      begin
        issue.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default _project_issues_path(@project) }
      format.api  { render_api_ok }
    end
  end
 l(:label_confirmation) 
 form_tag({}, :method => :delete)  do 
 @issues.collect {|i| hidden_field_tag('ids[]', i.id, :id => nil)}.join("\n").html_safe 
 l(:text_destroy_time_entries_question, :hours => number_with_precision(@hours, :precision => 2)) 
 radio_button_tag 'todo', 'destroy', true 
 l(:text_destroy_time_entries) 
 unless Setting.timelog_required_fields.include?('issue_id') 
 radio_button_tag 'todo', 'nullify', false 
 l(:text_assign_time_entries_to_project) 
 end 
 if @project 
 radio_button_tag 'todo', 'reassign', false, :onchange => 'if (this.checked) { $("#reassign_to_id").focus(); }' 
 l(:text_reassign_time_entries) 
 text_field_tag 'reassign_to_id', params[:reassign_to_id], :size => 6, :onfocus => '$("#todo_reassign").attr("checked", true);' 
 javascript_tag "observeAutocompleteField('reassign_to_id', '#{escape_javascript auto_complete_issues_path(:project_id => @project)}')" 
 end 
 submit_tag l(:button_apply) 
 end 
  def current_menu_item
    if Setting.new_item_menu_tab == '1' && [:new, :create].include?(action_name.to_sym)
      :new_issue
    else
      super
    end
  end
  private
  def retrieve_previous_and_next_issue_ids
    if params[:prev_issue_id].present? || params[:next_issue_id].present?
      @prev_issue_id = params[:prev_issue_id].presence.try(:to_i)
      @next_issue_id = params[:next_issue_id].presence.try(:to_i)
      @issue_position = params[:issue_position].presence.try(:to_i)
      @issue_count = params[:issue_count].presence.try(:to_i)
    else
      retrieve_query_from_session
      if @query
        @per_page = per_page_option
        limit = 500
        issue_ids = @query.issue_ids(:limit => (limit + 1))
        if (idx = issue_ids.index(@issue.id)) && idx < limit
          if issue_ids.size < 500
            @issue_position = idx + 1
            @issue_count = issue_ids.size
          end
          @prev_issue_id = issue_ids[idx - 1] if idx > 0
          @next_issue_id = issue_ids[idx + 1] if idx < (issue_ids.size - 1)
        end
        query_params = @query.as_params
        if @issue_position
          query_params = query_params.merge(:page => (@issue_position / per_page_option) + 1, :per_page => per_page_option)
        end
        @query_path = _project_issues_path(@query.project, query_params)
      end
    end
  end
  def previous_and_next_issue_ids_params
    {
      :prev_issue_id => params[:prev_issue_id],
      :next_issue_id => params[:next_issue_id],
      :issue_position => params[:issue_position],
      :issue_count => params[:issue_count]
    }.reject {|k,v| k.blank?}
  end
  def update_issue_from_params
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    if params[:time_entry]
      @time_entry.safe_attributes = params[:time_entry]
    end
    @issue.init_journal(User.current)
    issue_attributes = params[:issue]
    if issue_attributes && params[:conflict_resolution]
      case params[:conflict_resolution]
      when 'overwrite'
        issue_attributes = issue_attributes.dup
        issue_attributes.delete(:lock_version)
      when 'add_notes'
        issue_attributes = issue_attributes.slice(:notes, :private_notes)
      when 'cancel'
        redirect_to issue_path(@issue)
        return false
      end
    end
    @issue.safe_attributes = issue_attributes
    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    true
  end
  def build_new_issue_from_params
    @issue = Issue.new
    if params[:copy_from]
      begin
        @issue.init_journal(User.current)
        @copy_from = Issue.visible.find(params[:copy_from])
        unless User.current.allowed_to?(:copy_issues, @copy_from.project)
          raise ::Unauthorized
        end
        @link_copy = link_copy?(params[:link_copy]) || request.get?
        @copy_attachments = params[:copy_attachments].present? || request.get?
        @copy_subtasks = params[:copy_subtasks].present? || request.get?
        @copy_watchers = User.current.allowed_to?(:add_issue_watchers, @project)
        @issue.copy_from(@copy_from, :attachments => @copy_attachments, :subtasks => @copy_subtasks, :watchers => @copy_watchers, :link => @link_copy)
        @issue.parent_issue_id = @copy_from.parent_id
      rescue ActiveRecord::RecordNotFound
        render_404
        return
      end
    end
    @issue.project = @project
    if request.get?
      @issue.project ||= @issue.allowed_target_projects.first
    end
    @issue.author ||= User.current
    @issue.start_date ||= User.current.today if Setting.default_issue_start_date_to_creation_date?
    attrs = (params[:issue] || {}).deep_dup
    if action_name == 'new' && params[:was_default_status] == attrs[:status_id]
      attrs.delete(:status_id)
    end
    if action_name == 'new' && params[:form_update_triggered_by] == 'issue_project_id'
      attrs.delete(:fixed_version_id)
    end
    @issue.safe_attributes = attrs
    if @issue.project
      @issue.tracker ||= @issue.allowed_target_trackers.first
      if @issue.tracker.nil?
        if @issue.project.trackers.any?
          render_error :message => l(:error_no_tracker_allowed_for_new_issue_in_project), :status => 403
        else
          render_error l(:error_no_tracker_in_project)
        end
        return false
      end
      if @issue.status.nil?
        render_error l(:error_no_default_issue_status)
        return false
      end
    elsif request.get?
      render_error :message => l(:error_no_projects_with_tracker_allowed_for_new_issue), :status => 403
      return false
    end
    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
  end
  def save_issue_with_child_records
    Issue.transaction do
      if params[:time_entry] && (params[:time_entry][:hours].present? || params[:time_entry][:comments].present?) && User.current.allowed_to?(:log_time, @issue.project)
        time_entry = @time_entry || TimeEntry.new
        time_entry.project = @issue.project
        time_entry.issue = @issue
        time_entry.user = User.current
        time_entry.spent_on = User.current.today
        time_entry.safe_attributes = params[:time_entry]
        @issue.time_entries << time_entry
      end
      call_hook(:controller_issues_edit_before_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
      if @issue.save
        call_hook(:controller_issues_edit_after_save, { :params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
      else
        raise ActiveRecord::Rollback
      end
    end
  end
  def link_copy?(param)
    case Setting.link_copied_issue
    when 'yes'
      true
    when 'no'
      false
    when 'ask'
      param == '1'
    end
  end
  def redirect_after_create
    if params[:continue]
      url_params = {}
      url_params[:issue] = {:tracker_id => @issue.tracker, :parent_issue_id => @issue.parent_issue_id}.reject {|k,v| v.nil?}
      url_params[:back_url] = params[:back_url].presence
      if params[:project_id]
        redirect_to new_project_issue_path(@issue.project, url_params)
      else
        url_params[:issue].merge! :project_id => @issue.project_id
        redirect_to new_issue_path(url_params)
      end
    else
      redirect_back_or_default issue_path(@issue)
    end
  end
end
