class AdminController < ApplicationController
  layout 'admin'
  self.main_menu = false
  menu_item :projects, :only => :projects
  menu_item :plugins, :only => :plugins
  menu_item :info, :only => :info
  before_action :require_admin
  def index
    @no_configuration_data = Redmine::DefaultData::Loader::no_data?
  end
l(:label_administration)
 render :partial => 'no_data' if @no_configuration_data 
 form_tag({:action => 'default_configuration'}) do 
 simple_format(l(:text_no_configuration_data)) 
 l(:field_language) 
 select_tag 'lang', options_for_select(lang_options_for_select(false), current_language.to_s) 
 submit_tag l(:text_load_default_configuration) 
 end 
 render :partial => 'menu' 
 render_menu :admin_menu 
 html_title(l(:label_administration)) 
  def projects
    @status = params[:status] || 1
    scope = Project.status(@status).sorted
    scope = scope.like(params[:name]) if params[:name].present?
    @project_count = scope.count
    @project_pages = Paginator.new @project_count, per_page_option, params['page']
    @projects = scope.limit(@project_pages.per_page).offset(@project_pages.offset).to_a
    render :action => "projects", :layout => false if request.xhr?
 link_to l(:label_project_new), new_project_path, :class => 'icon icon-add' 
 title l(:label_project_plural) 
 form_tag({}, :method => :get) do 
 l(:label_filter_plural) 
 l(:field_status) 
 select_tag 'status', project_status_options_for_select(@status), :class => "small", :onchange => "this.form.submit(); return false;"  
 l(:label_project) 
 text_field_tag 'name', params[:name], :size => 30 
 submit_tag l(:button_apply), :class => "small", :name => nil 
 link_to l(:button_clear), admin_projects_path, :class => 'icon icon-reload' 
 end 
 if @projects.any? 
l(:label_project)
l(:field_is_public)
l(:field_created_on)
 project_tree(@projects, :init_level => true) do |project, level| 
 project.css_classes 
 level > 0 ? "idnt idnt-#{level}" : nil 
 link_to_project_settings(project, {}, :title => project.short_description) 
 checked_image project.is_public? 
 format_date(project.created_on) 
 link_to(l(:button_archive), archive_project_path(project, :status => params[:status]), :data => {:confirm => l(:text_are_you_sure)}, :method => :post, :class => 'icon icon-lock') unless project.archived? 
 link_to(l(:button_unarchive), unarchive_project_path(project, :status => params[:status]), :method => :post, :class => 'icon icon-unlock') if project.archived? && (project.parent.nil? || !project.parent.archived?) 
 link_to(l(:button_copy), copy_project_path(project), :class => 'icon icon-copy') 
 link_to(l(:button_delete), project_path(project), :method => :delete, :class => 'icon icon-del') 
 end 
 pagination_links_full @project_pages, @project_count 
 else 
 l(:label_no_data) 
 end 
  end
  def plugins
    @plugins = Redmine::Plugin.all
  end
 title l(:label_plugins) 
 if @plugins.any? 
 @plugins.each do |plugin| 
 plugin.id 
 plugin.name 
 content_tag('span', plugin.description, :class => 'description') unless plugin.description.blank? 
 content_tag('span', link_to(plugin.url, plugin.url), :class => 'url') unless plugin.url.blank? 
 plugin.author_url.blank? ? plugin.author : link_to(plugin.author, plugin.author_url) 
 plugin.version 
 link_to(l(:button_configure), plugin_settings_path(plugin)) if plugin.configurable? 
 end 
 l(:label_check_for_updates) 
 else 
 l(:label_no_data) 
 end 
 javascript_tag do 
 raw_json plugin_data_for_updates(@plugins) 
 escape_javascript l(:label_latest_compatible_version) 
 escape_javascript l(:label_unknown_plugin) 
 end if @plugins.any? 
  def default_configuration
    if request.post?
      begin
        Redmine::DefaultData::Loader::load(params[:lang])
        flash[:notice] = l(:notice_default_data_loaded)
      rescue Exception => e
        flash[:error] = l(:error_can_t_load_default_data, ERB::Util.h(e.message))
      end
    end
    redirect_to admin_path
  end
  def test_email
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    ActionMailer::Base.raise_delivery_errors = true
    begin
      @test = Mailer.test_email(User.current).deliver
      flash[:notice] = l(:notice_email_sent, ERB::Util.h(User.current.mail))
    rescue Exception => e
      flash[:error] = l(:notice_email_error, ERB::Util.h(Redmine::CodesetUtil.replace_invalid_utf8(e.message.dup)))
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to settings_path(:tab => 'notifications')
  end
  def info
    @checklist = [
      [:text_default_administrator_account_changed, User.default_admin_account_changed?],
      [:text_file_repository_writable, File.writable?(Attachment.storage_path)],
      ["#{l :text_plugin_assets_writable} (./public/plugin_assets)",   File.writable?(Redmine::Plugin.public_directory)],
      [:text_rmagick_available,        Object.const_defined?(:Magick)],
      [:text_convert_available,        Redmine::Thumbnail.convert_available?]
    ]
  end
l(:label_information_plural)
 Redmine::Info.versioned_name 
 @checklist.each do |label, result| 
 label.is_a?(Symbol) ? l(label) : label 
 (result ? 'icon-ok' : 'icon-error') 
 end 
 Redmine::Info.environment 
 html_title(l(:label_information_plural)) 
end
