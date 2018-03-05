class WikisController < ApplicationController
  menu_item :settings
  before_action :find_project, :authorize
  def destroy
    if request.post? && params[:confirm] && @project.wiki
      @project.wiki.destroy
      redirect_to settings_project_path(@project, :tab => 'wiki')
    end
  end
l(:label_confirmation)
 @project.name 
l(:text_wiki_destroy_confirmation)
 form_tag({:controller => 'wikis', :action => 'destroy', :id => @project}) do 
 hidden_field_tag "confirm", 1 
 submit_tag l(:button_delete) 
 link_to l(:button_cancel), :back 
 end 
end
