class PasswordResetsController < BaseController
  before_action :require_no_user
  before_action :load_user_using_perishable_token, :only => [ :edit, :update ]

  def new
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 csrf_meta_tag 
 page_title 
 if @meta 
 @meta.each do |key| 
 key[1] 
 key[0] 
 end 
 end 
 if @rss_title && @rss_url 
 auto_discovery_link_tag(:rss, @rss_url, {:title => @rss_title}) 
 end 
  stylesheet_link_tag 'community_engine' 
 if forum_page? 
 unless @feed_icons.blank? 
 @feed_icons.each do |feed| 
 auto_discovery_link_tag :rss, feed[:url], :title => "Subscribe to ''" 
 end 
 end 
 end 
 yield :head_css 
 
 unless configatron.auth_providers.facebook.key.blank? 
  
 end 
  # .navbar-toggle is used as the toggle for when the responsive design gets narrow and the navbar goes away 
 link_to configatron.community_name, home_path, :class => 'navbar-brand' 
  if params[:controller] == 'categories' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 if Category.all.any? 
 categories_path 
 :categories.l 
 for category in Category.order('name') 
 link_to category.name, category 
 end 
 end 
 
  if current_page?(site_clippings_path) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :clippings.l, site_clippings_path 
 
  if params[:controller] == 'events' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :events.l, events_path 
 
  if params[:controller] == 'forums' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :forums.l, forums_path 
 
  if current_page?(popular_path) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :popular.l, popular_path 
 
  if current_page?(users_path) || (params[:controller] == 'users' && !@user.nil? && @user != current_user) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :people.l, users_path 
 
 if @header_tabs.any? 
 for tab in @header_tabs 
 link_to tab.name, tab.url 
 end 
 end 
  if logged_in? 
 if current_user.unread_messages? 
 if params[:controller] == 'messages' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 user_messages_path(current_user) 
 current_user.unread_message_count 
 fa_icon "envelope inverse" 
 end 
 end 
 
  if logged_in? 
 if !current_page?(users_path) && (params[:controller] == 'users' && !@user.nil? && @user == current_user) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 dashboard_user_path(current_user) 
 :logged_in.l + ' ' + current_user.login 
 if current_user.admin? 
 link_to :admin_dashboard.l, admin_dashboard_path 
 end 
 link_to :edit_profile.l, edit_user_path(current_user) 
 link_to :edit_account.l, edit_account_user_path(current_user) 
 link_to :manage_posts.l, manage_user_posts_path(current_user) 
 link_to :inbox.l, user_messages_path(current_user) 
 link_to :my_profile.l, user_path(current_user) 
 link_to :my_blog.l, user_posts_path(current_user) 
 link_to :photo_manager.l, user_photo_manager_index_path(current_user) 
 link_to :my_clippings.l, user_clippings_path(current_user) 
 link_to :my_friends.l, accepted_user_friendships_path(current_user) 
 link_to :log_out.l, logout_path 
 else 
 link_to(:log_in.l, login_path) 
 link_to(:sign_up.l, signup_path) 
 end 
 
 
 render_jumbotron 
 container_title 
  [:notice, :error, :alert].each do |level| 
 unless flash[level].blank? 
 content_tag :p, flash[level] 
 end 
 end 
 
 @page_title=:forgot_your_password.l 
  widget do 
 :help.l 
 :dont_have_an_account.l 
 link_to :click_here_to_sign_up.l, signup_path 
 :forgot_your_password.l 
 link_to :click_here_to_retrieve_it.l, forgot_password_url 
 :forgot_your_username.l 
 link_to :click_here_to_retrieve_it.l, forgot_username_url 
 end 
 
 bootstrap_form_tag :url => password_resets_path, :layout => :horizontal do |f| 
 f.email_field :email, :label => :enter_your_email_address.l 
 f.form_group :submit_group do 
 f.primary :reset_my_password.l 
 end 
 end 
  render_widgets 
 
 if show_footer_content? 
 image_tag 'spinner.gif', :plugin => 'community_engine' 
 :loading_recent_content.l 
 end 
  :home.l 
 if !logged_in? 
 link_to :log_in.l, login_path 
 else 
 :log_out.l 
 end 
 Page.all.each do |page| 
 if (logged_in? ) 
 link_to page.title, pages_path(page) 
 end 
 end 
 if @rss_title && @rss_url 
 link_to :rss.l, @rss_url, {:title => @rss_title} 
 end 
 
 :community_tagline.l 
  javascript_include_tag 'community_engine' 
 tiny_mce_init_if_needed 
 if show_footer_content? 
 end 
 
 yield :end_javascript 

