class AccountController < ApplicationController
  helper :custom_fields
  include CustomFieldsHelper
  self.main_menu = false
  skip_before_action :check_if_login_required, :check_password_change
  def verify_authenticity_token
    unless using_open_id?
      super
    end
  end
  def login
    if request.post?
      authenticate_user
    else
      if User.current.logged?
        redirect_back_or_default home_url, :referer => true
      end
    end
  rescue AuthSourceException => e
    logger.error "An error occurred when authenticating #{params[:username]}: #{e.message}"
    render_error :message => e.message
  end
 call_hook :view_account_login_top 
 form_tag(signin_path, onsubmit: 'return keepAnchorOnSignIn(this);') do 
 back_url_hidden_field_tag 
l(:field_login)
 text_field_tag 'username', params[:username], :tabindex => '1' 
l(:field_password)
 link_to l(:label_password_lost), lost_password_path, :class => "lost_password" if Setting.lost_password? 
 password_field_tag 'password', nil, :tabindex => '2' 
 if Setting.openid? 
l(:field_identity_url)
 text_field_tag "openid_url", nil, :tabindex => '3' 
 end 
 if Setting.autologin? 
 check_box_tag 'autologin', 1, false, :tabindex => 4 
 l(:label_stay_logged_in) 
 end 
l(:button_login)
 end 
 call_hook :view_account_login_bottom 
 if params[:username].present? 
 javascript_tag "$('#password').focus();" 
 else 
 javascript_tag "$('#username').focus();" 
 end 
  def logout
    if User.current.anonymous?
      redirect_to home_url
    elsif request.post?
      logout_user
      redirect_to home_url
    end
  end
 form_tag(signout_path) do 
 submit_tag l(:label_logout) 
 end 
  def lost_password
    (redirect_to(home_url); return) unless Setting.lost_password?
    if prt = (params[:token] || session[:password_recovery_token])
      @token = Token.find_token("recovery", prt.to_s)
      if @token.nil? || @token.expired?
        redirect_to home_url
        return
      end
      if request.query_parameters[:token].present?
        session[:password_recovery_token] = @token.value
        redirect_to lost_password_url
        return
      end
      @user = @token.user
      unless @user && @user.active?
        redirect_to home_url
        return
      end
      if request.post?
        if @user.must_change_passwd? && @user.check_password?(params[:new_password])
          flash.now[:error] = l(:notice_new_password_must_be_different)
        else
          @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
          @user.must_change_passwd = false
          if @user.save
            @token.destroy
            Mailer.password_updated(@user)
            flash[:notice] = l(:notice_account_password_updated)
            redirect_to signin_path
            return
          end
        end
      end
      render :template => "account/password_recovery"
l(:label_password_lost)
 error_messages_for 'user' 
 form_tag(lost_password_path) do 
 hidden_field_tag 'token', @token.value 
l(:field_new_password)
 password_field_tag 'new_password', nil, :size => 25 
 l(:text_caracters_minimum, :count => Setting.password_min_length) 
l(:field_password_confirmation)
 password_field_tag 'new_password_confirmation', nil, :size => 25 
 submit_tag l(:button_save) 
 end 
      return
    else
      if request.post?
        email = params[:mail].to_s.strip
        user = User.find_by_mail(email)
        unless user
          flash.now[:error] = l(:notice_account_unknown_email)
          return
        end
        unless user.active?
          handle_inactive_user(user, lost_password_path)
          return
        end
        unless user.change_password_allowed?
          flash.now[:error] = l(:notice_can_t_change_password)
          return
        end
        token = Token.new(:user => user, :action => "recovery")
        if token.save
          recipent = user.mails.detect {|e| email.casecmp(e) == 0} || user.mail
          Mailer.lost_password(token, recipent).deliver
          flash[:notice] = l(:notice_account_lost_email_sent)
          redirect_to signin_path
          return
        end
      end
    end
  end
  def register
    (redirect_to(home_url); return) unless Setting.self_registration? || session[:auth_source_registration]
    if !request.post?
      session[:auth_source_registration] = nil
      @user = User.new(:language => current_language.to_s)
    else
      user_params = params[:user] || {}
      @user = User.new
      @user.safe_attributes = user_params
      @user.pref.safe_attributes = params[:pref]
      @user.admin = false
      @user.register
      if session[:auth_source_registration]
        @user.activate
        @user.login = session[:auth_source_registration][:login]
        @user.auth_source_id = session[:auth_source_registration][:auth_source_id]
        if @user.save
          session[:auth_source_registration] = nil
          self.logged_user = @user
          flash[:notice] = l(:notice_account_activated)
          redirect_to my_account_path
        end
      else
        unless user_params[:identity_url].present? && user_params[:password].blank? && user_params[:password_confirmation].blank?
          @user.password, @user.password_confirmation = user_params[:password], user_params[:password_confirmation]
        end
        case Setting.self_registration
        when '1'
          register_by_email_activation(@user)
        when '3'
          register_automatically(@user)
        else
          register_manually_by_administrator(@user)
        end
      end
    end
  end
