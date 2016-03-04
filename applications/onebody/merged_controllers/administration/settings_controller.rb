class Administration::SettingsController < ApplicationController
  before_filter :only_admins

  def index
    @settings = {}
    our_settings.each do |setting|
      @settings[setting.section] ||= {}
      @settings[setting.section][setting['name']] = setting
    end
    @timezones = ActiveSupport::TimeZone.all.map { |z| [z.to_s, z.name] }
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @title = t('admin.settings.heading') 
 form_tag batch_administration_settings_path, method: 'put', class: 'form-horizontal' do 
 section_tab(t('admin.settings.name_heading'), :naming, :active) 
 section_tab(t('admin.settings.contact_heading'), :contact) 
 section_tab(t('admin.settings.features_heading'), :features) 
 section_tab(t('admin.settings.sharing_heading'), :sharing) 
 section_tab(t('admin.settings.membership_management_heading'), :membership_management) 
 section_tab(t('admin.settings.locale_heading'), :locale) 
 section_tab(t('admin.settings.formats_heading'), :formats) 
 section_tab(t('admin.settings.theme_heading'), :theme) 
 section_tab(t('admin.settings.privacy_heading'), :privacy) 
 section_tab(t('admin.settings.services_heading'), :services) 
 label_tag 'hostname', t('admin.settings.host.name'), class: 'col-sm-2 control-label' 
 text_field_tag 'hostname', Site.current.host, class: 'form-control' 
 t('admin.settings.host.description') 
 setting_row('Name', 'Community') 
 setting_row('Name', 'Site') 
 button_tag t('save_changes'), class: 'btn btn-success' 
 t('admin.settings.contact_automated_email_about') 
 setting_row('Contact', 'Send Email Changes To') 
 setting_row('Contact', 'Send Updates To') 
 setting_row('Contact', 'Bug Notification Email') 
 setting_row('Contact', 'Send Attendance Submissions To') 
 t('admin.settings.contact_community_info_about') 
 setting_row('Contact', 'Community Office Phone') 
 setting_row('Contact', 'Community Address') 
 setting_row('Contact', 'Community Email') 
 setting_row('Contact', 'Tech Support Email') 
 button_tag t('save_changes'), class: 'btn btn-success' 
 setting_row('Features', 'Friends') 
 setting_row('Features', 'Groups') 
 setting_row('Features', 'Checkin') 
 setting_row('Features', 'Documents') 
 setting_row('Features', 'Business Directory') 
 setting_row('Features', 'Edit Legacy Ids') 
 button_tag t('save_changes'), class: 'btn btn-success' 
 t('admin.settings.sharing_communications_about') 
 setting_row('Features', 'News Page') 
 t('admin.settings.sharing_about') 
 setting_row('Features', 'News by Users') 
 setting_row('Features', 'Pictures') 
 setting_row('Features', 'Verses') 
 setting_row('Features', 'Small Group Size', options: small_group_sizes) 
 button_tag t('save_changes'), class: 'btn btn-success' 
 setting_row('Features', 'Notify on Photo Change') 
 setting_row('Features', 'Updates Must Be Approved') 
 setting_row('Features', 'Sign Up') 
 setting_row('Features', 'Sign Up Approval Email') 
 setting_row('Features', 'Custom Person Type') 
 setting_row('Features', 'Custom Person Fields') 
 setting_row('System', 'Adult Age', options: (13..21)) 
 setting_row('System', 'Suffixes') 
 button_tag t('save_changes'), class: 'btn btn-success' 
 setting_row('System', 'Language', options: ONEBODY_LOCALES.invert, description: t('admin.settings.System.Language.description', url: 'https://github.com/churchio/onebody/wiki/Translations').html_safe) 
 setting_row('System', 'Time Zone', options: @timezones) 
 setting_row('System', 'Default Country', options: country_options) 
 setting_row('System', 'Map Zoom Level', options: (12..16).to_a) 
 button_tag t('save_changes'), class: 'btn btn-success' 
 setting_row('Appearance', 'Theme', options: t('admin.settings.Appearance.Theme.options').invert) 
 button_tag t('save_changes'), class: 'btn btn-success' 
 t('admin.settings.formats_date_about_html') 
 setting_row('Formats', 'Full Date and Time') 
 setting_row('Formats', 'Date') 
 setting_row('Formats', 'Date Without Year') 
 setting_row('Formats', 'Time') 
 t('admin.settings.formats_phone_about') 
 setting_row('Formats', 'Mobile Phone') 
 setting_row('Formats', 'Phone') 
 button_tag t('save_changes'), class: 'btn btn-success' 
 setting_row('Privacy', 'Allow Picture Comments') 
 setting_row('Privacy', 'Max Sign in Attempts', options: [5, 10, 20, 50]) 
 t('admin.settings.privacy_defaults_about') 
 setting_row('Privacy', 'Share Email by Default',        label: :name) 
 setting_row('Privacy', 'Share Home Phone by Default',   label: :name) 
 setting_row('Privacy', 'Share Mobile Phone by Default', label: :name) 
 setting_row('Privacy', 'Share Work Phone by Default',   label: :name) 
 setting_row('Privacy', 'Share Fax by Default',          label: :name) 
 setting_row('Privacy', 'Share Address by Default',      label: :name) 
 setting_row('Privacy', 'Share Birthday by Default',     label: :name) 
 setting_row('Privacy', 'Share Anniversary by Default',  label: :name) 
 button_tag t('save_changes'), class: 'btn btn-success' 
 setting_row('URL', 'Visitor') 
 setting_row('URL', 'News Feed') 
 setting_row('Services', 'Analytics') 
 label_tag 'email_host', t('admin.settings.Email.Host.name'), class: 'col-sm-2 control-label' 
 text_field_tag 'email_host', Site.current.email_host, class: 'form-control' 
 t('admin.settings.Email.Host.description') 
 t('admin.pusher.heading') 
 t('admin.pusher.intro_html') 
 setting_row('Pusher', 'App ID') 
 setting_row('Pusher', 'App Key') 
 setting_row('Pusher', 'Secret') 
 setting_row('Pusher', 'API Scheme') 
 setting_row('Pusher', 'API Host') 
 setting_row('Pusher', 'API Port') 
 setting_row('Pusher', 'WS Host') 
 setting_row('Pusher', 'WS Port') 
 setting_row('Pusher', 'WSS Port') 
 t('admin.facebook.heading') 
 t('admin.facebook.intro_html') 
 setting_row('Facebook', 'App ID') 
 setting_row('Facebook', 'App Secret') 
 button_tag t('save_changes'), class: 'btn btn-success' 
 end 

end

  end

  def batch
    if update_site
      update_settings
      flash[:notice] = t('application.settings_saved')
    else
      add_errors_to_flash(Site.current)
    end
    redirect_to administration_settings_path
  end

  def reload
    reload_settings
    flash[:notice] = t('application.settings_reloaded')
    redirect_to admin_path
  end

  private

  def update_site
    Site.current.host = params[:hostname] if params[:hostname]
    Site.current.email_host = params[:email_host] if params[:email_host]
    Site.current.save
  end

  def update_settings
    our_settings.each do |setting|
      next unless (value = params[setting.id.to_s])
      value = value.presence
      value = value == 'true' if setting.format == 'boolean'
      setting.update_attributes!(value: value)
    end
    reload_settings
  end

  def our_settings
    Setting.where(hidden: false).where('site_id = ? or global = ?', Site.current.id, true).order('section, name')
  end

  def only_admins
    return if @logged_in.super_admin?
    render text: t('admin.must_be_superadmin'), layout: true, status: 401
    false
  end

  def reload_settings
    Site.current.update_attribute(:settings_changed_at, Time.now)
  end
end
