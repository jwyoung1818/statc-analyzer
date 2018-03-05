class MyController < ApplicationController
  self.main_menu = false
  before_action :require_login
  skip_before_action :check_password_change, :only => :password
  require_sudo_mode :account, only: :post
  require_sudo_mode :reset_rss_key, :reset_api_key, :show_api_key, :destroy
  helper :issues
  helper :users
  helper :custom_fields
  helper :queries
  def index
    page
    render :action => 'page'
 form_tag({:action => "add_block"}, :remote => true, :id => "block-form") do 
 label_tag('block-select', l(:button_add)) 
 block_select_tag(@user) 
 end 
l(:label_my_page)
 @groups.each do |group| 
 group 
 render_blocks(@blocks[group], @user) 
 end 
 context_menu 
 javascript_tag do 
 escape_javascript url_for(:action => "order_blocks") 
 end 
 html_title(l(:label_my_page)) 
  end
  def page
    @user = User.current
    @groups = @user.pref.my_page_groups
    @blocks = @user.pref.my_page_layout
  end
 form_tag({:action => "add_block"}, :remote => true, :id => "block-form") do 
 label_tag('block-select', l(:button_add)) 
 block_select_tag(@user) 
 end 
l(:label_my_page)
 @groups.each do |group| 
 group 
 render_blocks(@blocks[group], @user) 
 end 
 context_menu 
 javascript_tag do 
 escape_javascript url_for(:action => "order_blocks") 
 end 
 html_title(l(:label_my_page)) 
  def account
    @user = User.current
    @pref = @user.pref
    if request.post?
      @user.safe_attributes = params[:user]
      @user.pref.safe_attributes = params[:pref]
      if @user.save
        @user.pref.save
        set_language_if_valid @user.language
        flash[:notice] = l(:notice_account_updated)
        redirect_to my_account_path
        return
      end
    end
  end
 additional_emails_link(@user) 
 link_to(l(:button_change_password), {:action => 'password'}, :class => 'icon icon-passwd') if @user.change_password_allowed? 
 call_hook(:view_my_account_contextual, :user => @user)
 avatar_edit_link(@user, :size => "50") 
l(:label_my_account)
 error_messages_for 'user' 
 labelled_form_for :user, @user,
                     :url => { :action => "account" },
                     :html => { :id => 'my_account_form',
                                :method => :post, :multipart => true } do |f| 
l(:label_information_plural)
 f.text_field :firstname, :required => true 
 f.text_field :lastname, :required => true 
 f.text_field :mail, :required => true 
 unless @user.force_default_language? 
 f.select :language, lang_options_for_select 
 end 
 if Setting.openid? 
 f.text_field :identity_url  
 end 
 @user.custom_field_values.select(&:editable?).each do |value| 
 custom_field_tag_with_label :user, value 
 end 
 call_hook(:view_my_account, :user => @user, :form => f) 
 submit_tag l(:button_save) 
l(:field_mail_notification)
 render :partial => 'users/mail_notifications' 
l(:label_preferences)
 render :partial => 'users/preferences' 
 call_hook(:view_my_account_preferences, :user => @user, :form => f) 
 submit_tag l(:button_save) 
 end 
 content_for :sidebar do 
 render :partial => 'sidebar' 
l(:label_my_account)
l(:field_login)
 link_to_user(@user, :format => :username) 
l(:field_created_on)
 format_time(@user.created_on) 
 if @user.own_account_deletable? 
 link_to(l(:button_delete_my_account), {:action => 'destroy'}, :class => 'icon icon-del') 
 end 
 l(:label_feeds_access_key) 
 if @user.rss_token 
 l(:label_feeds_access_key_created_on, distance_of_time_in_words(Time.now, @user.rss_token.created_on)) 
 else 
 l(:label_missing_feeds_access_key) 
 end 
 link_to l(:button_reset), my_rss_key_path, :method => :post 
 if Setting.rest_api_enabled? 
 l(:label_api_access_key) 
 link_to l(:button_show), my_api_key_path, :remote => true 
 javascript_tag("$('#api-access-key').hide();") 
 if @user.api_token 
 l(:label_api_access_key_created_on, distance_of_time_in_words(Time.now, @user.api_token.created_on)) 
 else 
 l(:label_missing_api_access_key) 
 end 
 link_to l(:button_reset), my_api_key_path, :method => :post 
 end 
 end 
 html_title(l(:label_my_account)) 
  def destroy
    @user = User.current
    unless @user.own_account_deletable?
      redirect_to my_account_path
      return
    end
    if request.post? && params[:confirm]
      @user.destroy
      if @user.destroyed?
        logout_user
        flash[:notice] = l(:notice_account_deleted)
      end
      redirect_to home_path
    end
  end
