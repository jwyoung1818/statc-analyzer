class PostsController < BaseController
  include Viewable

  uses_tiny_mce do
    {:only => [:new, :edit, :update, :create ], :options => configatron.default_mce_options}
  end

  uses_tiny_mce do
    {:only => [:show], :options => configatron.simple_mce_options}
  end

  cache_sweeper :post_sweeper, :only => [:create, :update, :destroy]
  cache_sweeper :taggable_sweeper, :only => [:create, :update, :destroy]
  caches_action :show, :if => Proc.new{|c| !logged_in? }

  before_action :login_required, :only => [:new, :edit, :update, :destroy, :create, :manage, :preview]
  before_action :find_user, :only => [:new, :edit, :index, :show, :update_views, :manage, :preview]
  before_action :require_ownership_or_moderator, :only => [:edit, :update, :destroy, :create, :manage, :new]

  skip_before_action :verify_authenticity_token, :only => [:update_views, :send_to_friend] #called from ajax on cached pages

  def manage
    Post.unscoped do
      @search = Post.search(params[:q])
      @posts = @search.result
      @posts = @posts.where(:user_id => @user.id).order('created_at DESC').page(params[:page]).per(params[:size]||10)
    end
 @page_title = :manage_posts.l 
 widget do 
 :search.l 
 bootstrap_form_for @search, :url => manage_user_posts_path(current_user), :html => {:class => "form"} do |f| 
 f.text_field :title_cont, :label => :title.l 
 f.select :category_id_eq, Category.all.collect{|c| [c.name, c.id]}, :include_blank => true, :label => :category.l 
 f.select :published_as_eq, [['Published','live'], ['Draft','draft']], :include_blank => true, :label => :status.l 
 :show.l 
 select_tag :size, options_for_select([['10',10], ['20',20], ['100',100]], params[:size].to_i ) 
 f.primary :search.l 
 end 
 end 
 :posts_saved_with_draft_status_wont_appear_in_your_blog_until_you_publish_them.l 
 sort_link @search, :created_at, :date_created.l 
 sort_link @search, :published_at, :date_published.l 
 :title.l 
 :category.l 
 :tags.l 
 :comments.l 
 :status.l 
 :actions.l 
 @posts.each do |post| 
 post.created_at 
 I18n.l(post.created_at, :format => :published_date) 
 post.published_at 
 post.published_at_display 
 link_to post.title, user_post_path(post.user, post) 
 post.category ? post.category.name : :uncategorized.l 
 post.tags.any? ? post.tag_list : :no_tags.l 
 post.comments.count 
 post.is_live? ? link_to(:published.l, user_post_path(post.user, post)) : :draft.l 
 link_to :show.l, user_post_path(post.user, post), :class => 'btn btn-default' 
 link_to :edit.l, edit_user_post_path(post.user, post), :class => 'btn btn-warning' 
 link_to :delete.l, user_post_path(post.user, post), :method => 'delete', data: { confirm: :are_you_sure.l }, :class => 'btn btn-danger' 
 end 
 paginate @posts, :theme => 'bootstrap' 
 link_to :new_post.l, new_user_post_path(current_user), :class => 'btn btn-success' 

  end

  def index
    @user = User.find(params[:user_id])
    @category = Category.find_by_name(params[:category_name]) if params[:category_name]

    @posts = @user.posts.recent
    @posts = @post.where('category_id = ?', @category.id) if @category
    @posts = @posts.page(params[:page]).per(10)

    @is_current_user = @user.eql?(current_user)

    @popular_posts = @user.posts.order("view_count DESC").limit(10).to_a

    @rss_title = "#{configatron.community_name}: #{@user.login}'s posts"
    @rss_url = user_posts_path(@user,:format => :rss)

    respond_to do |format|
      format.html # index.rhtml
      format.rss {
        render_rss_feed_for(@posts,
           { :feed => {:title => @rss_title, :link => url_for(:controller => 'posts', :action => 'index', :user_id => @user) },
             :item => {:title => :title,
                       :description => :post,
                       :link => Proc.new {|post| user_post_url(post.user, post)},
                       :pub_date => :published_at} })
      }
    end
 @page_title = :users_blog.l(:user => @user.login) 
 render :partial => 'author_profile', :locals => {:user => @user} 
 unless @popular_posts.empty? 
 widget :id => "posts" do 
 :popular_posts.l 
 @popular_posts.each do |post| 
 link_to truncate(post.title, :length => 75), user_post_path(@user, post) 
 end 
 end 
 end 
 @category ? "&raquo; #{link_to(@category.name.upcase, users_posts_in_category_path(@user, @category.name))}".html_safe : '' 
 link_to( :new_post.l, new_user_post_path(@user), {:class => "right"})  if @is_current_user 
 render :partial => 'post', :collection => @posts 
 paginate @posts, :theme => 'bootstrap' 

  end

  # GET /posts/1
  # GET /posts/1.xml
  def show
    @post = Post.unscoped.find(params[:id])
    redirect_to user_posts_path(@user), :alert => :post_not_published_yet.l and return false unless @post.is_live? || @post.user.eql?(current_user) || admin? || moderator?

    @rss_title = "#{configatron.community_name}: #{@user.login}'s posts"
    @rss_url = user_posts_path(@user,:format => :rss)

    @user = @post.user
    @is_current_user = @user.eql?(current_user)
    @comment = Comment.new

    @comments = @post.comments.includes(:user).order('created_at DESC').limit(20).to_a

    @previous = @post.previous_post
    @next = @post.next_post
    @popular_posts = @user.posts.except(:order).order('view_count DESC').limit(10).to_a
    @related = Post.find_related_to(@post)
    @most_commented = Post.find_most_commented
 @section = (@post.category && @post.category.name) 
 @meta = { :title => "#{@post.title}", :description => "#{truncate_words(@post.post, 75, '...' )}", :keywords => "#{@post.tags.join(", ") unless @post.tags.nil?}", :robots => configatron.robots_meta_show_content } 
 render :partial => 'author_profile', :locals => {:user => @user} 
 unless @related.empty? 
 widget do 
 :related_posts.l 
 @related.each do |post| 
 link_to truncate(post.title, :length => 75), user_post_path(post.user, post) 
 end 
 end 
 end 
 unless @popular_posts.empty? 
 widget do 
 :popular_posts.l 
 @popular_posts.each do |post| 
 link_to truncate(post.title, :length => 75), user_post_path(post.user, post) 
 end 
 end 
 end 
 :users_blog.l :user=>  @user.login 
 user_post_path(@user, @post) 
 fa_icon "calendar fw" 
 @post.published_at 
 @post.published_at_display(:literal_date) 
 fa_icon "eye fw", :text => :view_count.l 
 @post.view_count 
 user_post_path(@user, @post) 
 fa_icon "comment fw", :text => :comments.l 
 @post.comments.count 
 if current_user and current_user.can_request_friendship_with(@post.user) 
 add_friend_link(@post.user) 
 end 
 :print_this_story.l 
 fa_icon "print fw", :text => :print.l 
 :email_this_story_to_friends.l 
 fa_icon "envelope fw", :text => :email_to_friends.l 
 sharethis_options(@post) 
 if @is_current_user || admin? || moderator? 
 edit_user_post_path(@post.user, @post) 
 fa_icon "pencil-square-o fw", :text => :edit.l 
 link_to fa_icon("trash-o fw", :text => :delete.l), user_post_path(@post.user, @post), {:method => :delete, data: { confirm: :permanently_delete_this_post.l }, :class => "list-group-item"} 
 end 
 @post.post.html_safe 
 render :partial => 'polls/poll_ui', :locals => {:poll => @post.polls.first} unless @post.polls.empty? 
 unless @post.tags.empty? 
 @post.tags.each do |t| 
 tag_url(t) 
 fa_icon "tag inverse", :text => t.name 
 end 
 end 
 :post_comments.l 
 :add_your_comment.l 
 render :partial => 'comments/comment_form', :locals => {:commentable => @post} 
 render :partial => 'comments/comment', :collection => @comments 
 more_comments_links(@post) 
 content_for :end_javascript do 
 end 

  end

  def update_views
    @post = Post.find(params[:id])
    updated = update_view_count(@post)
    render :text => updated ? 'updated' : 'duplicate'
  end

  def preview
    @post = Post.unscoped.find(params[:id])
    redirect_to(:controller => 'sessions', :action => 'new') and return false unless @post.user.eql?(current_user) || admin? || moderator?
 @page_title = @post.title 
 render :partial => 'author_profile', :locals => {:user => @user} 
 :users_blog.l :user=>  @user.login 
 user_post_path(@user, @post) 
 fa_icon "calendar fw" 
 @post.published_at 
 @post.published_at_display(:literal_date) 
 if @is_current_user || admin? || moderator? 
 edit_user_post_path(@post.user, @post) 
 fa_icon "pencil-square-o fw", :text => :edit.l 
 link_to fa_icon("trash-o fw", :text => :delete.l), user_post_path(@post.user, @post), {:method => :delete, data: { confirm: :permanently_delete_this_post.l }, :class => "list-group-item"} 
 end 
 @post.post 
 render :partial => 'polls/poll_ui', :locals => {:poll => @post.polls.first} unless @post.polls.empty? 
 unless @post.tags.empty? 
 @post.tags.each do |t| 
 tag_url(t) 
 fa_icon "tag inverse", :text => t.name 
 end 
 end 

  end

  # GET /posts/new
  def new
    @user = User.find(params[:user_id])
    @post = Post.new
    @post.category = Category.find(params[:category_id]) if params[:category_id]
    @post.published_as = 'live'
    @categories = Category.all
 @page_title = @post.category ? (:new_post_for_category.l :category => @post.category.name) : :new_post.l 
 widget :id => 'category_tips' do 
 if @post.category 
 render :partial => "categories/tips", :locals => {:category => @post.category} 
 else  
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 

 if !category.nil? && !category.tips.blank? 
 category.name 
 category.tips 
 else  
 :we_need_you.l 
 :every_person_has_something_to_say.l 
 end 


