class TrackersController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin, :except => :index
  before_action :require_admin_or_api_request, :only => :index
  accept_api_auth :index
  def index
    @trackers = Tracker.sorted.to_a
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.api
    end
  end
 link_to l(:label_tracker_new), new_tracker_path, :class => 'icon icon-add' 
 link_to l(:field_summary), fields_trackers_path, :class => 'icon icon-summary' 
l(:label_tracker_plural)
l(:label_tracker)
l(:field_default_status)
 for tracker in @trackers 
 link_to tracker.name, edit_tracker_path(tracker) 
 tracker.default_status.name 
 unless tracker.workflow_rules.exists? 
 l(:text_tracker_no_workflow) 
 link_to l(:button_edit), workflows_edit_path(:tracker_id => tracker) 
 end 
 reorder_handle(tracker) 
 delete_link tracker_path(tracker) 
 end 
 html_title(l(:label_tracker_plural)) 
 javascript_tag do 
 end 
  def new
    @tracker ||= Tracker.new
    @tracker.safe_attributes = params[:tracker]
    @trackers = Tracker.sorted.to_a
    @projects = Project.all
  end
 title [l(:label_tracker_plural), trackers_path], l(:label_tracker_new) 
 labelled_form_for @tracker do |f| 
 render :partial => 'form', :locals => { :f => f } 
 end 
  def create
    @tracker = Tracker.new
    @tracker.safe_attributes = params[:tracker]
    if @tracker.save
      if !params[:copy_workflow_from].blank? && (copy_from = Tracker.find_by_id(params[:copy_workflow_from]))
        @tracker.copy_workflow_rules(copy_from)
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to trackers_path
      return
    end
    new
    render :action => 'new'
 title [l(:label_tracker_plural), trackers_path], l(:label_tracker_new) 
 labelled_form_for @tracker do |f| 
 render :partial => 'form', :locals => { :f => f } 
 end 
  end
  def edit
    @tracker ||= Tracker.find(params[:id])
    @projects = Project.all
  end
 title [l(:label_tracker_plural), trackers_path], @tracker.name 
 labelled_form_for @tracker do |f| 
 render :partial => 'form', :locals => { :f => f } 
 end 
  def update
    @tracker = Tracker.find(params[:id])
    @tracker.safe_attributes = params[:tracker]
    if @tracker.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to trackers_path(:page => params[:page])
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html {
          edit
          render :action => 'edit'
 title [l(:label_tracker_plural), trackers_path], @tracker.name 
 labelled_form_for @tracker do |f| 
 render :partial => 'form', :locals => { :f => f } 
 end 
        }
        format.js { head 422 }
      end
    end
  end
  def destroy
    @tracker = Tracker.find(params[:id])
    unless @tracker.issues.empty?
      flash[:error] = l(:error_can_not_delete_tracker)
    else
      @tracker.destroy
    end
    redirect_to trackers_path
  end
  def fields
    if request.post? && params[:trackers]
      params[:trackers].each do |tracker_id, tracker_params|
        tracker = Tracker.find_by_id(tracker_id)
        if tracker
          tracker.core_fields = tracker_params[:core_fields]
          tracker.custom_field_ids = tracker_params[:custom_field_ids]
          tracker.save
        end
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to fields_trackers_path
      return
    end
    @trackers = Tracker.sorted.to_a
    @custom_fields = IssueCustomField.all.sort
  end
 title [l(:label_tracker_plural), trackers_path], l(:field_summary) 
 if @trackers.any? 
 form_tag fields_trackers_path do 
 @trackers.each do |tracker| 
 link_to_function('', "toggleCheckboxesBySelector('input.tracker-#{tracker.id}')",
                               :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}",
                               :class => 'icon-only icon-checked') 
 tracker.name 
 end 
 @trackers.size + 1 
 l(:field_core_fields) 
 Tracker::CORE_FIELDS.each do |field| 
 field_name = l("field_#{field}".sub(/_id$/, '')) 
 link_to_function('', "toggleCheckboxesBySelector('input.core-field-#{field}')",
                               :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}",
                               :class => 'icon-only icon-checked') 
 field_name 
 @trackers.each do |tracker| 
 "#{tracker.name}: #{field_name}" 
 check_box_tag "trackers[#{tracker.id}][core_fields][]", field, tracker.core_fields.include?(field),
                            :class => "tracker-#{tracker.id} core-field-#{field}", :id => nil 
 end 
 end 
 if @custom_fields.any? 
 @trackers.size + 1 
 l(:label_custom_field_plural) 
 @custom_fields.each do |field| 
 link_to_function('', "toggleCheckboxesBySelector('input.custom-field-#{field.id}')",
                                 :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}",
                                 :class => 'icon-only icon-checked') 
 field.name 
 @trackers.each do |tracker| 
 "#{tracker.name}: #{field.name}" 
 check_box_tag "trackers[#{tracker.id}][custom_field_ids][]", field.id, tracker.custom_fields.include?(field),
                              :class => "tracker-#{tracker.id} custom-field-#{field.id}", :id => nil 
 end 
 end 
 end 
 submit_tag l(:button_save) 
 @trackers.each do |tracker| 
 hidden_field_tag "trackers[#{tracker.id}][core_fields][]", '' 
 hidden_field_tag "trackers[#{tracker.id}][custom_field_ids][]", '' 
 end 
 end 
 else 
 l(:label_no_data) 
 end 
end
