class ProjectEnumerationsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  def update
    if @project.update_or_create_time_entry_activities(update_params)
      flash[:notice] = l(:notice_successful_update)
    end
    redirect_to settings_project_path(@project, :tab => 'activities')
  end
  def destroy
    @project.time_entry_activities.each do |time_entry_activity|
      time_entry_activity.destroy(time_entry_activity.parent)
    end
    flash[:notice] = l(:notice_successful_update)
    redirect_to settings_project_path(@project, :tab => 'activities')
  end
  private
  def update_params
    params.
      permit(:enumerations => [:parent_id, :active, {:custom_field_values => {}}]).
      require(:enumerations)
  end
end
