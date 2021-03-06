class WikiController < ApplicationController
  default_search_scope :wiki_pages
  before_action :find_wiki, :authorize
  before_action :find_existing_or_new_page, :only => [:show, :edit, :update]
  before_action :find_existing_page, :only => [:rename, :protect, :history, :diff, :annotate, :add_attachment, :destroy, :destroy_version]
  before_action :find_attachments, :only => [:preview]
  accept_api_auth :index, :show, :update, :destroy
  helper :attachments
  include AttachmentsHelper
  helper :watchers
  include Redmine::Export::PDF
  def index
    load_pages_for_index
    respond_to do |format|
      format.html {
        @pages_by_parent_id = @pages.group_by(&:parent_id)
      }
      format.api
    end
  end
 if User.current.allowed_to?(:edit_wiki_pages, @project) 
 link_to l(:label_wiki_page_new), new_project_wiki_page_path(@project), :remote => true, :class => 'icon icon-add' 
 end 
 watcher_link(@wiki, User.current) 
 if User.current.allowed_to?(:manage_wiki, @project) 
 link_to l(:button_delete), {:controller => 'wikis', :action => 'destroy', :id => @project}, :class => 'icon icon-del' 
 end 
 l(:label_index_by_title) 
 if @pages.empty? 
 l(:label_no_data) 
 end 
 render_page_hierarchy(@pages_by_parent_id, nil, :timestamp => true) 
 content_for :sidebar do 
 render :partial => 'sidebar' 
 if @wiki && @wiki.sidebar 
 textilizable @wiki.sidebar.content, :text 
 end 
 l(:label_wiki) 
 link_to(l(:field_start_page), {:action => 'show', :id => nil}) 
 link_to(l(:label_index_by_title), {:action => 'index'}) 
 link_to(l(:label_index_by_date),
                  {:controller => 'wiki', :project_id => @project,
                   :action => 'date_index'}) 
 end 
 unless @pages.empty? 
 other_formats_links do |f| 
 f.link_to 'Atom',
                :url => {:controller => 'activities', :action => 'index',
                         :id => @project, :show_wiki_edits => 1,
                         :key => User.current.rss_key} 
 if User.current.allowed_to?(:export_wiki_pages, @project) 
 f.link_to('PDF', :url => {:action => 'export', :format => 'pdf'}) 
 f.link_to('HTML', :url => {:action => 'export'}) 
 end 
 end 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(
      :atom, :controller => 'activities', :action => 'index',
      :id => @project, :show_wiki_edits => 1, :format => 'atom',
      :key => User.current.rss_key) 
 end 
  def date_index
    load_pages_for_index
    @pages_by_date = @pages.group_by {|p| p.updated_on.to_date}
  end
 if User.current.allowed_to?(:edit_wiki_pages, @project) 
 link_to l(:label_wiki_page_new), new_project_wiki_page_path(@project), :remote => true, :class => 'icon icon-add' 
 end 
 watcher_link(@wiki, User.current) 
 if User.current.allowed_to?(:manage_wiki, @project) 
 link_to l(:button_delete), {:controller => 'wikis', :action => 'destroy', :id => @project}, :class => 'icon icon-del' 
 end 
 l(:label_index_by_date) 
 if @pages.empty? 
 l(:label_no_data) 
 end 
 @pages_by_date.keys.sort.reverse_each do |date| 
 format_date(date) 
 @pages_by_date[date].each do |page| 
 link_to page.pretty_title, :action => 'show', :id => page.title, :project_id => page.project 
 end 
 end 
 content_for :sidebar do 
 render :partial => 'sidebar' 
 if @wiki && @wiki.sidebar 
 textilizable @wiki.sidebar.content, :text 
 end 
 l(:label_wiki) 
 link_to(l(:field_start_page), {:action => 'show', :id => nil}) 
 link_to(l(:label_index_by_title), {:action => 'index'}) 
 link_to(l(:label_index_by_date),
                  {:controller => 'wiki', :project_id => @project,
                   :action => 'date_index'}) 
 end 
 unless @pages.empty? 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:controller => 'activities', :action => 'index', :id => @project, :show_wiki_edits => 1, :key => User.current.rss_key} 
 if User.current.allowed_to?(:export_wiki_pages, @project) 
 f.link_to('PDF', :url => {:action => 'export', :format => 'pdf'}) 
 f.link_to('HTML', :url => {:action => 'export'}) 
 end 
 end 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, :controller => 'activities', :action => 'index', :id => @project, :show_wiki_edits => 1, :format => 'atom', :key => User.current.rss_key) 
 end 
  def new
    @page = WikiPage.new(:wiki => @wiki, :title => params[:title])
    unless User.current.allowed_to?(:edit_wiki_pages, @project)
      render_403
      return
    end
    if request.post?
      @page.title = '' unless editable?
      @page.validate
      if @page.errors[:title].blank?
        path = project_wiki_page_path(@project, @page.title, :parent => params[:parent])
        respond_to do |format|
          format.html { redirect_to path }
          format.js   { render :js => "window.location = #{path.to_json}" }
        end
      end
    end
  end
 title l(:label_wiki_page_new) 
 labelled_form_for :page, @page,
            :url => new_project_wiki_page_path(@project) do |f| 
 render_error_messages @page.errors.full_messages_for(:title) 
 f.text_field :title, :name => 'title', :size => 60, :required => true 
 l(:text_unallowed_characters) 
 submit_tag(l(:label_next)) 
 end 
  def show
    if params[:version] && !User.current.allowed_to?(:view_wiki_edits, @project)
      deny_access
      return
    end
    @content = @page.content_for_version(params[:version])
    if @content.nil?
      if User.current.allowed_to?(:edit_wiki_pages, @project) && editable? && !api_request?
        edit
        render :action => 'edit'
 wiki_page_breadcrumb(@page) 
 @page.pretty_title 
 form_for @content, :as => :content,
            :url => {:action => 'update', :id => @page.title},
            :html => {:method => :put, :multipart => true, :id => 'wiki_form'} do |f| 
 f.hidden_field :version 
 if @section 
 hidden_field_tag 'section', @section 
 hidden_field_tag 'section_hash', @section_hash 
 end 
 error_messages_for 'content' 
 text_area_tag 'content[text]', @text, :cols => 100, :rows => 25,
                  :class => 'wiki-edit', :accesskey => accesskey(:edit) 
 if @page.safe_attribute_names.include?('parent_id') && @wiki.pages.any? 
 fields_for @page do |fp| 
 l(:field_parent_title) 
 fp.select :parent_id,
                    content_tag('option', '', :value => '') +
                       wiki_page_options_for_select(
                         @wiki.pages.includes(:parent).to_a -
                         @page.self_and_descendants, @page.parent) 
 end 
 end 
 l(:field_comments) 
 f.text_field :comments, :size => 120, :maxlength => 1024 