l(:label_confirmation)
 simple_format l(:text_account_destroy_confirmation)
 form_tag({}) do 
 check_box_tag 'confirm', 1 
 l(:general_text_Yes) 
 submit_tag l(:button_delete_my_account) 
 link_to l(:button_cancel), :action => 'account' 
 end 
  def password
    @user = User.current
    unless @user.change_password_allowed?
      flash[:error] = l(:notice_can_t_change_password)
      redirect_to my_account_path
      return
    end
    if request.post?
      if !@user.check_password?(params[:password])
        flash.now[:error] = l(:notice_account_wrong_password)
      elsif params[:password] == params[:new_password]
        flash.now[:error] = l(:notice_new_password_must_be_different)
      else
        @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
        @user.must_change_passwd = false
        if @user.save
          session[:tk] = @user.generate_session_token
          Mailer.password_updated(@user)
          flash[:notice] = l(:notice_account_password_updated)
          redirect_to my_account_path
        end
      end
    end
  end
l(:button_change_password)
 error_messages_for 'user' 
 form_tag({}, :class => "tabular") do 
l(:field_password)
 password_field_tag 'password', nil, :size => 25 
l(:field_new_password)
 password_field_tag 'new_password', nil, :size => 25 
 l(:text_caracters_minimum, :count => Setting.password_min_length) 
l(:field_password_confirmation)
 password_field_tag 'new_password_confirmation', nil, :size => 25 
 submit_tag l(:button_apply) 
 end 
 unless @user.must_change_password? 
 content_for :sidebar do 
 render :partial => 'sidebar' 
l(:label_my_account)
l(:field_login)
 link_to_user(@user, :format => :username) 
l(:field_created_on)
 format_time(@user.created_on) 
 if @user.own_account_deletable? 
 link_to(l(:button_delete_my_account), {:action => 'destroy'}, :class => 'icon icon-del') 
 end 
 l(:label_feeds_access_key) 
 if @user.rss_token 
 l(:label_feeds_access_key_created_on, distance_of_time_in_words(Time.now, @user.rss_token.created_on)) 
 else 
 l(:label_missing_feeds_access_key) 
 end 
 link_to l(:button_reset), my_rss_key_path, :method => :post 
 if Setting.rest_api_enabled? 
 l(:label_api_access_key) 
 link_to l(:button_show), my_api_key_path, :remote => true 
 javascript_tag("$('#api-access-key').hide();") 
 if @user.api_token 
 l(:label_api_access_key_created_on, distance_of_time_in_words(Time.now, @user.api_token.created_on)) 
 else 
 l(:label_missing_api_access_key) 
 end 
 link_to l(:button_reset), my_api_key_path, :method => :post 
 end 
 end 
 end 
  def reset_rss_key
    if request.post?
      if User.current.rss_token
        User.current.rss_token.destroy
        User.current.reload
      end
      User.current.rss_key
      flash[:notice] = l(:notice_feeds_access_key_reseted)
    end
    redirect_to my_account_path
  end
  def show_api_key
    @user = User.current
  end
 l :label_api_access_key 
 @user.api_key 
 link_to l(:button_back), action: 'account' 
  def reset_api_key
    if request.post?
      if User.current.api_token
        User.current.api_token.destroy
        User.current.reload
      end
      User.current.api_key
      flash[:notice] = l(:notice_api_access_key_reseted)
    end
    redirect_to my_account_path
  end
  def update_page
    @user = User.current
    block_settings = params[:settings] || {}
    block_settings.each do |block, settings|
      @user.pref.update_block_settings(block, settings.to_unsafe_hash)
    end
    @user.pref.save
    @updated_blocks = block_settings.keys
  end
  def add_block
    @user = User.current
    @block = params[:block]
    if @user.pref.add_block @block
      @user.pref.save
      respond_to do |format|
        format.html { redirect_to my_page_path }
        format.js
      end
    else
      render_error :status => 422
    end
  end
  def remove_block
    @user = User.current
    @block = params[:block]
    @user.pref.remove_block @block
    @user.pref.save
    respond_to do |format|
      format.html { redirect_to my_page_path }
      format.js
    end
  end
  def order_blocks
    @user = User.current
    @user.pref.order_blocks params[:group], params[:blocks]
    @user.pref.save
    head 200
  end
end
