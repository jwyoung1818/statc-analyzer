class FilesController < ApplicationController
  menu_item :files
  before_action :find_project_by_project_id
  before_action :authorize
  accept_api_auth :index, :create
  helper :attachments
  helper :sort
  include SortHelper
  def index
    sort_init 'filename', 'asc'
    sort_update 'filename' => "#{Attachment.table_name}.filename",
                'created_on' => "#{Attachment.table_name}.created_on",
                'size' => "#{Attachment.table_name}.filesize",
                'downloads' => "#{Attachment.table_name}.downloads"
    @containers = [Project.includes(:attachments).
                     references(:attachments).reorder(sort_clause).find(@project.id)]
    @containers += @project.versions.includes(:attachments).
                    references(:attachments).reorder(sort_clause).to_a.sort.reverse
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.api
    end
  end
 link_to(l(:label_attachment_new), new_project_file_path(@project), :class => 'icon icon-add') if User.current.allowed_to?(:manage_files, @project) 
l(:label_attachment_plural)
 delete_allowed = User.current.allowed_to?(:manage_files, @project) 
 sort_header_tag('filename', :caption => l(:field_filename)) 
 sort_header_tag('created_on', :caption => l(:label_date), :default_order => 'desc') 
 sort_header_tag('size', :caption => l(:field_filesize), :default_order => 'desc') 
 sort_header_tag('downloads', :caption => l(:label_downloads_abbr), :default_order => 'desc') 
 l(:field_digest) 
 @containers.each do |container| 
 next if container.attachments.empty? 
 if container.is_a?(Version) 
 link_to(container, {:controller => 'versions', :action => 'show', :id => container}, :class => "icon icon-package") 
 end 
 container.attachments.each do |file| 
 link_to_attachment file, :title => file.description 
 format_time(file.created_on) 
 number_to_human_size(file.filesize) 
 file.downloads 
 file.digest_type 
 file.digest 
 link_to_attachment file, class: 'icon-only icon-download', title: l(:button_download), download: true 
 link_to(l(:button_delete), attachment_path(file), :class => 'icon-only icon-del',
                                         :data => {:confirm => l(:text_are_you_sure)}, :method => :delete) if delete_allowed 
 end 
 end 
 html_title(l(:label_attachment_plural)) 
  def new
    @versions = @project.versions.sort
  end
l(:label_attachment_new)
 error_messages_for 'attachment' 
 form_tag(project_files_path(@project), :multipart => true, :class => "tabular") do 
 if @versions.any? 
l(:field_version)
 select_tag "version_id", content_tag('option', '') +
                             options_from_collection_for_select(@versions, "id", "name") 
 end 
l(:label_attachment_plural)
 render :partial => 'attachments/form' 
 attachment_param ||= 'attachments' 
 saved_attachments ||= container.saved_attachments if defined?(container) && container 
 multiple = true unless defined?(multiple) && multiple == false 
 show_add = multiple || saved_attachments.blank? 
 description = (defined?(description) && description == false ? false : true) 
 css_class = (defined?(filedrop) && filedrop == false ? '' : 'filedrop') 
 if saved_attachments.present? 
 saved_attachments.each_with_index do |attachment, i| 
 i 
 text_field_tag("#{attachment_param}[p#{i}][filename]", attachment.filename, :class => 'filename') 
 if attachment.container_id.present? 
 link_to l(:label_delete), "#", :onclick => "$(this).closest('.attachments_form').find('.add_attachment').show(); $(this).parent().remove(); return false;", :class => 'icon-only icon-del' 
 hidden_field_tag "#{attachment_param}[p#{i}][id]", attachment.id 
 else 
 text_field_tag("#{attachment_param}[p#{i}][description]", attachment.description, :maxlength => 255, :placeholder => l(:label_optional_description), :class => 'description') if description 
 link_to('&nbsp;'.html_safe, attachment_path(attachment, :attachment_id => "p#{i}", :format => 'js'), :method => 'delete', :remote => true, :class => 'icon-only icon-del remove-upload') 
 hidden_field_tag "#{attachment_param}[p#{i}][token]", attachment.token 
 end 
 end 
 end 
 show_add ? nil : 'display:none;' 
 file_field_tag "#{attachment_param}[dummy][file]",
        :id => nil,
        :class => "file_selector #{css_class}",
        :multiple => multiple,
        :onchange => 'addInputFiles(this);',
        :data => {
          :max_file_size => Setting.attachment_max_size.to_i.kilobytes,
          :max_file_size_message => l(:error_attachment_too_big, :max_size => number_to_human_size(Setting.attachment_max_size.to_i.kilobytes)),
          :max_concurrent_uploads => Redmine::Configuration['max_concurrent_ajax_uploads'].to_i,
          :upload_path => uploads_path(:format => 'js'),
          :param => attachment_param,
          :description => description,
          :description_placeholder => l(:label_optional_description)
        } 
 l(:label_max_size) 
 number_to_human_size(Setting.attachment_max_size.to_i.kilobytes) 
 content_for :header_tags do 
 javascript_include_tag 'attachments' 
 end 
 submit_tag l(:button_add) 
 end 
  def create
    version_id = params[:version_id] || (params[:file] && params[:file][:version_id])
    container = version_id.blank? ? @project : @project.versions.find_by_id(version_id)
    attachments = Attachment.attach_files(container, (params[:attachments] || (params[:file] && params[:file][:token] && params)))
    render_attachment_warning_if_needed(container)
    if attachments[:files].present?
      if Setting.notified_events.include?('file_added')
        Mailer.attachments_added(attachments[:files]).deliver
      end
      respond_to do |format|
        format.html {
          flash[:notice] = l(:label_file_added)
          redirect_to project_files_path(@project) }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:error] = l(:label_attachment) + " " + l('activerecord.errors.messages.invalid')
          new
          render :action => 'new' }
