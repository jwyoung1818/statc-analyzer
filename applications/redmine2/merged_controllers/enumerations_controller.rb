class EnumerationsController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin, :except => :index
  before_action :require_admin_or_api_request, :only => :index
  before_action :build_new_enumeration, :only => [:new, :create]
  before_action :find_enumeration, :only => [:edit, :update, :destroy]
  accept_api_auth :index
  helper :custom_fields
  def index
    respond_to do |format|
      format.html
      format.api {
        @klass = Enumeration.get_subclass(params[:type])
        if @klass
          @enumerations = @klass.shared.sorted.to_a
        else
          render_404
        end
      }
    end
  end
l(:label_enumerations)
 Enumeration.get_subclasses.each do |klass| 
 l(klass::OptionName) 
 enumerations = klass.shared 
 link_to l(:label_enumeration_new), new_enumeration_path(:type => klass.name), :class => 'icon icon-add' 
 if enumerations.any? 
 l(:field_name) 
 l(:field_is_default) 
 l(:field_active) 
 enumerations.each do |enumeration| 
 link_to enumeration, edit_enumeration_path(enumeration) 
 checked_image enumeration.is_default? 
 checked_image enumeration.active? 
 reorder_handle(enumeration, :url => enumeration_path(enumeration), :param => 'enumeration') 
 delete_link enumeration_path(enumeration) 
 end 
 else 
 l(:label_no_data) 
 end 
 end 
 html_title(l(:label_enumerations)) 
 javascript_tag do 
 end 
  def new
  end
 title [l(@enumeration.option_name), enumerations_path], l(:label_enumeration_new) 
 labelled_form_for :enumeration, @enumeration, :url => enumerations_path, :html => {:multipart => true} do |f| 
 f.hidden_field :type  
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 end 
  def create
    if request.post? && @enumeration.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to enumerations_path
    else
      render :action => 'new'
 title [l(@enumeration.option_name), enumerations_path], l(:label_enumeration_new) 
 labelled_form_for :enumeration, @enumeration, :url => enumerations_path, :html => {:multipart => true} do |f| 
 f.hidden_field :type  
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 end 
    end
  end
  def edit
  end
 title [l(@enumeration.option_name), enumerations_path], @enumeration.name 
 labelled_form_for :enumeration, @enumeration, :url => enumeration_path(@enumeration), :html => {:method => :put, :multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
  def update
    if @enumeration.update_attributes(enumeration_params)
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to enumerations_path
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
 title [l(@enumeration.option_name), enumerations_path], @enumeration.name 
 labelled_form_for :enumeration, @enumeration, :url => enumeration_path(@enumeration), :html => {:method => :put, :multipart => true} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
        format.js { head 422 }
      end
    end
  end
  def destroy
    if !@enumeration.in_use?
      @enumeration.destroy
      redirect_to enumerations_path
      return
    elsif params[:reassign_to_id].present? && (reassign_to = @enumeration.class.find_by_id(params[:reassign_to_id].to_i))
      @enumeration.destroy(reassign_to)
      redirect_to enumerations_path
      return
    end
    @enumerations = @enumeration.class.system.to_a - [@enumeration]
  end
 title [l(@enumeration.option_name), enumerations_path], @enumeration.name 
 form_tag({}, :method => :delete) do 
 l(:text_enumeration_destroy_question, :name => @enumeration.name, :count => @enumeration.objects_count) 
 l(:text_enumeration_category_reassign_to) 
 select_tag 'reassign_to_id', (content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", :value => '') + options_from_collection_for_select(@enumerations, 'id', 'name')) 
 submit_tag l(:button_apply) 
 link_to l(:button_cancel), enumerations_path 
 end 
  private
  def build_new_enumeration
    class_name = params[:enumeration] && params[:enumeration][:type] || params[:type]
    @enumeration = Enumeration.new_subclass_instance(class_name, enumeration_params)
    if @enumeration.nil?
      render_404
    end
  end
  def find_enumeration
    @enumeration = Enumeration.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def enumeration_params
    params.permit(:enumeration => [:name, :active, :is_default, :position])[:enumeration]
  end
end