l(:label_register)
link_to l(:label_login_with_open_id_option), signin_url if Setting.openid? 
 labelled_form_for @user, :url => register_path do |f| 
 error_messages_for 'user' 
 if @user.auth_source_id.nil? 
 f.text_field :login, :size => 25, :required => true 
 f.password_field :password, :size => 25, :required => true 
 l(:text_caracters_minimum, :count => Setting.password_min_length) 
 f.password_field :password_confirmation, :size => 25, :required => true 
 end 
 f.text_field :firstname, :required => true 
 f.text_field :lastname, :required => true 
 f.text_field :mail, :required => true 
 labelled_fields_for :pref, @user.pref do |pref_fields| 
 pref_fields.check_box :hide_mail 
 end 
 unless @user.force_default_language? 
 f.select :language, lang_options_for_select 
 end 
 if Setting.openid? 
 f.text_field :identity_url  
 end 
 @user.custom_field_values.select {|v| (Setting.show_custom_fields_on_registration? && v.editable?) || v.required?}.each do |value| 
 custom_field_tag_with_label :user, value 
 end 
 submit_tag l(:button_submit) 
 end 
  def activate
    (redirect_to(home_url); return) unless Setting.self_registration? && params[:token].present?
    token = Token.find_token('register', params[:token].to_s)
    (redirect_to(home_url); return) unless token and !token.expired?
    user = token.user
    (redirect_to(home_url); return) unless user.registered?
    user.activate
    if user.save
      token.destroy
      flash[:notice] = l(:notice_account_activated)
    end
    redirect_to signin_path
  end
  def activation_email
    if session[:registered_user_id] && Setting.self_registration == '1'
      user_id = session.delete(:registered_user_id).to_i
      user = User.find_by_id(user_id)
      if user && user.registered?
        register_by_email_activation(user)
        return
      end
    end
    redirect_to(home_url)
  end
  private
  def authenticate_user
    if Setting.openid? && using_open_id?
      open_id_authenticate(params[:openid_url])
    else
      password_authentication
    end
  end
  def password_authentication
    user = User.try_to_login(params[:username], params[:password], false)
    if user.nil?
      invalid_credentials
    elsif user.new_record?
      onthefly_creation_failed(user, {:login => user.login, :auth_source_id => user.auth_source_id })
    else
      if user.active?
        successful_authentication(user)
        update_sudo_timestamp! # activate Sudo Mode
      else
        handle_inactive_user(user)
      end
    end
  end
  def open_id_authenticate(openid_url)
    back_url = signin_url(:autologin => params[:autologin])
    authenticate_with_open_id(
          openid_url, :required => [:nickname, :fullname, :email],
          :return_to => back_url, :method => :post
    ) do |result, identity_url, registration|
      if result.successful?
        user = User.find_or_initialize_by_identity_url(identity_url)
        if user.new_record?
          (redirect_to(home_url); return) unless Setting.self_registration?
          user.login = registration['nickname'] unless registration['nickname'].nil?
          user.mail = registration['email'] unless registration['email'].nil?
          user.firstname, user.lastname = registration['fullname'].split(' ') unless registration['fullname'].nil?
          user.random_password
          user.register
          case Setting.self_registration
          when '1'
            register_by_email_activation(user) do
              onthefly_creation_failed(user)
            end
          when '3'
            register_automatically(user) do
              onthefly_creation_failed(user)
            end
          else
            register_manually_by_administrator(user) do
              onthefly_creation_failed(user)
            end
          end
        else
          if user.active?
            successful_authentication(user)
          else
            handle_inactive_user(user)
          end
        end
      end
    end
  end
  def successful_authentication(user)
    logger.info "Successful authentication for '#{user.login}' from #{request.remote_ip} at #{Time.now.utc}"
    self.logged_user = user
    if params[:autologin] && Setting.autologin?
      set_autologin_cookie(user)
    end
    call_hook(:controller_account_success_authentication_after, {:user => user })
    redirect_back_or_default my_page_path
  end
  def set_autologin_cookie(user)
    token = user.generate_autologin_token
    secure = Redmine::Configuration['autologin_cookie_secure']
    if secure.nil?
      secure = request.ssl?
    end
    cookie_options = {
      :value => token,
      :expires => 1.year.from_now,
      :path => (Redmine::Configuration['autologin_cookie_path'] || RedmineApp::Application.config.relative_url_root || '/'),
      :secure => secure,
      :httponly => true
    }
    cookies[autologin_cookie_name] = cookie_options
  end
  def onthefly_creation_failed(user, auth_source_options = { })
    @user = user
    session[:auth_source_registration] = auth_source_options unless auth_source_options.empty?
    render :action => 'register'