end

  end

  def create
    @user = User.where("lower(email) = ?", params[:email].downcase).first
    if @user
      @user.deliver_password_reset_instructions!

      flash[:notice] = :your_password_reset_instructions_have_been_emailed_to_you.l

      redirect_to login_path
    else
      flash[:error] = :sorry_we_dont_recognize_that_email_address.l

      ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 csrf_meta_tag 
 page_title 
 if @meta 
 @meta.each do |key| 
 key[1] 
 key[0] 
 end 
 end 
 if @rss_title && @rss_url 
 auto_discovery_link_tag(:rss, @rss_url, {:title => @rss_title}) 
 end 
  stylesheet_link_tag 'community_engine' 
 if forum_page? 
 unless @feed_icons.blank? 
 @feed_icons.each do |feed| 
 auto_discovery_link_tag :rss, feed[:url], :title => "Subscribe to ''" 
 end 
 end 
 end 
 yield :head_css 
 
 unless configatron.auth_providers.facebook.key.blank? 
  
 end 
  # .navbar-toggle is used as the toggle for when the responsive design gets narrow and the navbar goes away 
 link_to configatron.community_name, home_path, :class => 'navbar-brand' 
  if params[:controller] == 'categories' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 if Category.all.any? 
 categories_path 
 :categories.l 
 for category in Category.order('name') 
 link_to category.name, category 
 end 
 end 
 
  if current_page?(site_clippings_path) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :clippings.l, site_clippings_path 
 
  if params[:controller] == 'events' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :events.l, events_path 
 
  if params[:controller] == 'forums' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :forums.l, forums_path 
 
  if current_page?(popular_path) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :popular.l, popular_path 
 
  if current_page?(users_path) || (params[:controller] == 'users' && !@user.nil? && @user != current_user) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :people.l, users_path 
 
 if @header_tabs.any? 
 for tab in @header_tabs 
 link_to tab.name, tab.url 
 end 
 end 
  if logged_in? 
 if current_user.unread_messages? 
 if params[:controller] == 'messages' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 user_messages_path(current_user) 
 current_user.unread_message_count 
 fa_icon "envelope inverse" 
 end 
 end 
 
  if logged_in? 
 if !current_page?(users_path) && (params[:controller] == 'users' && !@user.nil? && @user == current_user) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 dashboard_user_path(current_user) 
 :logged_in.l + ' ' + current_user.login 
 if current_user.admin? 
 link_to :admin_dashboard.l, admin_dashboard_path 
 end 
 link_to :edit_profile.l, edit_user_path(current_user) 
 link_to :edit_account.l, edit_account_user_path(current_user) 
 link_to :manage_posts.l, manage_user_posts_path(current_user) 
 link_to :inbox.l, user_messages_path(current_user) 
 link_to :my_profile.l, user_path(current_user) 
 link_to :my_blog.l, user_posts_path(current_user) 
 link_to :photo_manager.l, user_photo_manager_index_path(current_user) 
 link_to :my_clippings.l, user_clippings_path(current_user) 
 link_to :my_friends.l, accepted_user_friendships_path(current_user) 
 link_to :log_out.l, logout_path 
 else 
 link_to(:log_in.l, login_path) 
 link_to(:sign_up.l, signup_path) 
 end 
 
 
 render_jumbotron 
 container_title 
  [:notice, :error, :alert].each do |level| 
 unless flash[level].blank? 
 content_tag :p, flash[level] 
 end 
 end 
 
 @page_title=:forgot_your_password.l 
  widget do 
 :help.l 
 :dont_have_an_account.l 
 link_to :click_here_to_sign_up.l, signup_path 
 :forgot_your_password.l 
 link_to :click_here_to_retrieve_it.l, forgot_password_url 
 :forgot_your_username.l 
 link_to :click_here_to_retrieve_it.l, forgot_username_url 
 end 
 
 bootstrap_form_tag :url => password_resets_path, :layout => :horizontal do |f| 
 f.email_field :email, :label => :enter_your_email_address.l 
 f.form_group :submit_group do 
 f.primary :reset_my_password.l 
 end 
 end 
  render_widgets 
 
 if show_footer_content? 
 image_tag 'spinner.gif', :plugin => 'community_engine' 
 :loading_recent_content.l 
 end 
  :home.l 
 if !logged_in? 
 link_to :log_in.l, login_path 
 else 
 :log_out.l 
 end 
 Page.all.each do |page| 
 if (logged_in? ) 
 link_to page.title, pages_path(page) 
 end 
 end 
 if @rss_title && @rss_url 
 link_to :rss.l, @rss_url, {:title => @rss_title} 
 end 
 
 :community_tagline.l 
  javascript_include_tag 'community_engine' 
 tiny_mce_init_if_needed 
 if show_footer_content? 
 end 
 
 yield :end_javascript 

