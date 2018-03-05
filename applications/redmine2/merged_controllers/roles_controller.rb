class RolesController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin, :except => [:index, :show]
  before_action :require_admin_or_api_request, :only => [:index, :show]
  before_action :find_role, :only => [:show, :edit, :update, :destroy]
  accept_api_auth :index, :show
  require_sudo_mode :create, :update, :destroy
  def index
    respond_to do |format|
      format.html {
        @roles = Role.sorted.to_a
        render :layout => false if request.xhr?
      }
      format.api {
        @roles = Role.givable.to_a
      }
    end
  end
 link_to l(:label_role_new), new_role_path, :class => 'icon icon-add' 
 link_to l(:label_permissions_report), permissions_roles_path, :class => 'icon icon-summary' 
l(:label_role_plural)
l(:label_role)
 for role in @roles 
 role.builtin? ? "builtin" : "givable" 
 content_tag(role.builtin? ? 'em' : 'span', link_to(role.name, edit_role_path(role))) 
 reorder_handle(role) unless role.builtin? 
 link_to l(:button_copy), new_role_path(:copy => role), :class => 'icon icon-copy' 
 delete_link role_path(role) unless role.builtin? 
 end 
 html_title(l(:label_role_plural)) 
 javascript_tag do 
 end 
  def show
    respond_to do |format|
      format.api
    end
  end
  def new
    @role = Role.new
    @role.safe_attributes = params[:role] || {:permissions => Role.non_member.permissions}
    if params[:copy].present? && @copy_from = Role.find_by_id(params[:copy])
      @role.copy_from(@copy_from)
    end
    @roles = Role.sorted.to_a
  end
 title [l(:label_role_plural), roles_path], l(:label_role_new) 
 labelled_form_for @role do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 end 
  def create
    @role = Role.new
    @role.safe_attributes = params[:role]
    if request.post? && @role.save
      if !params[:copy_workflow_from].blank? && (copy_from = Role.find_by_id(params[:copy_workflow_from]))
        @role.copy_workflow_rules(copy_from)
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to roles_path
    else
      @roles = Role.sorted.to_a
      render :action => 'new'
 title [l(:label_role_plural), roles_path], l(:label_role_new) 
 labelled_form_for @role do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 end 
    end
  end
  def edit
  end
 title [l(:label_role_plural), roles_path], @role.name 
 labelled_form_for @role do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 end 
  def update
    @role.safe_attributes = params[:role]
    if @role.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to roles_path(:page => params[:page])
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
 title [l(:label_role_plural), roles_path], @role.name 
 labelled_form_for @role do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 end 
        format.js { head 422 }
      end
    end
  end
  def destroy
    begin
      @role.destroy
    rescue
      flash[:error] =  l(:error_can_not_remove_role)
    end
    redirect_to roles_path
  end
  def permissions
    @roles = Role.sorted.to_a
    @permissions = Redmine::AccessControl.permissions.select { |p| !p.public? }
    if request.post?
      @roles.each do |role|
        role.permissions = params[:permissions][role.id.to_s]
        role.save
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to roles_path
    end
  end
 title [l(:label_role_plural), roles_path], l(:label_permissions_report) 
 form_tag(permissions_roles_path, :id => 'permissions_form') do 
 hidden_field_tag 'permissions[0]', '', :id => nil 
l(:label_permissions)
 @roles.each do |role| 
 link_to_function('',
                             "toggleCheckboxesBySelector('input.role-#{role.id}')",
                             :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}",
                             :class => 'icon-only icon-checked') 
 content_tag(role.builtin? ? 'em' : 'span', role.name) 
 end 
 perms_by_module = @permissions.group_by {|p| p.project_module.to_s} 
 perms_by_module.keys.sort.each do |mod| 
 unless mod.blank? 
 l_or_humanize(mod, :prefix => 'project_module_') 
 @roles.each do |role| 
 role.name 
 end 
 end 
 perms_by_module[mod].each do |permission| 
 humanized_perm_name = l_or_humanize(permission.name, :prefix => 'permission_') 
 permission.name 
 link_to_function('',
                                 "toggleCheckboxesBySelector('.permission-#{permission.name} input')",
                                 :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}",
                                 :class => 'icon-only icon-checked') 
 humanized_perm_name 
 @roles.each do |role| 
 if role.setable_permissions.include? permission 
 "#{humanized_perm_name} (#{role.name})" 
 check_box_tag "permissions[#{role.id}][]", permission.name, (role.permissions.include? permission.name), :id => nil, :class => "role-#{role.id}" 
 else 
 end 
 end 
 end 
 end 
 check_all_links 'permissions_form' 
 submit_tag l(:button_save) 
 end 
  private
  def find_role
    @role = Role.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
