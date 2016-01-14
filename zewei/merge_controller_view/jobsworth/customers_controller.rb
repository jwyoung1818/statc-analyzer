# encoding: UTF-8
# Handle CRUD dealing with Customers

class CustomersController < ApplicationController
  before_filter :authorize_user_can_create_customers, :only => [:new, :create]
  before_filter :authorize_user_can_edit_customers,   :only => [:edit, :update, :destroy]
  before_filter :authorize_user_can_read_customers,   :only => [:show]

  def show
    @customer = Customer.from_company(current_user.company_id).find(params[:id])

  end

  def new
    @customer = current_user.company.customers.new
 @page_title = "#{t('customers.new')} - #{Setting.productName}" 
 form_for(@customer, :html => {:class => "form-horizontal"}) do |f| 
 t('customers.new') 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 if !@customer.internal_customer? 
 f.label :name 
 f.text_field 'name'  
 end 
 f.label :contact_name 
 f.text_field 'contact_name' 
 f.label :active 
 check_box(:customer, :active) 
 render("/common/custom_attributes", { :object => @customer }) 

end
 
 submit_tag t("button.create"), :class => "btn btn-primary" 
 end 

  end

  def create
    @customer         = Customer.new(params[:customer])
    @customer.company = current_user.company

    if @customer.save
      redirect_to root_path, notice: t('flash.notice.model_created', model: Customer.model_name.human)
    else
      flash[:error] = @customer.errors.full_messages.join(".")
      render :new
    end
  end

  def edit
    @customer = Customer.from_company(current_user.company_id).where(:id => params[:id]).includes(:projects).first
 @page_title = "Customer : #{@customer.name} - #{Setting.productName}" 
 form_for(@customer, :html => {:class => "form-horizontal"}) do |f| 
 link_to_tasks_filtered_by(t("customers.view_tasks"), @customer, :class => "btn btn-success pull-right") 
 @customer.name 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 if !@customer.internal_customer? 
 f.label :name 
 f.text_field 'name'  
 end 
 f.label :contact_name 
 f.text_field 'contact_name' 
 f.label :active 
 check_box(:customer, :active) 
 render("/common/custom_attributes", { :object => @customer }) 

end
 
 submit_tag t("button.save"), :class => "btn btn-primary" 
 if current_user.admin?
 link_to t("button.delete"), customer_path(@customer), :method => "delete", :confirm => "Really delete #{@customer.name}?", :class => "btn btn-mini btn-danger pull-right" 
 end 
 end 
 t("customers.view_tasks") 
 create_users_link(@customer) 
 link_to(t("customers.create_site"), new_organizational_unit_path(:customer_id => @customer.id)) 
 if current_user.use_resources? 
 link_to(t("customers.create_resource"), new_resource_path(:customer_id => @customer.id)) 
 end 
 t("customers.active_users") 
 t("customers.inactive_users") 
 t("customers.current_projects") 
 t("customers.completed_projects") 
 if current_user.company.use_score_rules? 
 t("customers.score_rules") 
 end 
 t("customers.sites") 
 if current_user.use_resources? 
 t("customers.resources") 
 end 
 t("customers.services") 
 for user in @customer.users.active 
 render(:partial => "/users/user", :locals => { :show_avatar => false, :user => user }) 
 end 
 for user in @customer.users.where(:active => false) 
 render(:partial => "/users/user", :locals => { :show_avatar => false, :user => user }) 
 end 
 if current_user.company.use_score_rules? 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
container_name 
 container_id 

end
 
 end 
 for @org_unit in @customer.organizational_units.active 
 link_to(@org_unit, edit_organizational_unit_path(@org_unit)) 
 end 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 service_level_agreement.id 
 link_to service_level_agreement.customer.name, edit_customer_path(service_level_agreement.customer) 
 link_to service_level_agreement.service.name, edit_service_path(service_level_agreement.service) 
 check_box_tag "billable", true, service_level_agreement.billable 
 t("service_level_agreements.billable") 
 image_tag("indicator.gif ", :class => "ajax hide")
 t("service_level_agreements.saved") 
 link_to "#", :class => "delete" do 
 end 