l(:label_attachment_plural)
 render :partial => 'attachments/form' 
 submit_tag l(:button_save) 
 preview_link({:controller => 'wiki', :action => 'preview', :project_id => @project, :id => @page.title }, 'wiki_form') 
 link_to l(:button_cancel), wiki_page_edit_cancel_path(@page) 
 wikitoolbar_for 'content_text' 
 end 
 content_for :header_tags do 
 robot_exclusion_tag 
 end 
 html_title @page.pretty_title 
      else
        render_404
      end
      return
    end
    call_hook :controller_wiki_show_before_render, content: @content, format: params[:format]
    if User.current.allowed_to?(:export_wiki_pages, @project)
      if params[:format] == 'pdf'
        send_file_headers! :type => 'application/pdf', :filename => filename_for_content_disposition("#{@page.title}.pdf")
        return
      elsif params[:format] == 'html'
        export = render_to_string :action => 'export', :layout => false
        send_data(export, :type => 'text/html', :filename => filename_for_content_disposition("#{@page.title}.html"))
        return
      elsif params[:format] == 'txt'
        send_data(@content.text, :type => 'text/plain', :filename => filename_for_content_disposition("#{@page.title}.txt"))
        return
      end
    end
    @editable = editable?
    @sections_editable = @editable && User.current.allowed_to?(:edit_wiki_pages, @page.project) &&
      @content.current_version? &&
      Redmine::WikiFormatting.supports_section_edit?
    respond_to do |format|
      format.html
      format.api
    end
  end
  def edit
    return render_403 unless editable?
    if @page.new_record?
      if params[:parent].present?
        @page.parent = @page.wiki.find_page(params[:parent].to_s)
      end
    end
    @content = @page.content_for_version(params[:version])
    @content ||= WikiContent.new(:page => @page)
    @content.text = initial_page_content(@page) if @content.text.blank?
    @content.comments = nil
    @content.version = @page.content.version if @page.content
    @text = @content.text
    if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
      @section = params[:section].to_i
      @text, @section_hash = Redmine::WikiFormatting.formatter.new(@text).get_section(@section)
      render_404 if @text.blank?
    end
  end
 wiki_page_breadcrumb(@page) 
 @page.pretty_title 
 form_for @content, :as => :content,
            :url => {:action => 'update', :id => @page.title},
            :html => {:method => :put, :multipart => true, :id => 'wiki_form'} do |f| 
 f.hidden_field :version 
 if @section 
 hidden_field_tag 'section', @section 
 hidden_field_tag 'section_hash', @section_hash 
 end 
 error_messages_for 'content' 
 text_area_tag 'content[text]', @text, :cols => 100, :rows => 25,
                  :class => 'wiki-edit', :accesskey => accesskey(:edit) 
 if @page.safe_attribute_names.include?('parent_id') && @wiki.pages.any? 
 fields_for @page do |fp| 
 l(:field_parent_title) 
 fp.select :parent_id,
                    content_tag('option', '', :value => '') +
                       wiki_page_options_for_select(
                         @wiki.pages.includes(:parent).to_a -
                         @page.self_and_descendants, @page.parent) 
 end 
 end 
 l(:field_comments) 
 f.text_field :comments, :size => 120, :maxlength => 1024 