end

 
 end 
 end 
 link_to :back.l, manage_user_posts_path(@user), :class => 'btn btn-default' 
 render 'form' 

  end

  # GET /posts/1;edit
  def edit
    @post = Post.unscoped.find(params[:id])
 @page_title = :editing_post.l 
 widget :id => 'category_tips' do 
 if @post.category 
 render :partial => "categories/tips", :locals => {:category => @post.category} 
 else 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 

 if !category.nil? && !category.tips.blank? 
 category.name 
 category.tips 
 else  
 :we_need_you.l 
 :every_person_has_something_to_say.l 
 end 


end

 
 end 
 end 
 link_to :back.l, manage_user_posts_path(@post.user), :class => 'btn btn-default' 
 link_to :show.l, user_post_path(@post.user, @post), :class => 'btn btn-primary' 
 link_to :delete.l, user_post_path(@post.user, @post), :method => 'delete', data: { confirm: :are_you_sure.l }, :class => 'btn btn-danger' 
 render 'form' 

  end

  # POST /posts
  # POST /posts.xml
  def create
    @user = User.find(params[:user_id])
    @post = Post.new(post_params)
    @post.user = @user

    respond_to do |format|
      if @post.save
        @post.create_poll(params[:poll], params[:choices]) if params[:poll]

        flash[:notice] = @post.category ? :post_created_for_category.l_with_args(:category => @post.category.name.singularize) : :your_post_was_successfully_created.l
        format.html {
          if @post.is_live?
            redirect_to @post.category ? category_path(@post.category) : user_post_path(@user, @post)
          else
            redirect_to manage_user_posts_path(@user)
          end
        }
        format.js
      else
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view| 

 @page_title = @post.category ? (:new_post_for_category.l :category => @post.category.name) : :new_post.l 
 widget :id => 'category_tips' do 
 if @post.category 
 render :partial => "categories/tips", :locals => {:category => @post.category} 
 else  
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 

 if !category.nil? && !category.tips.blank? 
 category.name 
 category.tips 
 else  
 :we_need_you.l 
 :every_person_has_something_to_say.l 
 end 


