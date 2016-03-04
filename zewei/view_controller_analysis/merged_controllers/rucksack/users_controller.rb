#==
# Copyright (C) 2008 James S Urquhart
# Portions Copyright (C) 2009 Michelangelo Altamore
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#++

class UsersController < ApplicationController
  
  layout :user_layout
  
  after_filter  :user_track
  
  before_filter :save_user?, :only => :update
    
  # GET /users
  # GET /users.xml
  def index
    return error_status(true, :cannot_see_user) unless @logged_user.member_of_owner?
    @users = Account.owner.users.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users.to_xml }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = t('user_list') 
 @tabbed_navigation_items = common_tabs(nil) 
 @user_navigation_items = user_tabs(:users) 
 if User.can_be_created_by(@logged_user) 
 new_user_path 
 t('add_user') 
 end 
 @users.each do |user| 
 user.id 
 user.gravatar_url(:size => 50) 
 h(user.display_name) 
 if @logged_user.is_admin 
 if user.can_be_edited_by(@logged_user) 
 edit_user_path(user) 
 t('edit') 
 end 
 if user.can_be_deleted_by(@logged_user) 
 t('delete') 
 end 
 end 
 end 

end

  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = Account.owner.users.find(params[:id])
    return error_status(true, :cannot_see_user) unless (@user.can_be_seen_by(@logged_user))

    respond_to do |format|
      format.html { redirect_to(users_path) }
      format.xml  { render :xml => @user.to_xml }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    return error_status(true, :cannot_create_user) unless (User.can_be_created_by(@logged_user))
    
    @user = Account.owner.users.build()
    @user.is_admin = false

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user.to_xml }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = t('create_user') 
 @tabbed_navigation_items = common_tabs(nil) 
 @user_navigation_items = user_tabs(:users) 
 form_tag users_path(), :method => :post do 
  error_messages_for :user 
 if @logged_user.is_admin 
 t('user_administration_options') 
 text_field 'user', 'username', :id => 'userFormUserName', :class => 'moderate' 
 t('options') 
 t('user_is_admin') 
 yesno_toggle 'user', 'is_admin', :id => 'userFormIsAdmin', :class => 'yesno' 
 end 
 t('display_name') 
 text_field 'user', 'display_name', :id => 'userFormDisplayName', :class => 'moderate' 
 t('email_address') 
 text_field 'user', 'email', :id => 'userFormEmail', :class => 'moderate' 
 t('password') 
 password_field 'user', 'password', :id => 'userFormPassword', :class => 'moderate' 
 t('repeat_password') 
 password_field 'user', 'password_confirmation', :id => 'userFormPasswordAgain', :class => 'moderate' 
 t('timezone') 
 time_zone_select 'user', 'time_zone', nil, {}, {:id => 'userFormTimezone', :class => 'moderate'} 
 
 end 

end

  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
    return error_status(true, :cannot_edit_user) unless (@user.can_be_edited_by(@logged_user))
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = (@user == @logged_user) ? t('update_profile') : t('update_user', :name => h(@user.display_name)) 
 @tabbed_navigation_items = common_tabs(nil) 
 @user_navigation_items = user_tabs((@user == @logged_user) ? :my_profile : :users) 
 form_tag user_path(@user), :method => :put do 
  error_messages_for :user 
 if @logged_user.is_admin 
 t('user_administration_options') 
 text_field 'user', 'username', :id => 'userFormUserName', :class => 'moderate' 
 t('options') 
 t('user_is_admin') 
 yesno_toggle 'user', 'is_admin', :id => 'userFormIsAdmin', :class => 'yesno' 
 end 
 t('display_name') 
 text_field 'user', 'display_name', :id => 'userFormDisplayName', :class => 'moderate' 
 t('email_address') 
 text_field 'user', 'email', :id => 'userFormEmail', :class => 'moderate' 
 t('password') 
 password_field 'user', 'password', :id => 'userFormPassword', :class => 'moderate' 
 t('repeat_password') 
 password_field 'user', 'password_confirmation', :id => 'userFormPasswordAgain', :class => 'moderate' 
 t('timezone') 
 time_zone_select 'user', 'time_zone', nil, {}, {:id => 'userFormTimezone', :class => 'moderate'} 
 
 end 

