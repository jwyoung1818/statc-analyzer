class SettingsController < ApplicationController
  layout 'admin'
  self.main_menu = false
  menu_item :plugins, :only => :plugin
  helper :queries
  before_action :require_admin
  require_sudo_mode :index, :edit, :plugin
  def index
    edit
    render :action => 'edit'
 l(:label_settings) 
 render_settings_error @setting_errors 
 render_tabs administration_settings_tabs 
 html_title(l(:label_settings), l(:label_administration)) 
  end
  def edit
    @notifiables = Redmine::Notifiable.all
    if request.post?
      errors = Setting.set_all_from_params(params[:settings].to_unsafe_hash)
      if errors.blank?
        flash[:notice] = l(:notice_successful_update)
        redirect_to settings_path(:tab => params[:tab])
        return
      else
        @setting_errors = errors
      end
    end
    @options = {}
    user_format = User::USER_FORMATS.collect{|key, value| [key, value[:setting_order]]}.sort{|a, b| a[1] <=> b[1]}
    @options[:user_format] = user_format.collect{|f| [User.current.name(f[0]), f[0].to_s]}
    @deliveries = ActionMailer::Base.perform_deliveries
    @guessed_host_and_path = request.host_with_port.dup
    @guessed_host_and_path << ('/'+ Redmine::Utils.relative_url_root.gsub(%r{^\/}, '')) unless Redmine::Utils.relative_url_root.blank?
    @commit_update_keywords = Setting.commit_update_keywords.dup
    @commit_update_keywords = [{}] unless @commit_update_keywords.is_a?(Array) && @commit_update_keywords.any?
    Redmine::Themes.rescan
  end
 l(:label_settings) 
 render_settings_error @setting_errors 
 render_tabs administration_settings_tabs 
 html_title(l(:label_settings), l(:label_administration)) 
  def plugin
    @plugin = Redmine::Plugin.find(params[:id])
    unless @plugin.configurable?
      render_404
      return
    end
    if request.post?
      setting = params[:settings] ? params[:settings].permit!.to_h : {}
      Setting.send "plugin_#{@plugin.id}=", setting
      flash[:notice] = l(:notice_successful_update)
      redirect_to plugin_settings_path(@plugin)
    else
      @partial = @plugin.settings[:partial]
      @settings = Setting.send "plugin_#{@plugin.id}"
    end
  rescue Redmine::PluginNotFound
    render_404
  end
 title [l(:label_plugins), {:controller => 'admin', :action => 'plugins'}], @plugin.name 
 form_tag({:action => 'plugin'}) do 
 render :partial => @partial, :locals => {:settings => @settings}
 submit_tag l(:button_apply) 
 end 
end