end

    end
  end

  def edit
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 csrf_meta_tag 
 page_title 
 if @meta 
 @meta.each do |key| 
 key[1] 
 key[0] 
 end 
 end 
 if @rss_title && @rss_url 
 auto_discovery_link_tag(:rss, @rss_url, {:title => @rss_title}) 
 end 
  stylesheet_link_tag 'community_engine' 
 if forum_page? 
 unless @feed_icons.blank? 
 @feed_icons.each do |feed| 
 auto_discovery_link_tag :rss, feed[:url], :title => "Subscribe to ''" 
 end 
 end 
 end 
 yield :head_css 
 
 unless configatron.auth_providers.facebook.key.blank? 
  
 end 
  # .navbar-toggle is used as the toggle for when the responsive design gets narrow and the navbar goes away 
 link_to configatron.community_name, home_path, :class => 'navbar-brand' 
  if params[:controller] == 'categories' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 if Category.all.any? 
 categories_path 
 :categories.l 
 for category in Category.order('name') 
 link_to category.name, category 
 end 
 end 
 
  if current_page?(site_clippings_path) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :clippings.l, site_clippings_path 
 
  if params[:controller] == 'events' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :events.l, events_path 
 
  if params[:controller] == 'forums' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :forums.l, forums_path 
 
  if current_page?(popular_path) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :popular.l, popular_path 
 
  if current_page?(users_path) || (params[:controller] == 'users' && !@user.nil? && @user != current_user) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :people.l, users_path 
 
 if @header_tabs.any? 
 for tab in @header_tabs 
 link_to tab.name, tab.url 
 end 
 end 
  if logged_in? 
 if current_user.unread_messages? 
 if params[:controller] == 'messages' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 user_messages_path(current_user) 
 current_user.unread_message_count 
 fa_icon "envelope inverse" 
 end 
 end 
 
  if logged_in? 
 if !current_page?(users_path) && (params[:controller] == 'users' && !@user.nil? && @user == current_user) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 dashboard_user_path(current_user) 
 :logged_in.l + ' ' + current_user.login 
 if current_user.admin? 
 link_to :admin_dashboard.l, admin_dashboard_path 
 end 
 link_to :edit_profile.l, edit_user_path(current_user) 
 link_to :edit_account.l, edit_account_user_path(current_user) 
 link_to :manage_posts.l, manage_user_posts_path(current_user) 
 link_to :inbox.l, user_messages_path(current_user) 
 link_to :my_profile.l, user_path(current_user) 
 link_to :my_blog.l, user_posts_path(current_user) 
 link_to :photo_manager.l, user_photo_manager_index_path(current_user) 
 link_to :my_clippings.l, user_clippings_path(current_user) 
 link_to :my_friends.l, accepted_user_friendships_path(current_user) 
 link_to :log_out.l, logout_path 
 else 
 link_to(:log_in.l, login_path) 
 link_to(:sign_up.l, signup_path) 
 end 
 
 
 render_jumbotron 
 container_title 
  [:notice, :error, :alert].each do |level| 
 unless flash[level].blank? 
 content_tag :p, flash[level] 
 end 
 end 
 
 @page_title=:forgot_your_password.l 
 bootstrap_form_tag :url => password_reset_path, :method => :put, :layout => :horizontal do |f| 
 f.password_field :password 
 f.password_field :password_confirmation, :label => :confirm_password.l 
 f.form_group :submit_group do 
 f.primary :reset_my_password.l 
 end 
 end 
  render_widgets 
 
 if show_footer_content? 
 image_tag 'spinner.gif', :plugin => 'community_engine' 
 :loading_recent_content.l 
 end 
  :home.l 
 if !logged_in? 
 link_to :log_in.l, login_path 
 else 
 :log_out.l 
 end 
 Page.all.each do |page| 
 if (logged_in? ) 
 link_to page.title, pages_path(page) 
 end 
 end 
 if @rss_title && @rss_url 
 link_to :rss.l, @rss_url, {:title => @rss_title} 
 end 
 
 :community_tagline.l 
  javascript_include_tag 'community_engine' 
 tiny_mce_init_if_needed 
 if show_footer_content? 
 end 
 
 yield :end_javascript 

