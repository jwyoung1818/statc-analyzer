class CustomFieldsController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin
  before_action :build_new_custom_field, :only => [:new, :create]
  before_action :find_custom_field, :only => [:edit, :update, :destroy]
  accept_api_auth :index
  def index
    respond_to do |format|
      format.html {
        @custom_fields_by_type = CustomField.all.group_by {|f| f.class.name }
        @custom_fields_projects_count =
          IssueCustomField.where(is_for_all: false).joins(:projects).group(:custom_field_id).count
      }
      format.api {
        @custom_fields = CustomField.all
      }
    end
  end
 link_to l(:label_custom_field_new), new_custom_field_path, :class => 'icon icon-add' 
 title l(:label_custom_field_plural) 
 if @custom_fields_by_type.present? 
 render_custom_fields_tabs(@custom_fields_by_type.keys) 
 else 
 l(:label_no_data) 
 end 
 javascript_tag do 
 end 
  def new
    @custom_field.field_format = 'string' if @custom_field.field_format.blank?
    @custom_field.default_value = nil
  end
 custom_field_title @custom_field 
 labelled_form_for :custom_field, @custom_field, :url => custom_fields_path, :html => {:id => 'custom_field_form'} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 hidden_field_tag 'type', @custom_field.type 
 end 
 javascript_tag do 
 new_custom_field_path(:format => 'js') 
 end 
  def create
    if @custom_field.save
      flash[:notice] = l(:notice_successful_create)
      call_hook(:controller_custom_fields_new_after_save, :params => params, :custom_field => @custom_field)
      redirect_to edit_custom_field_path(@custom_field)
    else
      render :action => 'new'
 custom_field_title @custom_field 
 labelled_form_for :custom_field, @custom_field, :url => custom_fields_path, :html => {:id => 'custom_field_form'} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 hidden_field_tag 'type', @custom_field.type 
 end 
 javascript_tag do 
 new_custom_field_path(:format => 'js') 
 end 
    end
  end
  def edit
  end
 custom_field_title @custom_field 
 labelled_form_for :custom_field, @custom_field, :url => custom_field_path(@custom_field), :html => {:method => :put, :id => 'custom_field_form'} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 end 
  def update
    @custom_field.safe_attributes = params[:custom_field]
    if @custom_field.save
      call_hook(:controller_custom_fields_edit_after_save, :params => params, :custom_field => @custom_field)
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default edit_custom_field_path(@custom_field)
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
 custom_field_title @custom_field 
 labelled_form_for :custom_field, @custom_field, :url => custom_field_path(@custom_field), :html => {:method => :put, :id => 'custom_field_form'} do |f| 
 render :partial => 'form', :locals => { :f => f } 
 end 
        format.js { head 422 }
      end
    end
  end
  def destroy
    begin
      if @custom_field.destroy
        flash[:notice] = l(:notice_successful_delete)
      end
    rescue
      flash[:error] = l(:error_can_not_delete_custom_field)
    end
    redirect_to custom_fields_path(:tab => @custom_field.class.name)
  end
  private
  def build_new_custom_field
    @custom_field = CustomField.new_subclass_instance(params[:type])
    if @custom_field.nil?
      render :action => 'select_type'
 custom_field_title @custom_field 
 selected = 0 
 form_tag new_custom_field_path, :method => 'get' do 
 l(:label_custom_field_select_type) 
 custom_field_type_options.each do |name, type| 
 radio_button_tag 'type', type, 1==selected+=1 
 name 
 end 
 submit_tag l(:label_next).html_safe + " &#187;".html_safe, :name => nil 
 end 
    else
      @custom_field.safe_attributes = params[:custom_field]
    end
  end
  def find_custom_field
    @custom_field = CustomField.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
