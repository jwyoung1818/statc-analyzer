require 'csv'
class ImportsController < ApplicationController
  menu_item :issues
  before_action :find_import, :only => [:show, :settings, :mapping, :run]
  before_action :authorize_global
  helper :issues
  helper :queries
  def new
  end
 l(:label_import_issues) 
 form_tag(imports_path, :multipart => true) do 
 l(:label_select_file_to_import) 
 file_field_tag 'file' 
 submit_tag l(:label_next).html_safe + " &#187;".html_safe, :name => nil 
 end 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 end 
  def create
    @import = IssueImport.new
    @import.user = User.current
    @import.file = params[:file]
    @import.set_default_settings
    if @import.save
      redirect_to import_settings_path(@import)
    else
      render :action => 'new'
 l(:label_import_issues) 
 form_tag(imports_path, :multipart => true) do 
 l(:label_select_file_to_import) 
 file_field_tag 'file' 
 submit_tag l(:label_next).html_safe + " &#187;".html_safe, :name => nil 
 end 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 end 
    end
  end
  def show
  end
 l(:label_import_issues) 
 if @import.saved_items.count > 0 
 l(:notice_import_finished, :count => @import.saved_items.count) 
 @import.saved_objects.each do |issue| 
 link_to_issue issue 
 end 
 link_to l(:label_issue_view_all), issues_path(:set_filter => 1, :status_id => '*', :issue_id => @import.saved_objects.map(&:id).join(',')) 
 end 
 if @import.unsaved_items.count > 0 
 l(:notice_import_finished_with_errors, :count => @import.unsaved_items.count, :total => @import.total_items) 
 @import.unsaved_items.each do |item| 
 item.position 
 simple_format_without_paragraph item.message 
 end 
 end 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 end 
  def settings
    if request.post? && @import.parse_file
      redirect_to import_mapping_path(@import)
    end
  rescue CSV::MalformedCSVError => e
    flash.now[:error] = l(:error_invalid_csv_file_or_settings)
  rescue ArgumentError, EncodingError => e
    flash.now[:error] = l(:error_invalid_file_encoding, :encoding => ERB::Util.h(@import.settings['encoding']))
  rescue SystemCallError => e
    flash.now[:error] = l(:error_can_not_read_import_file)
  end
 l(:label_import_issues) 
 form_tag(import_settings_path(@import), :id => "import-form") do 
 l(:label_options) 
 l(:label_fields_separator) 
 select_tag 'import_settings[separator]',
            options_for_select([[l(:label_comma_char), ','], [l(:label_semi_colon_char), ';']], @import.settings['separator']) 
 l(:label_fields_wrapper) 
 select_tag 'import_settings[wrapper]',
          options_for_select([[l(:label_quote_char), "'"], [l(:label_double_quote_char), '"']], @import.settings['wrapper']) 
 l(:label_encoding) 
 select_tag 'import_settings[encoding]', options_for_select(Setting::ENCODINGS, @import.settings['encoding']) 
 l(:setting_date_format) 
 select_tag 'import_settings[date_format]', options_for_select(date_format_options, @import.settings['date_format']) 
 submit_tag l(:label_next).html_safe + " &#187;".html_safe, :name => nil 
 end 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 end 
  def mapping
    @custom_fields = @import.mappable_custom_fields
    if request.post?
      respond_to do |format|
        format.html {
          if params[:previous]
            redirect_to import_settings_path(@import)
          else
            redirect_to import_run_path(@import)
          end
        }
        format.js # updates mapping form on project or tracker change
      end
    end
  end
 l(:label_import_issues) 
 form_tag(import_mapping_path(@import), :id => "import-form") do 
 l(:label_fields_mapping) 
 render :partial => 'fields_mapping' 
 l(:label_project) 
 select_tag 'import_settings[mapping][project_id]',
        options_for_select(project_tree_options_for_select(@import.allowed_target_projects, :selected => @import.project)),
        :id => 'import_mapping_project_id' 
 l(:label_tracker) 
 mapping_select_tag @import, 'tracker', :required => true,
        :values => @import.allowed_target_trackers.sorted.map {|t| [t.name, t.id]} 
 l(:field_status) 
 mapping_select_tag @import, 'status' 
 l(:field_subject) 
 mapping_select_tag @import, 'subject', :required => true 
 l(:field_description) 
 mapping_select_tag @import, 'description' 
 l(:field_priority) 
 mapping_select_tag @import, 'priority' 
 l(:field_category) 
 mapping_select_tag @import, 'category' 
 if User.current.allowed_to?(:manage_categories, @import.project) 
 check_box_tag 'import_settings[mapping][create_categories]', '1', @import.create_categories? 
 l(:label_create_missing_values) 
 end 
 l(:field_assigned_to) 
 mapping_select_tag @import, 'assigned_to' 
 l(:field_fixed_version) 
 mapping_select_tag @import, 'fixed_version' 
 if User.current.allowed_to?(:manage_versions, @import.project) 
 check_box_tag 'import_settings[mapping][create_versions]', '1', @import.create_versions? 
 l(:label_create_missing_values) 
 end 
 @custom_fields.each do |field| 
 field.id 
 field.name 
 mapping_select_tag @import, "cf_#{field.id}" 
 end 
 l(:field_is_private) 
 mapping_select_tag @import, 'is_private' 
 l(:field_parent_issue) 
 mapping_select_tag @import, 'parent_issue_id' 
 l(:field_start_date) 
 mapping_select_tag @import, 'start_date' 
 l(:field_due_date) 
 mapping_select_tag @import, 'due_date' 
 l(:field_estimated_hours) 
 mapping_select_tag @import, 'estimated_hours' 
 l(:field_done_ratio) 
 mapping_select_tag @import, 'done_ratio' 
 l(:label_file_content_preview) 
 @import.first_rows.each do |row| 
 row.map {|c| content_tag 'td', truncate(c.to_s, :length => 50) }.join("").html_safe 
 end 
 button_tag("\xc2\xab " + l(:label_previous), :name => 'previous') 
 submit_tag l(:button_import) 
 end 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 end 
 javascript_tag do 
 import_mapping_path(@import, :format => 'js') 
 @import.total_items || 0 
 end 
  def run
    if request.post?
      @current = @import.run(
        :max_items => max_items_per_request,
        :max_time => 10.seconds
      )
      respond_to do |format|
        format.html {
          if @import.finished?
            redirect_to import_path(@import)
          else
            redirect_to import_run_path(@import)
          end
        }
        format.js
      end
    end
  end
 l(:label_import_issues) 
 @import.total_items.to_i 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 end 
 javascript_tag do 
 @import.total_items.to_i 
 import_run_path(@import, :format => 'js') 
 end 
  private
  def find_import
    @import = Import.where(:user_id => User.current.id, :filename => params[:id]).first
    if @import.nil?
      render_404
      return
    elsif @import.finished? && action_name != 'show'
      redirect_to import_path(@import)
      return
    end
    update_from_params if request.post?
  end
  def update_from_params
    if params[:import_settings].present?
      @import.settings ||= {}
      @import.settings.merge!(params[:import_settings].to_unsafe_hash)
      @import.save!
    end
  end
  def max_items_per_request
    5
  end
end
