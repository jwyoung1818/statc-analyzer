class Import::BitbucketController < Import::BaseController
  before_action :verify_bitbucket_import_enabled
  before_action :bitbucket_auth, except: :callback

  rescue_from OAuth::Error, with: :bitbucket_unauthorized
  rescue_from Gitlab::BitbucketImport::Client::Unauthorized, with: :bitbucket_unauthorized

  def callback
    request_token = session.delete(:oauth_request_token)
    raise "Session expired!" if request_token.nil?

    request_token.symbolize_keys!

    access_token = client.get_token(request_token, params[:oauth_verifier], callback_import_bitbucket_url)

    session[:bitbucket_access_token] = access_token.token
    session[:bitbucket_access_token_secret] = access_token.secret

    redirect_to status_import_bitbucket_url
  end

  def status
    @repos = client.projects
    @incompatible_repos = client.incompatible_projects

    @already_added_projects = current_user.created_projects.where(import_type: "bitbucket")
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.to_a.reject!{ |repo| already_added_projects_names.include? "#{repo["owner"]}/#{repo["slug"]}" }
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 render "layouts/head" 
 # Ideally this would be inside the head, but turbolinks only evaluates page-specific JS in the body. 
 yield :scripts_body_top 
  nav_header_class 
 icon('bars') 
 icon('angle-left') 
  page_title    "Search" 
 header_title  "Search", search_path 
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
 csrf_meta_tags 
 include_gon 
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
  
  
  
  
 
 # Ideally this would be inside the head, but turbolinks only evaluates page-specific JS in the body. 
 yield :scripts_body_top 
 render "layouts/header/default", title: header_title 
 render 'layouts/page', sidebar: sidebar, nav: nav 
 yield :scripts_body 
 
 
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
 
   broadcast_message 
 
 nav_sidebar_class 
 brand_header_logo 
 link_to root_path, class: 'gitlab-text-container-link', title: 'Dashboard', id: 'js-shortcuts-home' do 
 end 
 if defined?(sidebar) && sidebar 
 render "layouts/nav/" 
 elsif current_user 
  nav_link(path: ['root#index', 'projects#trending', 'projects#starred', 'dashboard/projects#index'], html_options: {class: 'home'}) do 
 link_to dashboard_projects_path, title: 'Projects' do 
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
 link_to activity_dashboard_path, class: 'shortcuts-activity', title: 'Activity' do 
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
 link_to assigned_issues_dashboard_path, title: 'Issues', class: 'shortcuts-issues' do 
 icon('exclamation-circle fw') 
 number_with_delimiter(current_user.assigned_issues.opened.count) 
 end 
 end 
 nav_link(path: 'dashboard#merge_requests') do 
 link_to assigned_mrs_dashboard_path, title: 'Merge Requests', class: 'shortcuts-merge_requests' do 
 icon('tasks fw') 
 number_with_delimiter(current_user.assigned_merge_requests.opened.count) 
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
  if alert 
 alert 
 elsif notice 
 notice 
 end 
 
 yield :flash_message 
 (container_class unless @no_container) 
 page_title "Bitbucket import" 
 header_title "Projects", root_path 
 if @repos.any? 
 if @incompatible_repos.any? 
 button_tag class: "btn btn-import btn-success js-import-all" do 
 icon("spinner spin", class: "loading-icon") 
 end 
 else 
 button_tag class: "btn btn-success js-import-all" do 
 icon("spinner spin", class: "loading-icon") 
 end 
 end 
 end 
 @already_added_projects.each do |project| 
 link_to project.import_source, "https://bitbucket.org/", target: "_blank" 
 link_to project.path_with_namespace, [project.namespace.becomes(Namespace), project] 
 if project.import_status == 'finished' 
 elsif project.import_status == 'started' 
 else 
 project.human_import_status_name 
 end 
 end 
 @repos.each do |repo| 
 link_to "/", "https://bitbucket.org//", target: "_blank" 
 "/" 
 button_tag class: "btn btn-import js-add-to-import" do 
 icon("spinner spin", class: "loading-icon") 
 end 
 end 
 @incompatible_repos.each do |repo| 
 link_to "/", "https://bitbucket.org//", target: "_blank" 
 label_tag "Incompatible Project", nil, class: "label label-danger" 
 end 
 if @incompatible_repos.any? 
 link_to "them to Git,", "https://www.atlassian.com/git/tutorials/migrating-overview" 
 link_to "import flow", status_import_bitbucket_path, "data-no-turbolink" => "true" 
 end 
 
 yield :scripts_body 

end

  end

  def jobs
    jobs = current_user.created_projects.where(import_type: "bitbucket").to_json(only: [:id, :import_status])
    render json: jobs
  end

  def create
    @repo_id = params[:repo_id] || ""
    repo = client.project(@repo_id.gsub("___", "/"))
    @project_name = repo["slug"]

    repo_owner = repo["owner"]
    repo_owner = current_user.username if repo_owner == client.user["user"]["username"]
    @target_namespace = params[:new_namespace].presence || repo_owner

    namespace = get_or_create_namespace

    unless Gitlab::BitbucketImport::KeyAdder.new(repo, current_user, access_params).execute
      @access_denied = true
      render
      return
    end

    @project = Gitlab::BitbucketImport::ProjectCreator.new(repo, namespace, current_user, access_params).execute
  end

  private

  def client
    @client ||= Gitlab::BitbucketImport::Client.new(session[:bitbucket_access_token],
                                                    session[:bitbucket_access_token_secret])
  end

  def verify_bitbucket_import_enabled
    render_404 unless bitbucket_import_enabled?
  end

  def bitbucket_auth
    if session[:bitbucket_access_token].blank?
      go_to_bitbucket_for_permissions
    end
  end

  def go_to_bitbucket_for_permissions
    request_token = client.request_token(callback_import_bitbucket_url)
    session[:oauth_request_token] = request_token

    redirect_to client.authorize_url(request_token, callback_import_bitbucket_url)
  end

  def bitbucket_unauthorized
    go_to_bitbucket_for_permissions
  end

  private

  def access_params
    {
      bitbucket_access_token: session[:bitbucket_access_token],
      bitbucket_access_token_secret: session[:bitbucket_access_token_secret]
    }
  end
end
