class AttachmentsController < ApplicationController
  before_action :find_attachment, :only => [:show, :download, :thumbnail, :update, :destroy]
  before_action :find_editable_attachments, :only => [:edit_all, :update_all]
  before_action :file_readable, :read_authorize, :only => [:show, :download, :thumbnail]
  before_action :update_authorize, :only => :update
  before_action :delete_authorize, :only => :destroy
  before_action :authorize_global, :only => :upload
  skip_after_action :verify_same_origin_request, :only => :download
  accept_api_auth :show, :download, :thumbnail, :upload, :update, :destroy
  def show
    respond_to do |format|
      format.html {
        if @attachment.is_diff?
          @diff = File.read(@attachment.diskfile, :mode => "rb")
          @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
          @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
          if User.current.logged? && @diff_type != User.current.pref[:diff_type]
            User.current.pref[:diff_type] = @diff_type
            User.current.preference.save
          end
          render :action => 'diff'
 render :layout => 'layouts/file' do 
 form_tag({}, :method => 'get') do 
 l(:label_view_diff) 
 radio_button_tag 'type', 'inline', @diff_type != 'sbs', :onchange => "this.form.submit()" 
 l(:label_diff_inline) 
 radio_button_tag 'type', 'sbs', @diff_type == 'sbs', :onchange => "this.form.submit()" 
 l(:label_diff_side_by_side) 
 end 
 render :partial => 'common/diff', :locals => {:diff => @diff, :diff_type => @diff_type, :diff_style => nil} 
 end 
        elsif @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
          @content = File.read(@attachment.diskfile, :mode => "rb")
          render :action => 'file'
 render :layout => 'layouts/file' do 
 render :partial => 'common/file', :locals => {:content => @content, :filename => @attachment.filename} 
 end 
        elsif @attachment.is_image?
          render :action => 'image'
 render :layout => 'layouts/file' do 
 render :partial => 'common/image', :locals => {:path => download_named_attachment_path(@attachment, @attachment.filename), :alt => @attachment.filename} 
 end 
        else
          render :action => 'other'
 render :layout => 'layouts/file' do 
 render :partial => 'common/other',
             :locals => {
               :download_link => link_to_attachment(
                                   @attachment,
                                   :text => l(:label_no_preview_download),
                                   :download => true,
                                   :class => 'icon icon-download'
                                 )
             } 
 end 
        end
      }
      format.api
    end
  end
  def download
    if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
      @attachment.increment_download
    end
    if stale?(:etag => @attachment.digest)
      send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                                      :type => detect_content_type(@attachment),
                                      :disposition => disposition(@attachment)
    end
  end
  def thumbnail
    if @attachment.thumbnailable? && tbnail = @attachment.thumbnail(:size => params[:size])
      if stale?(:etag => tbnail)
        send_file tbnail,
          :filename => filename_for_content_disposition(@attachment.filename),
          :type => detect_content_type(@attachment),
          :disposition => 'inline'
      end
    else
      head 404
    end
  end
  def upload
    unless request.content_type == 'application/octet-stream'
      head 406
      return
    end
    @attachment = Attachment.new(:file => request.raw_post)
    @attachment.author = User.current
    @attachment.filename = params[:filename].presence || Redmine::Utils.random_hex(16)
    @attachment.content_type = params[:content_type].presence
    saved = @attachment.save
    respond_to do |format|
      format.js
      format.api {
        if saved
          render :action => 'upload', :status => :created
        else
          render_validation_errors(@attachment)
        end
      }
    end
  end
  def edit_all
  end
 l(:label_edit_attachments) 
 error_messages_for *@attachments 
 form_tag(container_attachments_path(@container), :method => 'patch') do 
 back_url_hidden_field_tag 
 @attachments.each do |attachment| 
 attachment.filename_was 
 number_to_human_size attachment.filesize 
 attachment.author 
 format_time(attachment.created_on) 
 attachment.id 
 text_field_tag "attachments[#{attachment.id}][filename]", attachment.filename, :size => 40 
 text_field_tag "attachments[#{attachment.id}][description]", attachment.description, :size => 80, :placeholder => l(:label_optional_description) 
 end 
 submit_tag l(:button_save) 
 link_to l(:button_cancel), back_url if back_url.present? 
 end 
  def update_all
    if Attachment.update_attachments(@attachments, update_all_params)
      redirect_back_or_default home_path
      return
    end
    render :action => 'edit_all'
 l(:label_edit_attachments) 
 error_messages_for *@attachments 
 form_tag(container_attachments_path(@container), :method => 'patch') do 
 back_url_hidden_field_tag 
 @attachments.each do |attachment| 
 attachment.filename_was 
 number_to_human_size attachment.filesize 
 attachment.author 
 format_time(attachment.created_on) 
 attachment.id 
 text_field_tag "attachments[#{attachment.id}][filename]", attachment.filename, :size => 40 
 text_field_tag "attachments[#{attachment.id}][description]", attachment.description, :size => 80, :placeholder => l(:label_optional_description) 
 end 
 submit_tag l(:button_save) 
 link_to l(:button_cancel), back_url if back_url.present? 
 end 
  end
  def update
    @attachment.safe_attributes = params[:attachment]
    saved = @attachment.save
    respond_to do |format|
      format.api {
        if saved
          render_api_ok
        else
          render_validation_errors(@attachment)
        end
      }
    end
  end
  def destroy
    if @attachment.container.respond_to?(:init_journal)
      @attachment.container.init_journal(User.current)
    end
    if @attachment.container
      @attachment.container.attachments.delete(@attachment)
    else
      @attachment.destroy
    end
    respond_to do |format|
      format.html { redirect_to_referer_or project_path(@project) }
      format.js
      format.api { render_api_ok }
    end
  end
  def current_menu_item
    if @attachment
      case @attachment.container
      when WikiPage
        :wiki
      when Message
        :boards
      when Project, Version
        :files
      else
        @attachment.container.class.name.pluralize.downcase.to_sym
      end
    end
  end
  private
  def find_attachment
    @attachment = Attachment.find(params[:id])
    raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
    @project = @attachment.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def find_editable_attachments
    klass = params[:object_type].to_s.singularize.classify.constantize rescue nil
    unless klass && klass.reflect_on_association(:attachments)
      render_404
      return
    end
    @container = klass.find(params[:object_id])
    if @container.respond_to?(:visible?) && !@container.visible?
      render_403
      return
    end
    @attachments = @container.attachments.select(&:editable?)
    if @container.respond_to?(:project)
      @project = @container.project
    end
    render_404 if @attachments.empty?
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def file_readable
    if @attachment.readable?
      true
    else
      logger.error "Cannot send attachment, #{@attachment.diskfile} does not exist or is unreadable."
      render_404
    end
  end
  def read_authorize
    @attachment.visible? ? true : deny_access
  end
  def update_authorize
    @attachment.editable? ? true : deny_access
  end
  def delete_authorize
    @attachment.deletable? ? true : deny_access
  end
  def detect_content_type(attachment)
    content_type = attachment.content_type
    if content_type.blank? || content_type == "application/octet-stream"
      content_type = Redmine::MimeType.of(attachment.filename)
    end
    content_type.to_s
  end
  def disposition(attachment)
    if attachment.is_pdf?
      'inline'
    else
      'attachment'
    end
  end
  def update_all_params
    params.permit(:attachments => [:filename, :description]).require(:attachments)
  end
end