l(:label_attachment_plural)
 render :partial => 'attachments/form' 
 submit_tag l(:button_save) 
 preview_link({:controller => 'wiki', :action => 'preview', :project_id => @project, :id => @page.title }, 'wiki_form') 
 link_to l(:button_cancel), wiki_page_edit_cancel_path(@page) 
 wikitoolbar_for 'content_text' 
 end 
 content_for :header_tags do 
 robot_exclusion_tag 
 end 
 html_title @page.pretty_title 
  def update
    return render_403 unless editable?
    was_new_page = @page.new_record?
    @page.safe_attributes = params[:wiki_page]
    @content = @page.content || WikiContent.new(:page => @page)
    content_params = params[:content]
    if content_params.nil? && params[:wiki_page].present?
      content_params = params[:wiki_page].slice(:text, :comments, :version)
    end
    content_params ||= {}
    @content.comments = content_params[:comments]
    @text = content_params[:text]
    if params[:section].present? && Redmine::WikiFormatting.supports_section_edit?
      @section = params[:section].to_i
      @section_hash = params[:section_hash]
      @content.text = Redmine::WikiFormatting.formatter.new(@content.text).update_section(@section, @text, @section_hash)
    else
      @content.version = content_params[:version] if content_params[:version]
      @content.text = @text
    end
    @content.author = User.current
    if @page.save_with_content(@content)
      attachments = Attachment.attach_files(@page, params[:attachments] || (params[:wiki_page] && params[:wiki_page][:uploads]))
      render_attachment_warning_if_needed(@page)
      call_hook(:controller_wiki_edit_after_save, { :params => params, :page => @page})
      respond_to do |format|
        format.html {
          anchor = @section ? "section-#{@section}" : nil
          redirect_to project_wiki_page_path(@project, @page.title, :anchor => anchor)
        }
        format.api {
          if was_new_page
            render :action => 'show', :status => :created, :location => project_wiki_page_path(@project, @page.title)
 if User.current.allowed_to?(:edit_wiki_pages, @project) 
 link_to l(:label_wiki_page_new), new_project_wiki_page_path(@project, :parent => @page.title), :remote => true, :class => 'icon icon-add' 
 end 
 if @editable 
 if @content.current_version? 
 link_to_if_authorized(l(:button_edit), {:action => 'edit', :id => @page.title}, :class => 'icon icon-edit', :accesskey => accesskey(:edit)) 
 watcher_link(@page, User.current) 
 link_to_if_authorized(l(:button_lock), {:action => 'protect', :id => @page.title, :protected => 1}, :method => :post, :class => 'icon icon-lock') if !@page.protected? 
 link_to_if_authorized(l(:button_unlock), {:action => 'protect', :id => @page.title, :protected => 0}, :method => :post, :class => 'icon icon-unlock') if @page.protected? 
 link_to_if_authorized(l(:button_rename), {:action => 'rename', :id => @page.title}, :class => 'icon icon-move') 
 link_to_if_authorized(l(:button_delete), {:action => 'destroy', :id => @page.title}, :method => :delete, :data => {:confirm => l(:text_are_you_sure)}, :class => 'icon icon-del') 
 else 
 link_to_if_authorized(l(:button_rollback), {:action => 'edit', :id => @page.title, :version => @content.version }, :class => 'icon icon-cancel') 
 end 
 end 
 wiki_page_breadcrumb(@page) 
 unless @content.current_version? 
 title [@page.pretty_title, project_wiki_page_path(@page.project, @page.title, :version => nil)],
        [l(:label_history), history_project_wiki_page_path(@page.project, @page.title)],
        "#{l(:label_version)} #{@content.version}" 
 link_to(("\xc2\xab " + l(:label_previous)),
                :action => 'show', :id => @page.title, :project_id => @page.project,
                :version => @content.previous.version) + " - " if @content.previous 
 "#{l(:label_version)} #{@content.version}/#{@page.content.version}" 
 '('.html_safe + link_to(l(:label_diff), :controller => 'wiki', :action => 'diff',
                      :id => @page.title, :project_id => @page.project,
                      :version => @content.version) + ')'.html_safe if @content.previous 
 link_to((l(:label_next) + " \xc2\xbb"), :action => 'show',
                :id => @page.title, :project_id => @page.project,
                :version => @content.next.version) + " - " if @content.next 
 link_to(l(:label_current_version), :action => 'show', :id => @page.title, :project_id => @page.project, :version => nil) 
 @content.author ? link_to_user(@content.author) : l(:label_user_anonymous)
 format_time(@content.updated_on) 
 @content.comments 
 end 
 render(:partial => "wiki/content", :locals => {:content => @content}) 
 textilizable content, :text, :attachments => content.page.attachments,
        :edit_section_links => (@sections_editable && {:controller => 'wiki', :action => 'edit', :project_id => @page.project, :id => @page.title}) 
 l(:label_attachment_plural) 
 link_to_attachments @page, :thumbnails => true 
 if @editable && authorize_for('wiki', 'add_attachment') 
 form_tag({:controller => 'wiki', :action => 'add_attachment',
                  :project_id => @project, :id => @page.title},
                 :multipart => true, :id => "add_attachment_form") do 
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
 if User.current.allowed_to?(:view_wiki_edits, @project) 
 wiki_content_update_info(@content) 
 link_to l(:label_x_revisions, :count => @content.version), {:action => 'history', :id => @page.title} 
 end 
 other_formats_links do |f| 
 f.link_to 'PDF', :url => {:id => @page.title, :version => params[:version]} 
 f.link_to 'HTML', :url => {:id => @page.title, :version => params[:version]} 
 f.link_to 'TXT', :url => {:id => @page.title, :version => params[:version]} 
 end if User.current.allowed_to?(:export_wiki_pages, @project) 
 content_for :sidebar do 
 render :partial => 'sidebar' 
 if @wiki && @wiki.sidebar 
 textilizable @wiki.sidebar.content, :text 
 end 
 l(:label_wiki) 
 link_to(l(:field_start_page), {:action => 'show', :id => nil}) 
 link_to(l(:label_index_by_title), {:action => 'index'}) 
 link_to(l(:label_index_by_date),
                  {:controller => 'wiki', :project_id => @project,
                   :action => 'date_index'}) 
 end 
 html_title @page.pretty_title 
          else
            render_api_ok
          end
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
 wiki_page_breadcrumb(@page) 
 @page.pretty_title 
 form_for @content, :as => :content,
            :url => {:action => 'update', :id => @page.title},
            :html => {:method => :put, :multipart => true, :id => 'wiki_form'} do |f| 
 f.hidden_field :version 
 if @section 
 hidden_field_tag 'section', @section 
 hidden_field_tag 'section_hash', @section_hash 
 end 
 error_messages_for 'content' 
 text_area_tag 'content[text]', @text, :cols => 100, :rows => 25,
                  :class => 'wiki-edit', :accesskey => accesskey(:edit) 
 if @page.safe_attribute_names.include?('parent_id') && @wiki.pages.any? 
 fields_for @page do |fp| 
 l(:field_parent_title) 
 fp.select :parent_id,
                    content_tag('option', '', :value => '') +
                       wiki_page_options_for_select(
                         @wiki.pages.includes(:parent).to_a -
                         @page.self_and_descendants, @page.parent) 
 end 
 end 
 l(:field_comments) 
 f.text_field :comments, :size => 120, :maxlength => 1024 
l(:label_attachment_plural)
 render :partial => 'attachments/form' 
 submit_tag l(:button_save) 
 preview_link({:controller => 'wiki', :action => 'preview', :project_id => @project, :id => @page.title }, 'wiki_form') 
 link_to l(:button_cancel), wiki_page_edit_cancel_path(@page) 
 wikitoolbar_for 'content_text' 
 end 
 content_for :header_tags do 
 robot_exclusion_tag 
 end 
 html_title @page.pretty_title 
        format.api { render_validation_errors(@content) }
      end
    end
  rescue ActiveRecord::StaleObjectError, Redmine::WikiFormatting::StaleSectionError
    respond_to do |format|
      format.html {
        flash.now[:error] = l(:notice_locking_conflict)
        render :action => 'edit'
 wiki_page_breadcrumb(@page) 
 @page.pretty_title 
 form_for @content, :as => :content,
            :url => {:action => 'update', :id => @page.title},
            :html => {:method => :put, :multipart => true, :id => 'wiki_form'} do |f| 
 f.hidden_field :version 
 if @section 
 hidden_field_tag 'section', @section 
 hidden_field_tag 'section_hash', @section_hash 
 end 
 error_messages_for 'content' 
 text_area_tag 'content[text]', @text, :cols => 100, :rows => 25,
                  :class => 'wiki-edit', :accesskey => accesskey(:edit) 
 if @page.safe_attribute_names.include?('parent_id') && @wiki.pages.any? 
 fields_for @page do |fp| 
 l(:field_parent_title) 
 fp.select :parent_id,
                    content_tag('option', '', :value => '') +
                       wiki_page_options_for_select(
                         @wiki.pages.includes(:parent).to_a -
                         @page.self_and_descendants, @page.parent) 
 end 
 end 
 l(:field_comments) 
 f.text_field :comments, :size => 120, :maxlength => 1024 
l(:label_attachment_plural)
 render :partial => 'attachments/form' 
 submit_tag l(:button_save) 
 preview_link({:controller => 'wiki', :action => 'preview', :project_id => @project, :id => @page.title }, 'wiki_form') 
 link_to l(:button_cancel), wiki_page_edit_cancel_path(@page) 
 wikitoolbar_for 'content_text' 
 end 
 content_for :header_tags do 
 robot_exclusion_tag 
 end 
 html_title @page.pretty_title 
      }
      format.api { render_api_head :conflict }
    end
  end
  def rename
    return render_403 unless editable?
    @page.redirect_existing_links = true
    @original_title = @page.pretty_title
    @page.safe_attributes = params[:wiki_page]
    if request.post? && @page.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_wiki_page_path(@page.project, @page.title)
    end
  end
 wiki_page_breadcrumb(@page) 
 @original_title 
 error_messages_for 'page' 
 labelled_form_for :wiki_page, @page,
                     :url => { :action => 'rename' },
                     :html => { :method => :post } do |f| 
 f.text_field :title, :required => true, :size => 100  
 if @page.safe_attribute? 'is_start_page' 
 f.check_box :is_start_page, :label => :field_start_page, :disabled => @page.is_start_page 
 end 
 f.check_box :redirect_existing_links 
 f.select :parent_id,
                content_tag('option', '', :value => '') + 
                  wiki_page_options_for_select(
                    @wiki.pages.includes(:parent).to_a - @page.self_and_descendants,
                    @page.parent),
                :label => :field_parent_title 
 if @page.safe_attribute? 'wiki_id' 
 f.select :wiki_id, wiki_page_wiki_options_for_select(@page), :label => :label_project 
 end 
 submit_tag l(:button_rename) 
 end 
  def protect
    @page.update_attribute :protected, params[:protected]
    redirect_to project_wiki_page_path(@project, @page.title)
  end
  def history
    @version_count = @page.content.versions.count
    @version_pages = Paginator.new @version_count, per_page_option, params['page']
    @versions = @page.content.versions.
      select("id, author_id, comments, updated_on, version").
      reorder('version DESC').
      limit(@version_pages.per_page + 1).
      offset(@version_pages.offset).
      to_a
    render :layout => false if request.xhr?
  end
 wiki_page_breadcrumb(@page) 
 title [@page.pretty_title, project_wiki_page_path(@page.project, @page.title, :version => nil)], l(:label_history) 
 form_tag({:controller => 'wiki', :action => 'diff',
              :project_id => @page.project, :id => @page.title},
              :method => :get) do 
 l(:field_updated_on) 
 l(:field_author) 
 l(:field_comments) 
 show_diff = @versions.size > 1 
 line_num = 1 
 @versions.each do |ver| 
 link_to ver.version, :action => 'show', :id => @page.title, :project_id => @page.project, :version => ver.version 
 radio_button_tag('version', ver.version, (line_num==1), :id => "cb-#{line_num}", :onclick => "$('#cbto-#{line_num+1}').prop('checked', true);") if show_diff && (line_num < @versions.size) 
 radio_button_tag('version_from', ver.version, (line_num==2), :id => "cbto-#{line_num}") if show_diff && (line_num > 1) 
 format_time(ver.updated_on) 
 link_to_user ver.author 
 ver.comments 
 link_to l(:button_annotate), :action => 'annotate', :id => @page.title, :version => ver.version 
 delete_link wiki_page_path(@page, :version => ver.version) if User.current.allowed_to?(:delete_wiki_pages, @page.project) && @version_count > 1 
 line_num += 1 
 end 
 submit_tag l(:label_view_diff), :class => 'small' if show_diff 
 pagination_links_full @version_pages, @version_count 
 end 
  def diff
    @diff = @page.diff(params[:version], params[:version_from])
    render_404 unless @diff
  end
 link_to(l(:label_history), {:action => 'history', :id => @page.title},
            :class => 'icon icon-history') 
 wiki_page_breadcrumb(@page) 
 title [@page.pretty_title, project_wiki_page_path(@page.project, @page.title, :version => nil)],
      [l(:label_history), history_project_wiki_page_path(@page.project, @page.title)],
      "#{l(:label_version)} #{@diff.content_to.version}" 
 l(:label_version) 
 link_to @diff.content_from.version, :action => 'show', :id => @page.title, :project_id => @page.project, :version => @diff.content_from.version 
 @diff.content_from.author ?
             @diff.content_from.author.name : l(:label_user_anonymous)
 format_time(@diff.content_from.updated_on) 
 l(:label_version) 
 link_to @diff.content_to.version, :action => 'show',
                             :id => @page.title, :project_id => @page.project,
                             :version => @diff.content_to.version
 @page.content.version 
 @diff.content_to.author ?
             link_to_user(@diff.content_to.author.name) : l(:label_user_anonymous)
 format_time(@diff.content_to.updated_on) 
 simple_format_without_paragraph @diff.to_html 
  def annotate
    @annotate = @page.annotate(params[:version])
    render_404 unless @annotate
  end
 link_to(l(:button_edit), {:action => 'edit', :id => @page.title}, :class => 'icon icon-edit') 
 link_to(l(:label_history),
            {:action => 'history', :id => @page.title}, :class => 'icon icon-history') 
 wiki_page_breadcrumb(@page) 
 title [@page.pretty_title, project_wiki_page_path(@page.project, @page.title, :version => nil)],
      [l(:label_history), history_project_wiki_page_path(@page.project, @page.title)],
      "#{l(:label_version)} #{@annotate.content.version}" 
 @annotate.content.author ? link_to_user(@annotate.content.author) : l(:label_user_anonymous)
 format_time(@annotate.content.updated_on) 
 @annotate.content.comments 
 colors = Hash.new {|k,v| k[v] = (k.size % 12) } 
 line_num = 1 
 @annotate.lines.each do |line| 
 colors[line[0]] 
 line_num 
 link_to line[0], :controller => 'wiki',
                             :action => 'show', :project_id => @project,
                             :id => @page.title, :version => line[0] 
 line[1] 
 line[2] 
 line_num += 1 
 end 
 content_for :header_tags do 
 stylesheet_link_tag 'scm' 
 end 
  def destroy
    return render_403 unless editable?
    @descendants_count = @page.descendants.size
    if @descendants_count > 0
      case params[:todo]
      when 'nullify'
      when 'destroy'
        @page.descendants.each(&:destroy)
      when 'reassign'
        reassign_to = @wiki.pages.find_by_id(params[:reassign_to_id].to_i)
        return unless reassign_to
        @page.children.each do |child|
          child.update_attribute(:parent, reassign_to)
        end
      else
        @reassignable_to = @wiki.pages - @page.self_and_descendants
        return unless api_request?
      end
    end
    @page.destroy
    respond_to do |format|
      format.html { redirect_to project_wiki_index_path(@project) }
      format.api { render_api_ok }
    end
  end
 wiki_page_breadcrumb(@page) 
 @page.pretty_title 
 form_tag({}, :method => :delete) do 
 l(:text_wiki_page_destroy_question, :descendants => @descendants_count) 
 radio_button_tag 'todo', 'nullify', true 
 l(:text_wiki_page_nullify_children) 
 radio_button_tag 'todo', 'destroy', false 
 l(:text_wiki_page_destroy_children) 
 if @reassignable_to.any? 
 radio_button_tag 'todo', 'reassign', false 
 l(:text_wiki_page_reassign_children) 
 label_tag "reassign_to_id", l(:description_wiki_subpages_reassign), :class => "hidden-for-sighted" 
 select_tag 'reassign_to_id', wiki_page_options_for_select(@reassignable_to),
                                 :onclick => "$('#todo_reassign').prop('checked', true);" 
 end 
 submit_tag l(:button_apply) 
 link_to l(:button_cancel), :controller => 'wiki', :action => 'show', :project_id => @project, :id => @page.title 
 end 
  def destroy_version
    return render_403 unless editable?
    if content = @page.content.versions.find_by_version(params[:version])
      content.destroy
      redirect_to_referer_or history_project_wiki_page_path(@project, @page.title)
    else
      render_404
    end
  end
  def export
    @pages = @wiki.pages.
                      order('title').
                      includes([:content, {:attachments => :author}]).
                      to_a
    respond_to do |format|
      format.html {
        export = render_to_string :action => 'export_multiple', :layout => false
        send_data(export, :type => 'text/html', :filename => "wiki.html")
      }
      format.pdf {
        send_file_headers! :type => 'application/pdf', :filename => "#{@project.identifier}.pdf"
      }
    end
  end
 @page.pretty_title 
 textilizable @content, :text, :wiki_links => :local 
  def preview
    page = @wiki.find_page(params[:id])
    return render_403 unless page.nil? || editable?(page)
    if page
      @attachments += page.attachments
      @previewed = page.content
    end
    @text = params[:content][:text]
    render :partial => 'common/preview'
 l(:label_preview) 
 textilizable @text, :attachments => @attachments, :object => @previewed 
  end
  def add_attachment
    return render_403 unless editable?
    attachments = Attachment.attach_files(@page, params[:attachments])
    render_attachment_warning_if_needed(@page)
    redirect_to :action => 'show', :id => @page.title, :project_id => @project
  end
private
  def find_wiki
    @project = Project.find(params[:project_id])
    @wiki = @project.wiki
    render_404 unless @wiki
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def find_existing_or_new_page
    @page = @wiki.find_or_new_page(params[:id])
    if @wiki.page_found_with_redirect?
      redirect_to_page @page
    end
  end
  def find_existing_page
    @page = @wiki.find_page(params[:id])
    if @page.nil?
      render_404
      return
    end
    if @wiki.page_found_with_redirect?
      redirect_to_page @page
    end
  end
  def redirect_to_page(page)
    if page.project && page.project.visible?
      redirect_to :action => action_name, :project_id => page.project, :id => page.title
    else
      render_404
    end
  end
  def editable?(page = @page)
    page.editable_by?(User.current)
  end
  def initial_page_content(page)
    helper = Redmine::WikiFormatting.helper_for(Setting.text_formatting)
    extend helper unless self.instance_of?(helper)
    helper.instance_method(:initial_page_content).bind(self).call(page)
  end
  def load_pages_for_index
    @pages = @wiki.pages.with_updated_on.
                reorder("#{WikiPage.table_name}.title").
                includes(:wiki => :project).
                includes(:parent).
                to_a
  end
end
