class WelcomeController < ApplicationController
  self.main_menu = false
  def index
    @news = News.latest User.current
  end
 l(:label_home) 
 textilizable Setting.welcome_text 
 call_hook(:view_welcome_index_left) 
 if @news.any? 
l(:label_news_latest)
 render :partial => 'news/news', :collection => @news 
 link_to_project(news.project) + ': ' unless @project 
 link_to news.title, news_path(news) 
 if news.comments_count > 0 
 l(:label_x_comments, :count => news.comments_count) 
 end 
 unless news.summary.blank? 
 news.summary 
 end 
 authoring news.created_on, news.author 
 link_to l(:label_news_view_all), :controller => 'news' 
 end 
 call_hook(:view_welcome_index_right) 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:controller => 'news', :action => 'index', :key => User.current.rss_key, :format => 'atom'},
                                   :title => "#{Setting.app_title}: #{l(:label_news_latest)}") 
 auto_discovery_link_tag(:atom, {:controller => 'activities', :action => 'index', :key => User.current.rss_key, :format => 'atom'},
                                   :title => "#{Setting.app_title}: #{l(:label_activity)}") 
 end 
  def robots
    @projects = Project.all_public.active
    render :layout => false, :content_type => 'text/plain'
  end
end