l(:label_register)
link_to l(:label_login_with_open_id_option), signin_url if Setting.openid? 
 labelled_form_for @user, :url => register_path do |f| 
 error_messages_for 'user' 
 if @user.auth_source_id.nil? 
 f.text_field :login, :size => 25, :required => true 
 f.password_field :password, :size => 25, :required => true 
 l(:text_caracters_minimum, :count => Setting.password_min_length) 
 f.password_field :password_confirmation, :size => 25, :required => true 
 end 
 f.text_field :firstname, :required => true 
 f.text_field :lastname, :required => true 
 f.text_field :mail, :required => true 
 labelled_fields_for :pref, @user.pref do |pref_fields| 
 pref_fields.check_box :hide_mail 
 end 
 unless @user.force_default_language? 
 f.select :language, lang_options_for_select 
 end 
 if Setting.openid? 
 f.text_field :identity_url  
 end 
 @user.custom_field_values.select {|v| (Setting.show_custom_fields_on_registration? && v.editable?) || v.required?}.each do |value| 
 custom_field_tag_with_label :user, value 
 end 
 submit_tag l(:button_submit) 
 end 
  end
  def invalid_credentials
    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} at #{Time.now.utc}"
    flash.now[:error] = l(:notice_account_invalid_credentials)
  end
  def register_by_email_activation(user, &block)
    token = Token.new(:user => user, :action => "register")
    if user.save and token.save
      Mailer.register(token).deliver
      flash[:notice] = l(:notice_account_register_done, :email => ERB::Util.h(user.mail))
      redirect_to signin_path
    else
      yield if block_given?
    end
  end
  def register_automatically(user, &block)
    user.activate
    user.last_login_on = Time.now
    if user.save
      self.logged_user = user
      flash[:notice] = l(:notice_account_activated)
      redirect_to my_account_path
    else
      yield if block_given?
    end
  end
  def register_manually_by_administrator(user, &block)
    if user.save
      Mailer.account_activation_request(user).deliver
      account_pending(user)
    else
      yield if block_given?
    end
  end
  def handle_inactive_user(user, redirect_path=signin_path)
    if user.registered?
      account_pending(user, redirect_path)
    else
      account_locked(user, redirect_path)
    end
  end
  def account_pending(user, redirect_path=signin_path)
    if Setting.self_registration == '1'
      flash[:error] = l(:notice_account_not_activated_yet, :url => activation_email_path)
      session[:registered_user_id] = user.id
    else
      flash[:error] = l(:notice_account_pending)
    end
    redirect_to redirect_path
  end
  def account_locked(user, redirect_path=signin_path)
    flash[:error] = l(:notice_account_locked)
    redirect_to redirect_path
  end
end
