class Projects::ProtectedBranchesController < Projects::ApplicationController
  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_admin_project!

  layout "project_settings"

  def index
    @branches = @project.protected_branches.to_a
    @protected_branch = @project.protected_branches.new
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 page_title  "Settings" 
 nav         "project" 
  page_title       @project.name_with_namespace 
 page_description @project.description    unless page_description 
 header_title     project_title(@project) unless header_title 
 nav              "project" 
 content_for :scripts_body_top do 
 project = @target_project || @project 
 if @project_wiki 
 markdown_preview_path = namespace_project_wikis_markdown_preview_path(project.namespace, project) 
 else 
 markdown_preview_path = markdown_preview_namespace_project_path(project.namespace, project) 
 end 
 if current_user 
 end 
 end 
 content_for :scripts_body do 
  project = @target_project || @project 
 if @noteable 
 end 
 
 end 
 content_for :header_content do 
 dropdown_title("Go to a project") 
 dropdown_filter("Search your projects") 
 dropdown_content 
 dropdown_loading 
 end 
   page_description brand_title unless page_description 
 site_name = "GitLab" 
 # Open Graph - http://ogp.me/ 
 site_name 
 page_title 
 page_description 
 page_image 
 request.base_url 
 # Twitter Card - https://dev.twitter.com/cards/types/summary 
 page_title 
 page_description 
 page_image 
 page_card_meta_tags 
 page_title(site_name) 
 page_description 
 favicon_link_tag 'favicon.ico' 
 stylesheet_link_tag "application", media: "all" 
 stylesheet_link_tag "print",       media: "print" 
 javascript_include_tag "application" 
 if page_specific_javascripts 
 javascript_include_tag page_specific_javascripts, {"data-turbolinks-track" => true} 
 end 
 csrf_meta_tags 
 unless browser.safari? 
 end 
 # Apple Safari/iOS home screen icons 
 favicon_link_tag 'touch-icon-iphone.png',        rel: 'apple-touch-icon' 
 favicon_link_tag 'touch-icon-ipad.png',          rel: 'apple-touch-icon', sizes: '76x76' 
 favicon_link_tag 'touch-icon-iphone-retina.png', rel: 'apple-touch-icon', sizes: '120x120' 
 favicon_link_tag 'touch-icon-ipad-retina.png',   rel: 'apple-touch-icon', sizes: '152x152' 
 image_path('logo.svg') 
 # Windows 8 pinned site tile 
 image_path('msapplication-tile.png') 
 yield :meta_tags 
  
  
  
  
 
 Gon::Base.render_data 
 # Ideally this would be inside the head, but turbolinks only evaluates page-specific JS in the body. 
 yield :scripts_body_top 
  nav_header_class 
 icon('bars') 
 icon('angle-left') 
  page_title    "Search" 
 header_title  "Search", search_path 
 render template: "layouts/application" 
 
 link_to search_path, title: 'Search', data: {toggle: 'tooltip', placement: 'bottom', container: 'body'} do 
 icon('search') 
 end 
 if current_user 
 if session[:impersonator_id] 
 link_to admin_impersonation_path, method: :delete, title: 'Stop Impersonation', data: { toggle: 'tooltip', placement: 'bottom', container: 'body' } do 
 icon('user-secret fw') 
 end 
 end 
 if current_user.is_admin? 
 link_to admin_root_path, title: 'Admin Area', data: {toggle: 'tooltip', placement: 'bottom', container: 'body'} do 
 icon('wrench fw') 
 end 
 end 
 link_to dashboard_todos_path, title: 'Todos', data: {toggle: 'tooltip', placement: 'bottom', container: 'body'} do 
 icon('bell fw') 
 unless todos_pending_count == 0 
 todos_pending_count 
 end 
 end 
 if current_user.can_create_project? 
 link_to new_project_path, title: 'New project', data: {toggle: 'tooltip', placement: 'bottom', container: 'body'} do 
 icon('plus fw') 
 end 
 end 
 if Gitlab::Sherlock.enabled? 
 link_to sherlock_transactions_path, title: 'Sherlock Transactions',                  data: {toggle: 'tooltip', placement: 'bottom', container: 'body'} do 
 icon('tachometer fw') 
 end 
 end 
 link_to destroy_user_session_path, class: 'logout', method: :delete, title: 'Sign out', data: {toggle: 'tooltip', placement: 'bottom', container: 'body'} do 
 icon('sign-out') 
 end 
 else 
 link_to "Sign in", new_session_path(:user, redirect_to_referer: 'yes'), class: 'btn btn-sign-in btn-success' 
 end 
 title 
 yield :header_content 
  if outdated_browser? 
 link = "https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/install/requirements.md#supported-web-browsers" 
 link_to 'supported web browser', link 
 end 
 
 if @project && !@project.empty_repo? 
 if ref = @ref || @project.repository.root_ref 
 end 
 end 
 
  nav_sidebar_class 
 brand_header_logo 
 link_to root_path, class: 'gitlab-text-container-link', title: 'Dashboard', id: 'js-shortcuts-home' do 
 end 
 if defined?(sidebar) && sidebar 
 render "layouts/nav/" 
 elsif current_user 
  nav_link(path: ['root#index', 'projects#trending', 'projects#starred', 'dashboard/projects#index'], html_options: {}) do 
 link_to dashboard_projects_path, title: 'Projects', class: 'dashboard-shortcuts-projects' do 
 icon('bookmark fw') 
 end 
 end 
 nav_link(controller: :todos) do 
 link_to dashboard_todos_path, title: 'Todos' do 
 icon('bell fw') 
 number_with_delimiter(todos_pending_count) 
 end 
 end 
 nav_link(path: 'dashboard#activity') do 
 link_to activity_dashboard_path, class: 'dashboard-shortcuts-activity', title: 'Activity' do 
 icon('dashboard fw') 
 end 
 end 
 nav_link(controller: [:groups, 'groups/milestones', 'groups/group_members']) do 
 link_to dashboard_groups_path, title: 'Groups' do 
 icon('group fw') 
 end 
 end 
 nav_link(controller: 'dashboard/milestones') do 
 link_to dashboard_milestones_path, title: 'Milestones' do 
 icon('clock-o fw') 
 end 
 end 
 nav_link(path: 'dashboard#issues') do 
 link_to assigned_issues_dashboard_path, title: 'Issues', class: 'dashboard-shortcuts-issues' do 
 icon('exclamation-circle fw') 
 number_with_delimiter(current_user.assigned_open_issues_count) 
 end 
 end 
 nav_link(path: 'dashboard#merge_requests') do 
 link_to assigned_mrs_dashboard_path, title: 'Merge Requests', class: 'dashboard-shortcuts-merge_requests' do 
 icon('tasks fw') 
 number_with_delimiter(current_user.assigned_open_merge_request_count) 
 end 
 end 
 nav_link(controller: :snippets) do 
 link_to dashboard_snippets_path, title: 'Snippets' do 
 icon('clipboard fw') 
 end 
 end 
 nav_link(controller: :help) do 
 link_to help_path, title: 'Help' do 
 icon('question-circle fw') 
 end 
 end 
 nav_link(html_options: {class: profile_tab_class}) do 
 link_to profile_path, title: 'Profile Settings', data: {placement: 'bottom'} do 
 icon('user fw') 
 end 
 end 
 
 else 
  nav_link(path: ['dashboard#show', 'root#show', 'projects#trending', 'projects#starred', 'projects#index'], html_options: {class: 'home'}) do 
 link_to explore_root_path, title: 'Projects' do 
 icon('bookmark fw') 
 end 
 end 
 nav_link(controller: [:groups, 'groups/milestones', 'groups/group_members']) do 
 link_to explore_groups_path, title: 'Groups' do 
 icon('group fw') 
 end 
 end 
 nav_link(controller: :snippets) do 
 link_to explore_snippets_path, title: 'Snippets' do 
 icon('clipboard fw') 
 end 
 end 
 nav_link(controller: :help) do 
 link_to help_path, title: 'Help' do 
 icon('question-circle fw') 
 end 
 end 
 
 end 
  if nav_menu_collapsed? 
 link_to icon('angle-right'), '#', class: 'toggle-nav-collapse', title: "Open/Close" 
 else 
 link_to icon('angle-left'), '#', class: 'toggle-nav-collapse', title: "Open/Close" 
 end 
 
 if current_user 
 link_to current_user, class: 'sidebar-user', title: "Profile" do 
 image_tag avatar_icon(current_user, 60), alt: 'Profile', class: 'avatar avatar s36' 
 current_user.username 
 end 
 end 
 if defined?(nav) && nav 
 render "layouts/nav/" 
 end 
  broadcast_message 
 
  if alert 
 alert 
 elsif notice 
 notice 
 end 
 
 yield :flash_message 
 (container_class unless @no_container) 
 page_title "Protected branches" 
 page_title 
 if can? current_user, :admin_project, @project 
 form_for [@project.namespace.becomes(Namespace), @project, @protected_branch] do |f| 
 form_errors(@protected_branch) 
 f.label :name, "Branch", class: "label-light" 
 f.select(:name, @project.open_branches.map { |br| [br.name, br.name] } , {include_blank: true}, {}) 
 f.check_box :developers_can_push, class: "pull-left" 
 f.label :developers_can_push, "Developers can push", class: "label-light append-bottom-0" 
 f.submit "Protect", class: "btn-create btn" 
 end 
 end 
  if @branches.empty? 
 else 
 can_admin_project = can?(current_user, :admin_project, @project) 
 if can_admin_project 
 end 
 if can_admin_project 
 end 
 @branches.each do |branch| 
 @url = namespace_project_protected_branch_path(@project.namespace, @project, branch) 
 link_to(branch.name, namespace_project_commits_path(@project.namespace, @project, branch.name)) 
 if @project.root_ref?(branch.name) 
 end 
 if commit = branch.commit 
 link_to(commit.short_id, namespace_project_commit_path(@project.namespace, @project, commit.id), class: 'commit_short_id') 
 else 
 end 
 check_box_tag("developers_can_push", branch.id, branch.developers_can_push, data: { url: @url }) 
 if can_admin_project 
 link_to 'Unprotect', [@project.namespace.becomes(Namespace), @project, branch], data: { confirm: 'Branch will be writable for developers. Are you sure?' }, method: :delete, class: "btn btn-warning btn-sm" 
 end 
 end 
 end 
 
 
 yield :scripts_body 
 
 

end

  end

  def create
    @project.protected_branches.create(protected_branch_params)
    redirect_to namespace_project_protected_branches_path(@project.namespace,
                                                          @project)
  end

  def update
    protected_branch = @project.protected_branches.find(params[:id])

    if protected_branch &&
       protected_branch.update_attributes(
         developers_can_push: params[:developers_can_push]
       )

      respond_to do |format|
        format.json { render json: protected_branch, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: protected_branch.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @project.protected_branches.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to namespace_project_protected_branches_path }
      format.js { head :ok }
    end
  end

  private

  def protected_branch_params
    params.require(:protected_branch).permit(:name, :developers_can_push)
  end
end