end
 
 if current_user.use_resources? 
 resources_without_parents(@customer.resources).each do |r| 
 render(:partial => "/resources/resource", :locals => { :resource => r, :depth => 0 }) 
 end 
 end 
 if @customer.projects.in_progress.size > 0 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 link_to_tasks_filtered_by project, :class => "pull-left name" 
 number_to_percentage(project.progress, :precision => 0) 
 if current_user.can?(project, 'grant') || current_user.can?(project, 'milestone') 
 link_to '<i class="icon-pencil"></i>'.html_safe, { :controller => 'projects', :action => 'edit', :id => project },
        :class => "pull-left hide action", :rel => "tooltip", :title => t("projects.edit_project_html", project: escape_twice(project.name)) 
 end 
 if current_user.can?(project, 'see_unwatched') 
 link_to '<i class="icon-list-alt"></i>'.html_safe, { :controller => 'projects', :action => 'show', :id => project },
        :class => "pull-left hide action", :rel => "tooltip", :title => t("projects.view_project_html", project: escape_twice(project.name)) 
 end 
 for milestone in project.milestones.active.scheduled.order("due_at, milestones.name").includes(:user) 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 milestone.due_at ? milestone.due_at.strftime("%a, %d %b %Y") : t("milestones.unscheduled") 
 link_to_milestone milestone 
 milestone_status_tag(milestone) 
 if current_user.can?(milestone.project, 'milestone') 
 link_to '<i class="icon-pencil"></i>'.html_safe, edit_milestone_path(milestone), :class => "hide action" 
 end 
 milestone.description 
 number_to_percentage(milestone.percent_complete, :precision => 0)  

end
end 
 for milestone in project.milestones.active.unscheduled.order("due_at, milestones.name").includes(:user) 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 milestone.due_at ? milestone.due_at.strftime("%a, %d %b %Y") : t("milestones.unscheduled") 
 link_to_milestone milestone 
 milestone_status_tag(milestone) 
 if current_user.can?(milestone.project, 'milestone') 
 link_to '<i class="icon-pencil"></i>'.html_safe, edit_milestone_path(milestone), :class => "hide action" 
 end 
 milestone.description 
 number_to_percentage(milestone.percent_complete, :precision => 0)  

end
end 
 if project.completed_milestones_count > 0 
 t("projects.n_completed_milestones", n: project.completed_milestones_count) 
 end

end
 
 else 
 t("customers.no_project_in_process") 
 end 
 if @customer.projects.completed.size > 0 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 link_to_tasks_filtered_by project, :class => "pull-left name" 
 number_to_percentage(project.progress, :precision => 0) 
 if current_user.can?(project, 'grant') || current_user.can?(project, 'milestone') 
 link_to '<i class="icon-pencil"></i>'.html_safe, { :controller => 'projects', :action => 'edit', :id => project },
        :class => "pull-left hide action", :rel => "tooltip", :title => t("projects.edit_project_html", project: escape_twice(project.name)) 
 end 
 if current_user.can?(project, 'see_unwatched') 
 link_to '<i class="icon-list-alt"></i>'.html_safe, { :controller => 'projects', :action => 'show', :id => project },
        :class => "pull-left hide action", :rel => "tooltip", :title => t("projects.view_project_html", project: escape_twice(project.name)) 
 end 
 for milestone in project.milestones.active.scheduled.order("due_at, milestones.name").includes(:user) 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 milestone.due_at ? milestone.due_at.strftime("%a, %d %b %Y") : t("milestones.unscheduled") 
 link_to_milestone milestone 
 milestone_status_tag(milestone) 
 if current_user.can?(milestone.project, 'milestone') 
 link_to '<i class="icon-pencil"></i>'.html_safe, edit_milestone_path(milestone), :class => "hide action" 
 end 
 milestone.description 
 number_to_percentage(milestone.percent_complete, :precision => 0)  

end
end 
 for milestone in project.milestones.active.unscheduled.order("due_at, milestones.name").includes(:user) 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 milestone.due_at ? milestone.due_at.strftime("%a, %d %b %Y") : t("milestones.unscheduled") 
 link_to_milestone milestone 
 milestone_status_tag(milestone) 
 if current_user.can?(milestone.project, 'milestone') 
 link_to '<i class="icon-pencil"></i>'.html_safe, edit_milestone_path(milestone), :class => "hide action" 
 end 
 milestone.description 
 number_to_percentage(milestone.percent_complete, :precision => 0)  