end

  end

  # POST /users
  # POST /users.xml
  def create
    return error_status(true, :cannot_create_user) unless (User.can_be_created_by(@logged_user))
    
    user_attribs = params[:user]

    @user = Account.owner.users.new()

    if @logged_user.is_admin
      if user_attribs.has_key?('is_admin')
        set_admin = user_attribs.delete('is_admin')
        @user.is_admin = Account.owner.owner_id != @user.id ? set_admin : true
      end

      @user.username = user_attribs.delete('username') if user_attribs.has_key?('username')
    else
      user_attribs.delete('is_admin')
      user_attribs.delete('username')
    end
    
    if user_attribs.has_key? 'password' and !user_attribs['password'].empty?
      @user.password = user_attribs.delete('password')
      @user.password_confirmation = user_attribs.delete('password_confirmation')
    else
      user_attribs.delete('password')
      user_attribs.delete('password_confirmation')
    end

    @user.attributes = user_attribs
    
    saved = @user.save
    if saved
      home_page = Page.new(:title => "#{@user.display_name.pluralize} page")
      home_page.created_by = @user
      home_page.save
      @user.update_attribute('home_page', home_page)
    end

    respond_to do |format|
      if saved
        flash[:notice] = 'user was successfully created.'
        format.html { redirect_to(users_path) }
        format.xml  { render :xml => @user.to_xml, :status => :created, :location => @user }
      else
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = t('create_user') 
 @tabbed_navigation_items = common_tabs(nil) 
 @user_navigation_items = user_tabs(:users) 
 form_tag users_path(), :method => :post do 
  error_messages_for :user 
 if @logged_user.is_admin 
 t('user_administration_options') 
 text_field 'user', 'username', :id => 'userFormUserName', :class => 'moderate' 
 t('options') 
 t('user_is_admin') 
 yesno_toggle 'user', 'is_admin', :id => 'userFormIsAdmin', :class => 'yesno' 
 end 
 t('display_name') 
 text_field 'user', 'display_name', :id => 'userFormDisplayName', :class => 'moderate' 
 t('email_address') 
 text_field 'user', 'email', :id => 'userFormEmail', :class => 'moderate' 
 t('password') 
 password_field 'user', 'password', :id => 'userFormPassword', :class => 'moderate' 
 t('repeat_password') 
 password_field 'user', 'password_confirmation', :id => 'userFormPasswordAgain', :class => 'moderate' 
 t('timezone') 
 time_zone_select 'user', 'time_zone', nil, {}, {:id => 'userFormTimezone', :class => 'moderate'} 
 
 end 

end
 }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = Account.owner.users.find(params[:id])
    return error_status(true, :cannot_edit_user) unless (@user.can_be_edited_by(@logged_user))
    
    user_attribs = params[:user]
    if @logged_user.is_admin
      if user_attribs.has_key?('is_admin')
        set_admin = user_attribs.delete('is_admin')
        @user.is_admin = Account.owner.owner_id != @user.id ? set_admin : true
      end

      @user.username = user_attribs.delete('username') if user_attribs.has_key?('username')
    else
      user_attribs.delete('is_admin')
      user_attribs.delete('username')
    end
    
    if user_attribs.has_key? 'password' and !user_attribs['password'].empty?
      @user.password = user_attribs.delete('password')
      @user.password_confirmation = user_attribs.delete('password_confirmation')
    else
      user_attribs.delete('password')
      user_attribs.delete('password_confirmation')
    end

    puts "ATTRS TO SET: #{user_attribs.inspect}"

    respond_to do |format|
      if @user.update_attributes(user_attribs)
        flash[:notice] = 'user was successfully updated.'
        format.html { redirect_to(users_path) }
        format.xml  { head :ok }
      else
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = (@user == @logged_user) ? t('update_profile') : t('update_user', :name => h(@user.display_name)) 
 @tabbed_navigation_items = common_tabs(nil) 
 @user_navigation_items = user_tabs((@user == @logged_user) ? :my_profile : :users) 
 form_tag user_path(@user), :method => :put do 
  error_messages_for :user 
 if @logged_user.is_admin 
 t('user_administration_options') 
 text_field 'user', 'username', :id => 'userFormUserName', :class => 'moderate' 
 t('options') 
 t('user_is_admin') 
 yesno_toggle 'user', 'is_admin', :id => 'userFormIsAdmin', :class => 'yesno' 
 end 
 t('display_name') 
 text_field 'user', 'display_name', :id => 'userFormDisplayName', :class => 'moderate' 
 t('email_address') 
 text_field 'user', 'email', :id => 'userFormEmail', :class => 'moderate' 
 t('password') 
 password_field 'user', 'password', :id => 'userFormPassword', :class => 'moderate' 
 t('repeat_password') 
 password_field 'user', 'password_confirmation', :id => 'userFormPasswordAgain', :class => 'moderate' 
 t('timezone') 
 time_zone_select 'user', 'time_zone', nil, {}, {:id => 'userFormTimezone', :class => 'moderate'} 
 
 end 

