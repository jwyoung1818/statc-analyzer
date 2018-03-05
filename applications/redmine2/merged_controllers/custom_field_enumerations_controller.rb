class CustomFieldEnumerationsController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin
  before_action :find_custom_field
  before_action :find_enumeration, :only => :destroy
  helper :custom_fields
  def index
    @values = @custom_field.enumerations.order(:position)
  end
 custom_field_title @custom_field 
 if @custom_field.enumerations.any? 
 form_tag custom_field_enumerations_path(@custom_field), :method => 'put' do 
 @custom_field.enumerations.each_with_index do |value, position| 
 hidden_field_tag "custom_field_enumerations[#{value.id}][position]", position, :class => 'position' 
 text_field_tag "custom_field_enumerations[#{value.id}][name]", value.name, :size => 40 
 hidden_field_tag "custom_field_enumerations[#{value.id}][active]", 0 
 check_box_tag "custom_field_enumerations[#{value.id}][active]", 1, value.active? 
 l(:field_active) 
 delete_link custom_field_enumeration_path(@custom_field, value) 
 end 
 submit_tag(l(:button_save)) 
 link_to l(:button_back), edit_custom_field_path(@custom_field) 
 end 
 end 
 l(:label_enumeration_new) 
 form_tag custom_field_enumerations_path(@custom_field), :method => 'post', :remote => true do 
 text_field_tag 'custom_field_enumeration[name]', '', :size => 40 
 submit_tag(l(:button_add)) 
 end 
 javascript_tag do 
 end 
  def create
    @value = @custom_field.enumerations.build
    @value.attributes = enumeration_params
    @value.save
    respond_to do |format|
      format.html { redirect_to custom_field_enumerations_path(@custom_field) }
      format.js
    end
  end
  def update_each
    saved = CustomFieldEnumeration.update_each(@custom_field, update_each_params)
    if saved
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to :action => 'index'
  end
  def destroy
    reassign_to = @custom_field.enumerations.find_by_id(params[:reassign_to_id])
    if reassign_to.nil? && @value.in_use?
      @enumerations = @custom_field.enumerations - [@value]
      render :action => 'destroy'
 title [l(:label_custom_field_plural), custom_fields_path],
  [l(@custom_field.type_name), custom_fields_path(:tab => @custom_field.class.name)],
  @custom_field.name 
 form_tag(custom_field_enumeration_path(@custom_field, @value), :method => :delete) do 
 l(:text_enumeration_destroy_question, :name => @value.name, :count => @value.objects_count) 
 l(:text_enumeration_category_reassign_to) 
 select_tag('reassign_to_id', content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", :value => '') + options_from_collection_for_select(@enumerations, 'id', 'name')) 
 submit_tag l(:button_apply) 
 link_to l(:button_cancel), custom_field_enumerations_path(@custom_field) 
 end 
      return
    end
    @value.destroy(reassign_to)
    redirect_to custom_field_enumerations_path(@custom_field)
  end
  private
  def find_custom_field
    @custom_field = CustomField.find(params[:custom_field_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def find_enumeration
    @value = @custom_field.enumerations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def enumeration_params
    params.require(:custom_field_enumeration).permit(:name, :active, :position)
  end
  def update_each_params
    params.permit(:custom_field_enumerations => [:name, :active, :position]).require(:custom_field_enumerations)
  end
end
