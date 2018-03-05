class NewsController < ApplicationController
  default_search_scope :news
  model_object News
  before_action :find_model_object, :except => [:new, :create, :index]
  before_action :find_project_from_association, :except => [:new, :create, :index]
  before_action :find_project_by_project_id, :only => [:new, :create]
  before_action :authorize, :except => [:index]
  before_action :find_optional_project, :only => :index
  accept_rss_auth :index
  accept_api_auth :index
  helper :watchers
  helper :attachments
  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit =  10
    end
    scope = @project ? @project.news.visible : News.visible
    @news_count = scope.count
    @news_pages = Paginator.new @news_count, @limit, params['page']
    @offset ||= @news_pages.offset
    @newss = scope.includes([:author, :project]).
                      order("#{News.table_name}.created_on DESC").
                      limit(@limit).
                      offset(@offset).
                      to_a
    respond_to do |format|
      format.html {
        @news = News.new # for adding news inline
        render :layout => false if request.xhr?
      }
      format.api
      format.atom { render_feed(@newss, :title => (@project ? @project.name : Setting.app_title) + ": #{l(:label_news_plural)}") }
    end
  end
 link_to(l(:label_news_new),
            new_project_news_path(@project),
            :class => 'icon icon-add',
            :onclick => 'showAndScrollTo("add-news", "news_title"); return false;') if @project && User.current.allowed_to?(:manage_news, @project) 
 watcher_link(@project.enabled_module('news'), User.current) if @project && User.current.logged? 
l(:label_news_new)
 labelled_form_for @news, :url => project_news_index_path(@project),
                                           :html => { :id => 'news-form', :multipart => true } do |f| 
 render :partial => 'news/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 preview_link preview_news_path(:project_id => @project), 'news-form' 
 link_to l(:button_cancel), "#", :onclick => '$("#add-news").hide()' 
 end if @project 
l(:label_news_plural)
 if @newss.empty? 
 l(:label_no_data) 
 else 
 @newss.each do |news| 
 avatar(news.author, :size => "24") 
 link_to_project(news.project) + ': ' unless news.project == @project 
 link_to h(news.title), news_path(news) 
 "(#{l(:label_x_comments, :count => news.comments_count)})" if news.comments_count > 0 
 authoring news.created_on, news.author 
 textilizable(news, :description) 
 end 
 end 
 pagination_links_full @news_pages 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:project_id => @project, :key => User.current.rss_key} 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, _project_news_path(@project, :key => User.current.rss_key, :format => 'atom')) 
 stylesheet_link_tag 'scm' 
 end 
 html_title(l(:label_news_plural)) 
  def show
    @comments = @news.comments.to_a
    @comments.reverse! if User.current.wants_comments_in_reverse_order?
  end
 watcher_link(@news, User.current) 
 link_to(l(:button_edit),
      edit_news_path(@news),
      :class => 'icon icon-edit',
      :accesskey => accesskey(:edit),
      :onclick => '$("#edit-news").show(); return false;') if User.current.allowed_to?(:manage_news, @project) 
 delete_link news_path(@news) if User.current.allowed_to?(:manage_news, @project) 
 avatar(@news.author, :size => "24") 
h @news.title 
 if authorize_for('news', 'edit') 
 labelled_form_for :news, @news, :url => news_path(@news),
                                           :html => { :id => 'news-form', :multipart => true, :method => :put } do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 preview_link preview_news_path(:project_id => @project, :id => @news), 'news-form' 
 link_to l(:button_cancel), "#", :onclick => '$("#edit-news").hide(); return false;' 
 end 
 end 
 unless @news.summary.blank? 
 @news.summary 
 end 
 authoring @news.created_on, @news.author 
 textilizable(@news, :description) 
 link_to_attachments @news 
 l(:label_comment_plural) 
 if @news.commentable? && @comments.size >= 3 
 toggle_link l(:label_comment_add), "add_comment_form", :focus => "comment_comments", :scroll => "comment_comments" 
 end 
 @comments.each do |comment| 
 next if comment.new_record? 
 link_to_if_authorized l(:button_delete), {:controller => 'comments', :action => 'destroy', :id => @news, :comment_id => comment},
                              :data => {:confirm => l(:text_are_you_sure)}, :method => :delete,
                              :title => l(:button_delete),
                              :class => 'icon-only icon-del' 
 avatar(comment.author, :size => "24") 
 authoring comment.created_on, comment.author 
 textilizable(comment.comments) 
 end if @comments.any? 
 if @news.commentable? 
 toggle_link l(:label_comment_add), "add_comment_form", :focus => "comment_comments" 
 form_tag({:controller => 'comments', :action => 'create', :id => @news}, :id => "add_comment_form", :style => "display:none;") do 
 text_area 'comment', 'comments', :cols => 80, :rows => 15, :class => 'wiki-edit' 
 wikitoolbar_for 'comment_comments' 
 submit_tag l(:button_add) 
 end 
 end 
 html_title @news.title 
 content_for :header_tags do 
 stylesheet_link_tag 'scm' 
 end 
  def new
    @news = News.new(:project => @project, :author => User.current)
  end
l(:label_news_new)
 labelled_form_for @news, :url => project_news_index_path(@project),
                                           :html => { :id => 'news-form', :multipart => true } do |f| 
 render :partial => 'news/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 preview_link preview_news_path(:project_id => @project), 'news-form' 
 end 
  def create
    @news = News.new(:project => @project, :author => User.current)
    @news.safe_attributes = params[:news]
    @news.save_attachments(params[:attachments])
    if @news.save
      render_attachment_warning_if_needed(@news)
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_news_index_path(@project)
    else
      render :action => 'new'
l(:label_news_new)
 labelled_form_for @news, :url => project_news_index_path(@project),
                                           :html => { :id => 'news-form', :multipart => true } do |f| 
 render :partial => 'news/form', :locals => { :f => f } 
 submit_tag l(:button_create) 
 preview_link preview_news_path(:project_id => @project), 'news-form' 
 end 
    end
  end
  def edit
  end
l(:label_news)
 labelled_form_for @news, :html => { :id => 'news-form', :multipart => true, :method => :put } do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 preview_link preview_news_path(:project_id => @project, :id => @news), 'news-form' 
 end 
 content_for :header_tags do 
 stylesheet_link_tag 'scm' 
 end 
  def update
    @news.safe_attributes = params[:news]
    @news.save_attachments(params[:attachments])
    if @news.save
      render_attachment_warning_if_needed(@news)
      flash[:notice] = l(:notice_successful_update)
      redirect_to news_path(@news)
    else
      render :action => 'edit'
l(:label_news)
 labelled_form_for @news, :html => { :id => 'news-form', :multipart => true, :method => :put } do |f| 
 render :partial => 'form', :locals => { :f => f } 
 submit_tag l(:button_save) 
 preview_link preview_news_path(:project_id => @project, :id => @news), 'news-form' 
 end 
 content_for :header_tags do 
 stylesheet_link_tag 'scm' 
 end 
    end
  end
  def destroy
    @news.destroy
    redirect_to project_news_index_path(@project)
  end
end
