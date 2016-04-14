class PhotoManagerController < BaseController
  include Viewable
  before_action :login_required
  before_action :find_user
  before_action :require_current_user
  
  def index
    @albums = current_user.albums.order('id DESC').page(params[:page_albums])
    @photos_no_albums = current_user.photos.where('album_id IS NULL').order('id DESC').page(params[:page])
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
 
 @page_title = :photo_manager.l 
 widget do 
 :links.l 
 link_to :view_all_my_photos.l, user_photos_path(current_user) 
 link_to :new_photo.l, new_user_photo_path(current_user) 
 link_to :new_album.l, new_user_album_path(current_user) 
 end 
 :albums.l 
 :title.l 
 :preview.l 
 :created_at.l 
 :actions.l 
 @albums.each do |album| 
 link_to album.title, user_album_path(current_user,album) 
 if album.photos[0] 
 link_to image_tag( album.photos[0].photo.url(:thumb), :size => "50x50"), user_photo_path(current_user, album.photos[0]) 
 end 
 if album.photos[1] 
 link_to image_tag( album.photos[1].photo.url(:thumb), :size => "50x50"), user_photo_path(current_user, album.photos[1]) 
 end 
 if album.photos[2] 
 link_to image_tag( album.photos[2].photo.url(:thumb), :size => "50x50"), user_photo_path(current_user, album.photos[2]) 
 end 
 end 
 album.created_at.strftime("%Y/%m/%d") 
 link_to :show.l, user_album_path(current_user,album), :class => 'btn btn-default' 
 link_to :edit.l, edit_user_album_path(current_user,album), :class => 'btn btn-warning' 
 link_to :add_photos.l, new_user_album_photo_path(current_user,album), :class => 'btn btn-primary' 
 link_to :delete.l, user_album_path(current_user,album), data: { confirm: :delete_album_and_photos.l }, :method => :delete, :class => 'btn btn-danger' 
 paginate @albums, :theme => 'bootstrap' 
 link_to :new_album.l, new_user_album_path(current_user), :class => 'btn btn-success' 
 :not_assigned_photos.l 
 @photos_no_albums.each do |photo| 
 link_to image_tag( photo.photo.url(:thumb)), user_photo_path(current_user, photo), :class => 'thumbnail' 
 link_to :show.l, user_photo_path(current_user, photo), :class => 'btn btn-xs btn-default' 
 link_to :edit.l, edit_user_photo_path(current_user, photo), :class => 'btn btn-warning btn-xs' 
 link_to :delete.l, edit_user_photo_path(current_user, photo), data: { confirm: :are_you_sure.l }, :method => :delete, :class => 'btn btn-danger btn-xs' 
 end 
 paginate @photos_no_albums, :theme => 'bootstrap' 
 link_to :new_photo.l, new_user_photo_path(current_user), :class => 'btn btn-success' 
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