class DocumentsController < ApplicationController
  default_search_scope :documents
  model_object Document
  before_action :find_project_by_project_id, :only => [:index, :new, :create]
  before_action :find_model_object, :except => [:index, :new, :create]
  before_action :find_project_from_association, :except => [:index, :new, :create]
  before_action :authorize
  helper :attachments
  helper :custom_fields
  def index
    @sort_by = %w(category date title author).include?(params[:sort_by]) ? params[:sort_by] : 'category'
    documents = @project.documents.includes(:attachments, :category).to_a
    case @sort_by
    when 'date'
      @grouped = documents.group_by {|d| d.updated_on.to_date }
    when 'title'
      @grouped = documents.group_by {|d| d.title.first.upcase}
    when 'author'
      @grouped = documents.select{|d| d.attachments.any?}.group_by {|d| d.attachments.last.author}
    else
      @grouped = documents.group_by(&:category)
    end
    @document = @project.documents.build
    render :layout => false if request.xhr?
  end
 link_to l(:label_document_new), new_project_document_path(@project), :class => 'icon icon-add',
      :onclick => 'showAndScrollTo("add-document", "document_title"); return false;' if User.current.allowed_to?(:add_documents, @project) 
l(:label_document_new)
 labelled_form_for @document, :url => project_documents_path(@project), :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 link_to l(:button_cancel), "#", :onclick => '$("#add-document").hide(); return false;' 
 end 
l(:label_document_plural)
 if @grouped.empty? 
 l(:label_no_data) 
 end 
 @grouped.keys.sort.each do |group| 
 group 
 render :partial => 'documents/document', :collection => @grouped[group] 
 link_to document.title, document_path(document) 
 format_time(document.updated_on) 
 textilizable(truncate_lines(document.description), :object => document) 
 end 
 content_for :sidebar do 
 l(:label_sort_by, '') 
 link_to(l(:field_category), {:sort_by => 'category'},
                    :class => (@sort_by == 'category' ? 'selected' :nil)) 
 link_to(l(:label_date), {:sort_by => 'date'},
                    :class => (@sort_by == 'date' ? 'selected' :nil)) 
 link_to(l(:field_title), {:sort_by => 'title'},
                    :class => (@sort_by == 'title' ? 'selected' :nil)) 
 link_to(l(:field_author), {:sort_by => 'author'},
                    :class => (@sort_by == 'author' ? 'selected' :nil)) 
 end 
 html_title(l(:label_document_plural)) 
  def show
    @attachments = @document.attachments.to_a
  end
 if User.current.allowed_to?(:edit_documents, @project) 
 link_to l(:button_edit), edit_document_path(@document), :class => 'icon icon-edit', :accesskey => accesskey(:edit) 
 end 
 if User.current.allowed_to?(:delete_documents, @project) 
 delete_link document_path(@document) 
 end 
 @document.title 
 @document.category.name 
 format_date @document.created_on 
 if @document.custom_field_values.any? 
 render_custom_field_values(@document) do |custom_field, formatted| 
 custom_field.name 
 formatted 
 end 
 end 
 textilizable @document, :description, :attachments => @document.attachments 
 l(:label_attachment_plural) 
 link_to_attachments @document, :thumbnails => true 
 if authorize_for('documents', 'add_attachment') 
 link_to l(:label_attachment_new), {}, :onclick => "$('#add_attachment_form').show(); return false;",
                                             :id => 'attach_files_link' 
 form_tag({ :controller => 'documents', :action => 'add_attachment', :id => @document }, :multipart => true, :id => "add_attachment_form", :style => "display:none;") do 
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
 end 
 html_title @document.title 
  def new
    @document = @project.documents.build
    @document.safe_attributes = params[:document]
  end
l(:label_document_new)
 labelled_form_for @document, :url => project_documents_path(@project), :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 end 
  def create
    @document = @project.documents.build
    @document.safe_attributes = params[:document]
    @document.save_attachments(params[:attachments])
    if @document.save
      render_attachment_warning_if_needed(@document)
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_documents_path(@project)
    else
      render :action => 'new'
l(:label_document_new)
 labelled_form_for @document, :url => project_documents_path(@project), :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 end 
    end
  end
  def edit
  end
l(:label_document)
 labelled_form_for @document, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
  def update
    @document.safe_attributes = params[:document]
    if @document.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to document_path(@document)
    else
      render :action => 'edit'
l(:label_document)
 labelled_form_for @document, :html => {:multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
    end
  end
  def destroy
    @document.destroy if request.delete?
    redirect_to project_documents_path(@project)
  end
  def add_attachment
    attachments = Attachment.attach_files(@document, params[:attachments])
    render_attachment_warning_if_needed(@document)
    if attachments.present? && attachments[:files].present? && Setting.notified_events.include?('document_added')
      Mailer.attachments_added(attachments[:files]).deliver
    end
    redirect_to document_path(@document)
  end
end