end
end 
 if project.completed_milestones_count > 0 
 t("projects.n_completed_milestones", n: project.completed_milestones_count) 
 end

end
 
 else 
 t("customers.no_project_completed") 
 end 
 @customer.id 

  end

  def update
    @customer = Customer.from_company(current_user.company_id).find(params[:id])

    if @customer.update_attributes(params[:customer])
      flash[:success] = t('flash.notice.model_updated', model: Customer.model_name.human)
      redirect_to :action => :edit, :id => @customer.id
    else
      render :edit
    end
  end

  def destroy
    @customer = Customer.from_company(current_user.company_id).find(params[:id])

    case
    when @customer.has_projects?
      flash[:error] = t('flash.error.destroy_dependents_of_model',
                        dependents: @customer.human_name(:projects),
                        model: @customer.name)

    when @customer == current_company.internal_customer
      flash[:error] = t('error.company.delete_own_company')

    else
      flash[:success] = t('flash.notice.model_deleted', model: Customer.model_name.human)
      @customer.destroy
    end

    redirect_to root_path
  end

  ###
  # Returns the list to use for auto completes for customer names.
  ###
  def auto_complete_for_customer_name
    text = params[:term]
    if !text.blank?
      customer_table = Customer.arel_table
      @customers = current_user.company.customers.order('name').where(customer_table[:name].matches("#{text}%").or(customer_table[:name].matches("%#{text}%"))).limit(50)
      render :json=> @customers.collect{|customer| {:value => customer.name, :id=> customer.id} }.to_json
    else
      render :nothing=> true
    end
  end

  def search
    search_criteria = params[:term].strip

    @customers = []
    @users = []
    @tasks = []
    @projects = []
    @resources = []
    @limit = 5
    unless search_criteria.blank?
      if search_criteria.to_i > 0

        @tasks = TaskRecord.all_accessed_by(current_user).where(:task_num => search_criteria)
      elsif params[:entity]
        @limit = 100000
        if params[:entity] =~ /user/
          @users = current_user.company.users.where('lower(name) LIKE ?', '%' + search_criteria.downcase + '%').where(:active => true)
        elsif params[:entity] =~ /customer/
          @customers = current_user.company.customers.where('lower(name) LIKE ?', '%' + search_criteria.downcase + '%').where(:active => true)
        elsif params[:entity] =~ /task/
          @tasks = TaskRecord.all_accessed_by(current_user).where('lower(tasks.name) LIKE ?', '%' + search_criteria.downcase + '%').where("tasks.status = 0")
        elsif params[:entity] =~ /resource/
          @resources = current_user.company.resources.where('lower(name) like ?', '%' + search_criteria.downcase + '%') if current_user.use_resources?
        elsif params[:entity] =~ /project/
          @projects = current_user.projects.where('lower(name) like ?', '%' + search_criteria.downcase + '%')
        end
      else
        @customers = current_user.company.customers.where('lower(name) LIKE ?', '%' + search_criteria.downcase + '%').where(:active => true)
        @users = current_user.company.users.where('lower(name) LIKE ?', '%' + search_criteria.downcase + '%').where(:active => true)
        @tasks = TaskRecord.all_accessed_by(current_user).where('lower(tasks.name) LIKE ?', '%' + search_criteria.downcase + '%').where("tasks.status = 0")
        @resources = current_user.company.resources.where('lower(name) like ?', '%' + search_criteria.downcase + '%') if current_user.use_resources?
        @projects = current_user.projects.where('lower(name) like ?', '%' + search_criteria.downcase + '%')
      end
    end

    html = render_to_string :partial => "customers/search_autocomplete", :locals => {:users => @users, :customers => @customers, :tasks => @tasks, :projects => @projects, :resources => @resources, :limit => @limit }
    render :json=> { :success => true, :html => html }
  end

  private

  def authorize_user_can_create_customers
    deny_access unless Setting.contact_creation_allowed && (current_user.admin? || current_user.create_clients?)
  end

  def authorize_user_can_edit_customers
    deny_access unless current_user.admin? || current_user.edit_clients?
  end

  def authorize_user_can_read_customers
    deny_access unless current_user.admin? || current_user.read_clients?
  end

  def deny_access
    flash[:error] = t('flash.alert.access_denied')
    redirect_from_last
  end
end
