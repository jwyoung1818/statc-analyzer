class EmailAddressesController < ApplicationController
  self.main_menu = false
  before_action :find_user, :require_admin_or_current_user
  before_action :find_email_address, :only => [:update, :destroy]
  require_sudo_mode :create, :update, :destroy
  def index
    @addresses = @user.email_addresses.order(:id).where(:is_default => false).to_a
    @address ||= EmailAddress.new
  end
 @user.name 
 render :partial => 'email_addresses/index' 
 if @addresses.present? 
 @addresses.each do |address| 
 address.address 
 toggle_email_address_notify_link(address) 
 delete_link user_email_address_path(@user, address), :remote => true 
 end 
 end 
 unless @addresses.size >= Setting.max_additional_emails.to_i 
 form_for @address, :url => user_email_addresses_path(@user), :remote => true do |f| 
 l(:label_email_address_add) 
 error_messages_for @address 
 f.text_field :address, :size => 40 
 submit_tag l(:button_add) 
 end 
 end 
  def create
    saved = false
    if @user.email_addresses.count <= Setting.max_additional_emails.to_i
      @address = EmailAddress.new(:user => @user, :is_default => false)
      @address.safe_attributes = params[:email_address]
      saved = @address.save
    end
    respond_to do |format|
      format.html {
        if saved
          redirect_to user_email_addresses_path(@user)
        else
          index
          render :action => 'index'
 @user.name 
 render :partial => 'email_addresses/index' 
 if @addresses.present? 
 @addresses.each do |address| 
 address.address 
 toggle_email_address_notify_link(address) 
 delete_link user_email_address_path(@user, address), :remote => true 
 end 
 end 
 unless @addresses.size >= Setting.max_additional_emails.to_i 
 form_for @address, :url => user_email_addresses_path(@user), :remote => true do |f| 
 l(:label_email_address_add) 
 error_messages_for @address 
 f.text_field :address, :size => 40 
 submit_tag l(:button_add) 
 end 
 end 
        end
      }
      format.js {
        @address = nil if saved
        index
        render :action => 'index'
 @user.name 
 render :partial => 'email_addresses/index' 
 if @addresses.present? 
 @addresses.each do |address| 
 address.address 
 toggle_email_address_notify_link(address) 
 delete_link user_email_address_path(@user, address), :remote => true 
 end 
 end 
 unless @addresses.size >= Setting.max_additional_emails.to_i 
 form_for @address, :url => user_email_addresses_path(@user), :remote => true do |f| 
 l(:label_email_address_add) 
 error_messages_for @address 
 f.text_field :address, :size => 40 
 submit_tag l(:button_add) 
 end 
 end 
      }
    end
  end
  def update
    if params[:notify].present?
      @address.notify = params[:notify].to_s
    end
    @address.save
    respond_to do |format|
      format.html {
        redirect_to user_email_addresses_path(@user)
      }
      format.js {
        @address = nil
        index
        render :action => 'index'
 @user.name 
 render :partial => 'email_addresses/index' 
 if @addresses.present? 
 @addresses.each do |address| 
 address.address 
 toggle_email_address_notify_link(address) 
 delete_link user_email_address_path(@user, address), :remote => true 
 end 
 end 
 unless @addresses.size >= Setting.max_additional_emails.to_i 
 form_for @address, :url => user_email_addresses_path(@user), :remote => true do |f| 
 l(:label_email_address_add) 
 error_messages_for @address 
 f.text_field :address, :size => 40 
 submit_tag l(:button_add) 
 end 
 end 
      }
    end
  end
  def destroy
    @address.destroy
    respond_to do |format|
      format.html {
        redirect_to user_email_addresses_path(@user)
      }
      format.js {
        @address = nil
        index
        render :action => 'index'
 @user.name 
 render :partial => 'email_addresses/index' 
 if @addresses.present? 
 @addresses.each do |address| 
 address.address 
 toggle_email_address_notify_link(address) 
 delete_link user_email_address_path(@user, address), :remote => true 
 end 
 end 
 unless @addresses.size >= Setting.max_additional_emails.to_i 
 form_for @address, :url => user_email_addresses_path(@user), :remote => true do |f| 
 l(:label_email_address_add) 
 error_messages_for @address 
 f.text_field :address, :size => 40 
 submit_tag l(:button_add) 
 end 
 end 
      }
    end
  end
  private
  def find_user
    @user = User.find(params[:user_id])
  end
  def find_email_address
    @address = @user.email_addresses.where(:is_default => false).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def require_admin_or_current_user
    unless @user == User.current
      require_admin
    end
  end
end