end

  end

  def update
    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]

    if @user.save
      flash[:notice] = :your_changes_were_saved.l

      redirect_to dashboard_user_path(@user)
    else
      flash[:error] = @user.errors.full_messages.to_sentence
      ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 csrf_meta_tag 
 page_title 
 if @meta 
 @meta.each do |key| 
 key[1] 
 key[0] 
 end 
 end 
 if @rss_title && @rss_url 
 auto_discovery_link_tag(:rss, @rss_url, {:title => @rss_title}) 
 end 
  stylesheet_link_tag 'community_engine' 
 if forum_page? 
 unless @feed_icons.blank? 
 @feed_icons.each do |feed| 
 auto_discovery_link_tag :rss, feed[:url], :title => "Subscribe to ''" 
 end 
 end 
 end 
 yield :head_css 
 
 unless configatron.auth_providers.facebook.key.blank? 
  
 end 
  # .navbar-toggle is used as the toggle for when the responsive design gets narrow and the navbar goes away 
 link_to configatron.community_name, home_path, :class => 'navbar-brand' 
  if params[:controller] == 'categories' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 if Category.all.any? 
 categories_path 
 :categories.l 
 for category in Category.order('name') 
 link_to category.name, category 
 end 
 end 
 
  if current_page?(site_clippings_path) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :clippings.l, site_clippings_path 
 
  if params[:controller] == 'events' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :events.l, events_path 
 
  if params[:controller] == 'forums' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :forums.l, forums_path 
 
  if current_page?(popular_path) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :popular.l, popular_path 
 
  if current_page?(users_path) || (params[:controller] == 'users' && !@user.nil? && @user != current_user) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 link_to :people.l, users_path 
 
 if @header_tabs.any? 
 for tab in @header_tabs 
 link_to tab.name, tab.url 
 end 
 end 
  if logged_in? 
 if current_user.unread_messages? 
 if params[:controller] == 'messages' 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 css_class 
 user_messages_path(current_user) 
 current_user.unread_message_count 
 fa_icon "envelope inverse" 
 end 
 end 
 
  if logged_in? 
 if !current_page?(users_path) && (params[:controller] == 'users' && !@user.nil? && @user == current_user) 
 css_class = 'active' 
 else 
 css_class = 'inactive' 
 end 
 dashboard_user_path(current_user) 
 :logged_in.l + ' ' + current_user.login 
 if current_user.admin? 
 link_to :admin_dashboard.l, admin_dashboard_path 
 end 
 link_to :edit_profile.l, edit_user_path(current_user) 
 link_to :edit_account.l, edit_account_user_path(current_user) 
 link_to :manage_posts.l, manage_user_posts_path(current_user) 
 link_to :inbox.l, user_messages_path(current_user) 
 link_to :my_profile.l, user_path(current_user) 
 link_to :my_blog.l, user_posts_path(current_user) 
 link_to :photo_manager.l, user_photo_manager_index_path(current_user) 
 link_to :my_clippings.l, user_clippings_path(current_user) 
 link_to :my_friends.l, accepted_user_friendships_path(current_user) 
 link_to :log_out.l, logout_path 
 else 
 link_to(:log_in.l, login_path) 
 link_to(:sign_up.l, signup_path) 
 end 
 
 
 render_jumbotron 
 container_title 
  [:notice, :error, :alert].each do |level| 
 unless flash[level].blank? 
 content_tag :p, flash[level] 
 end 
 end 
 
 @page_title=:forgot_your_password.l 
 bootstrap_form_tag :url => password_reset_path, :method => :put, :layout => :horizontal do |f| 
 f.password_field :password 
 f.password_field :password_confirmation, :label => :confirm_password.l 
 f.form_group :submit_group do 
 f.primary :reset_my_password.l 
 end 
 end 
  render_widgets 
 
 if show_footer_content? 
 image_tag 'spinner.gif', :plugin => 'community_engine' 
 :loading_recent_content.l 
 end 
  :home.l 
 if !logged_in? 
 link_to :log_in.l, login_path 
 else 
 :log_out.l 
 end 
 Page.all.each do |page| 
 if (logged_in? ) 
 link_to page.title, pages_path(page) 
 end 
 end 
 if @rss_title && @rss_url 
 link_to :rss.l, @rss_url, {:title => @rss_title} 
 end 
 
 :community_tagline.l 
  javascript_include_tag 'community_engine' 
 tiny_mce_init_if_needed 
 if show_footer_content? 
 end 
 
 yield :end_javascript 

end

    end
  end


  private

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash[:error] = :an_error_occurred.l
      redirect_to login_path
    end
  end

end