end
 }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = Account.owner.users.find(params[:id])
    return error_status(true, :cannot_delete_user) unless (@user.can_be_deleted_by(@logged_user))
    
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.js { }
      format.xml  { head :ok }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 escape_javascript(users_path(:use_route => nil)) 

end

  end

  # GET /users/current
  def current
    @user = @logged_user
    return error_status(true, :cannot_edit_user) unless (@user.can_be_edited_by(@logged_user))
    
    ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = (@user == @logged_user) ? t('update_profile') : t('update_user', :name => h(@user.display_name)) 
 @tabbed_navigation_items = common_tabs(nil) 
 @user_navigation_items = user_tabs((@user == @logged_user) ? :my_profile : :users) 
 form_tag user_path(@user), :method => :put do 
  error_messages_for :user 
 if @logged_user.is_admin 
 t('user_administration_options') 
 text_field 'user', 'username', :id => 'userFormUserName', :class => 'moderate' 
 t('options') 
 t('user_is_admin') 
 yesno_toggle 'user', 'is_admin', :id => 'userFormIsAdmin', :class => 'yesno' 
 end 
 t('display_name') 
 text_field 'user', 'display_name', :id => 'userFormDisplayName', :class => 'moderate' 
 t('email_address') 
 text_field 'user', 'email', :id => 'userFormEmail', :class => 'moderate' 
 t('password') 
 password_field 'user', 'password', :id => 'userFormPassword', :class => 'moderate' 
 t('repeat_password') 
 password_field 'user', 'password_confirmation', :id => 'userFormPasswordAgain', :class => 'moderate' 
 t('timezone') 
 time_zone_select 'user', 'time_zone', nil, {}, {:id => 'userFormTimezone', :class => 'moderate'} 
 
 end 

end

  end  
 
  # GET /users/forgot_password 
  def forgot_password
    case request.method_symbol
      when :post
        @your_email = params[:your_email]
        
        user = User.where(:email => @your_email).where('account_id NOT NULL').first
        if user.nil?
          error_status(false, :invalid_email_not_in_use, {}, false)
          return
        end
        
        # Send the reset!
        user.send_password_reset()
        error_status(false, :forgot_password_sent_email, {}, false)
        redirect_to new_session_path
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = t('forgot_password') 
 form_tag :controller => 'users', :action => 'forgot_password' do 
 t('email_address') 
 text_field_tag 'your_email', '', :id => 'forgotPasswordEmail', :class => 'medium' 
 link_to t('login'), '/login' 
 t('send_password') 
 end 

end

  end
  
  # GET /users/reset_password
  def reset_password
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(false, :invalid_request, {}, false)
      redirect_to new_session_path
      return
    end
    
    unless @user.member_of_owner? and @user.password_reset_key == params[:confirm]
      error_status(false, :invalid_request, {}, false)
      redirect_to new_session_path
      return
    end
    
    @initial_signup = params.has_key? :initial
    
    case request.method_symbol
      when :post
        
        @password_data = params[:user]
            
        unless @password_data[:password]
          @user.errors.add(:password, t('new_password_required'))
          return
        end
          
        unless @password_data[:password] == @password_data[:password_confirmation]
          @user.errors.add(:password_confirmation, t('does_not_match'))
          return
        end
    
        @user.password = @password_data[:password]
        @user.save
        
        error_status(false, :password_changed, {}, false)
        redirect_to '/login'
        return
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = @initial_signup ? t('set_password') : t('reset_password') 
 form_tag :controller => 'users', :action => 'reset_password' do 
 error_messages_for :user 
 h(params[:confirm]) 
 @initial_signup ? t('set_password') : t('change_password') 
 end 

end

  end

protected

  def user_layout
    ['forgot_password', 'reset_password'].include?(action_name) ? 'dialog' : 'pages'
  end
  
  def authorized?(action = action_name, resource = nil)
    ['forgot_password', 'reset_password'].include?(action) ? true : logged_in?
  end
  
  def save_user?
    if admin_in_demo_mode? 
      flash[:notice] = 'You are not allowed to change admin credentials in this demo, try with a normal user instead.'
      redirect_to users_url
    end
  end
end