l(:label_attachment_new)
 error_messages_for 'attachment' 
 form_tag(project_files_path(@project), :multipart => true, :class => "tabular") do 
 if @versions.any? 
l(:field_version)
 select_tag "version_id", content_tag('option', '') +
                             options_from_collection_for_select(@versions, "id", "name") 
 end 
l(:label_attachment_plural)
 render :partial => 'attachments/form' 
 attachment_param ||= 'attachments' 
 saved_attachments ||= container.saved_attachments if defined?(container) && container 
 multiple = true unless defined?(multiple) && multiple == false 
 show_add = multiple || saved_attachments.blank? 
 description = (defined?(description) && description == false ? false : true) 
 css_class = (defined?(filedrop) && filedrop == false ? '' : 'filedrop') 
 if saved_attachments.present? 
 saved_attachments.each_with_index do |attachment, i| 
 i 
 text_field_tag("#{attachment_param}[p#{i}][filename]", attachment.filename, :class => 'filename') 
 if attachment.container_id.present? 
 link_to l(:label_delete), "#", :onclick => "$(this).closest('.attachments_form').find('.add_attachment').show(); $(this).parent().remove(); return false;", :class => 'icon-only icon-del' 
 hidden_field_tag "#{attachment_param}[p#{i}][id]", attachment.id 
 else 
 text_field_tag("#{attachment_param}[p#{i}][description]", attachment.description, :maxlength => 255, :placeholder => l(:label_optional_description), :class => 'description') if description 
 link_to('&nbsp;'.html_safe, attachment_path(attachment, :attachment_id => "p#{i}", :format => 'js'), :method => 'delete', :remote => true, :class => 'icon-only icon-del remove-upload') 
 hidden_field_tag "#{attachment_param}[p#{i}][token]", attachment.token 
 end 
 end 
 end 
 show_add ? nil : 'display:none;' 
 file_field_tag "#{attachment_param}[dummy][file]",
        :id => nil,
        :class => "file_selector #{css_class}",
        :multiple => multiple,
        :onchange => 'addInputFiles(this);',
        :data => {
          :max_file_size => Setting.attachment_max_size.to_i.kilobytes,
          :max_file_size_message => l(:error_attachment_too_big, :max_size => number_to_human_size(Setting.attachment_max_size.to_i.kilobytes)),
          :max_concurrent_uploads => Redmine::Configuration['max_concurrent_ajax_uploads'].to_i,
          :upload_path => uploads_path(:format => 'js'),
          :param => attachment_param,
          :description => description,
          :description_placeholder => l(:label_optional_description)
        } 
 l(:label_max_size) 
 number_to_human_size(Setting.attachment_max_size.to_i.kilobytes) 
 content_for :header_tags do 
 javascript_include_tag 'attachments' 
 end 
 submit_tag l(:button_add) 
 end 
        format.api { render :status => :bad_request }
      end
    end
  end
end