end

 
 end 
 end 
 link_to :back.l, manage_user_posts_path(@user), :class => 'btn btn-default' 
 render 'form' 


end

 }
        format.js
      end
    end
  end

  # patch /posts/1
  # patch /posts/1.xml
  def update
    @post = Post.unscoped.find(params[:id])
    @user = @post.user

    respond_to do |format|
      if @post.update_attributes(post_params)
        @post.update_poll(params[:poll], params[:choices]) if params[:poll]

        format.html { redirect_to user_post_path(@post.user, @post) }
      else
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view| 

 @page_title = :editing_post.l 
 widget :id => 'category_tips' do 
 if @post.category 
 render :partial => "categories/tips", :locals => {:category => @post.category} 
 else 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 

 if !category.nil? && !category.tips.blank? 
 category.name 
 category.tips 
 else  
 :we_need_you.l 
 :every_person_has_something_to_say.l 
 end 


end

 
 end 
 end 
 link_to :back.l, manage_user_posts_path(@post.user), :class => 'btn btn-default' 
 link_to :show.l, user_post_path(@post.user, @post), :class => 'btn btn-primary' 
 link_to :delete.l, user_post_path(@post.user, @post), :method => 'delete', data: { confirm: :are_you_sure.l }, :class => 'btn btn-danger' 
 render 'form' 


