class PrincipalMembershipsController < ApplicationController
  layout 'admin'
  self.main_menu = false
  before_action :require_admin
  before_action :find_principal, :only => [:new, :create]
  before_action :find_membership, :only => [:edit, :update, :destroy]
  def new
    @projects = Project.active.all
    @roles = Role.find_all_givable
    respond_to do |format|
      format.html
      format.js
    end
  end
 l(:label_add_projects) 
 form_for :membership, :url => user_memberships_path(@principal), :method => :post do |f| 
 render :partial => 'new_form' 
 submit_tag l(:button_add), :name => nil 
 end 
  def create
    @members = Member.create_principal_memberships(@principal, params[:membership])
    respond_to do |format|
      format.html { redirect_to_principal @principal }
      format.js
    end
  end
  def edit
    @roles = Role.givable.to_a
  end
 title "#{@membership.principal} - #{@membership.project}" 
 render :partial => 'edit' 
 form_for(:membership, :url => principal_membership_path(@principal, @membership),
                          :remote => request.xhr?,
                          :method => :put) do 
 @roles.each do |role| 
 check_box_tag 'membership[role_ids][]', role.id, @membership.roles.to_a.include?(role),
            :disabled => !@membership.role_editable?(role),
            :id => nil 
 role.name 
 end 
 hidden_field_tag 'membership[role_ids][]', '', :id => nil 
 submit_tag l(:button_save) 
 link_to_function l(:button_cancel),
                         "$('#member-#{@membership.id}-roles').show(); $('#member-#{@membership.id}-form').empty(); return false;" if request.xhr? 
 end 
  def update
    @membership.attributes = params.require(:membership).permit(:role_ids => [])
    @membership.save
    respond_to do |format|
      format.html { redirect_to_principal @principal }
      format.js
    end
  end
  def destroy
    if @membership.deletable?
      @membership.destroy
    end
    respond_to do |format|
      format.html { redirect_to_principal @principal }
      format.js
    end
  end
  private
  def find_principal
    principal_id = params[:user_id] || params[:group_id]
    @principal = Principal.find(principal_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def find_membership
    @membership = Member.find(params[:id])
    @principal = @membership.principal
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def redirect_to_principal(principal)
    redirect_to edit_polymorphic_path(principal, :tab => 'memberships')
  end
end