end

 }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    @user = User.find(params[:user_id])
    @post = Post.find(params[:id])
    @post.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = :your_post_was_deleted.l
        redirect_to manage_user_posts_url(@user)
        }
    end
  end

  def send_to_friend
    unless params[:emails]
      render :partial => 'posts/send_to_friend', :locals => {:user_id => params[:user_id], :post_id => params[:post_id]} and return
    end
    @post = Post.find(params[:id])
    if @post.send_to(params[:emails], params[:message], (current_user || nil))
      flash[:notice] = "Your message has been sent."
      respond_to do |format|
        format.html {ruby_code_from_view.ruby_code_from_view do |rb_from_view| 



end

}
        format.js
      end
    else
      flash[:error] = "You entered invalid addresses: "+ @post.invalid_emails.join(', ')+". Please correct these and try again."

      respond_to do |format|
        format.html {ruby_code_from_view.ruby_code_from_view do |rb_from_view| 



end

, :status => 500}
        format.js
      end
    end
  end


  def popular
    @posts = Post.find_popular({:limit => 15, :since => 3.days})

    @monthly_popular_posts = Post.find_popular({:limit => 20, :since => 30.days})

    @related_tags = ActsAsTaggableOn::Tag.find_by_sql("SELECT tags.id, tags.name, count(*) AS count
      FROM taggings, tags
      WHERE tags.id = taggings.tag_id GROUP BY tags.id, tags.name");

    @rss_title = "#{configatron.community_name} "+:popular_posts.l
    @rss_url = popular_rss_url
    respond_to do |format|
      format.html # index.rhtml
      format.rss {
        render_rss_feed_for(@posts, { :feed => {:title => @rss_title, :link => popular_url},
          :item => {:title => :title, :link => Proc.new {|post| user_post_url(post.user, post)}, :description => :post, :pub_date => :published_at}
          })
      }
    end

  end

  def recent
    @posts = Post.recent.page(params[:page]).per(20)

    @recent_clippings = Clipping.find_recent(:limit => 15)
    @recent_photos = Photo.find_recent(:limit => 10)

    @rss_title = "#{configatron.community_name} "+:recent_posts.l
    @rss_url = recent_rss_url
    respond_to do |format|
      format.html
      format.rss {
        render_rss_feed_for(@posts, { :feed => {:title => @rss_title, :link => recent_url},
          :item => {:title => :title, :link => Proc.new {|post| user_post_url(post.user, post)}, :description => :post, :pub_date => :published_at}
          })
      }
    end

  end

  def featured
    @posts = Post.by_featured_writers.recent.page(params[:page])
    @featured_writers = User.featured

    @rss_title = "#{configatron.community_name} "+:featured_posts.l
    @rss_url = featured_rss_url
    respond_to do |format|
      format.html
      format.rss {
        render_rss_feed_for(@posts, { :feed => {:title => @rss_title, :link => recent_url},
          :item => {:title => :title, :link => Proc.new {|post| user_post_url(post.user, post)}, :description => :post, :pub_date => :published_at}
          })
      }
    end
 @section = 'posts' 
 @page_title = :featured_posts.l 
 widget do 
 :featured_writers.l 
 @featured_writers.each do |user| 
 render :partial => "users/sidebar_user", :locals => {:user => user} 
 end 
 end 
 render :partial => 'posts/post', :collection => @posts 
 paginate @posts, :theme => 'bootstrap' 

  end

  def category_tips_update
    return unless request.xhr?
    @category = Category.find(params[:post_category_id] )
    ruby_code_from_view.ruby_code_from_view do |rb_from_view| 

 if !category.nil? && !category.tips.blank? 
 category.name 
 category.tips 
 else  
 :we_need_you.l 
 :every_person_has_something_to_say.l 
 end 


end


  rescue ActiveRecord::RecordNotFound
    ruby_code_from_view.ruby_code_from_view do |rb_from_view| 

 if !category.nil? && !category.tips.blank? 
 category.name 
 category.tips 
 else  
 :we_need_you.l 
 :every_person_has_something_to_say.l 
 end 


end


  end

  private

  def require_ownership_or_moderator
    @user ||= User.find(params[:user_id])
    @post ||= Post.unscoped.find(params[:id]) if params[:id]
    unless admin? || moderator? || (@post && (@post.user.eql?(current_user))) || (!@post && @user && @user.eql?(current_user))
      redirect_to :controller => 'sessions', :action => 'new' and return false
    end
    return @user
  end


  def post_params
    params[:post].permit(:category_id, :title, :raw_post, :published_as, :send_comment_notifications, :tag_list)
  end

  def comment_params
    params[:comment].permit(:author_name, :author_email, :notify_by_email, :author_url, :comment)
  end
end
