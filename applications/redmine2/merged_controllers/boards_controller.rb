class BoardsController < ApplicationController
  default_search_scope :messages
  before_action :find_project_by_project_id, :find_board_if_available, :authorize
  accept_rss_auth :index, :show
  helper :sort
  include SortHelper
  helper :watchers
  def index
    @boards = @project.boards.preload(:last_message => :author).to_a
    if @boards.size == 1
      @board = @boards.first
      show
    end
  end
 l(:label_board_plural) 
 l(:label_board) 
 l(:label_topic_plural) 
 l(:label_message_plural) 
 l(:label_message_last) 
 Board.board_tree(@boards) do |board, level| 
 level * 18 
 link_to board.name, project_board_path(board.project, board), :class => "board" 
h board.description 
 board.topics_count 
 board.messages_count 
 if board.last_message 
 authoring board.last_message.created_on, board.last_message.author 
 link_to_message board.last_message 
 end 
 end 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:controller => 'activities', :action => 'index', :id => @project, :show_messages => 1, :key => User.current.rss_key} 
 end 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:controller => 'activities', :action => 'index', :id => @project, :format => 'atom', :show_messages => 1, :key => User.current.rss_key}) 
 end 
 html_title l(:label_board_plural) 
  def show
    respond_to do |format|
      format.html {
        sort_init 'updated_on', 'desc'
        sort_update 'created_on' => "#{Message.table_name}.id",
                    'replies' => "#{Message.table_name}.replies_count",
                    'updated_on' => "COALESCE(#{Message.table_name}.last_reply_id, #{Message.table_name}.id)"
        @topic_count = @board.topics.count
        @topic_pages = Paginator.new @topic_count, per_page_option, params['page']
        @topics =  @board.topics.
          reorder(:sticky => :desc).
          limit(@topic_pages.per_page).
          offset(@topic_pages.offset).
          order(sort_clause).
          preload(:author, {:last_reply => :author}).
          to_a
        @message = Message.new(:board => @board)
        render :action => 'show', :layout => !request.xhr?
 board_breadcrumb(@board) 
 link_to l(:label_message_new),
            new_board_message_path(@board),
            :class => 'icon icon-add',
            :onclick => 'showAndScrollTo("add-message", "message_subject"); return false;' if User.current.allowed_to?(:add_messages, @board.project) 
 watcher_link(@board, User.current) 
 if User.current.allowed_to?(:add_messages, @board.project) 
 link_to @board.name, project_board_path(@project, @board) 
 l(:label_message_new) 
 form_for @message, :url => new_board_message_path(@board), :html => {:multipart => true, :id => 'message-form'} do |f| 
 render :partial => 'messages/form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 preview_link(preview_board_message_path(@board), 'message-form') 
 link_to l(:button_cancel), "#", :onclick => '$("#add-message").hide(); return false;' 
 end 
 end 
 @board.name 
 @board.description 
 if @topics.any? 
 l(:field_subject) 
 l(:field_author) 
 sort_header_tag('created_on', :caption => l(:field_created_on)) 
 sort_header_tag('replies', :caption => l(:label_reply_plural)) 
 sort_header_tag('updated_on', :caption => l(:label_message_last)) 
 @topics.each do |topic| 
 topic.id 
 topic.sticky? ? 'sticky' : '' 
 topic.locked? ? 'locked' : '' 
 'icon-sticky' if topic.sticky? 
 'icon-locked' if topic.locked? 
 link_to topic.subject, board_message_path(@board, topic) 
 link_to_user(topic.author) 
 format_time(topic.created_on) 
 topic.replies_count 
 if topic.last_reply 
 authoring topic.last_reply.created_on, topic.last_reply.author 
 link_to_message topic.last_reply 
 end 
 end 
 pagination_links_full @topic_pages, @topic_count 
 else 
 l(:label_no_data) 
 end 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:key => User.current.rss_key} 
 end 
 html_title @board.name 
 content_for :header_tags do 
 auto_discovery_link_tag(:atom, {:format => 'atom', :key => User.current.rss_key}, :title => "#{@project}: #{@board}") 
 end 
      }
      format.atom {
        @messages = @board.messages.
          reorder(:id => :desc).
          includes(:author, :board).
          limit(Setting.feeds_limit.to_i).
          to_a
        render_feed(@messages, :title => "#{@project}: #{@board}")
      }
    end
  end
  def new
    @board = @project.boards.build
    @board.safe_attributes = params[:board]
  end
 l(:label_board_new) 
 labelled_form_for @board, :url => project_boards_path(@project) do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 end 
  def create
    @board = @project.boards.build
    @board.safe_attributes = params[:board]
    if @board.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_settings_in_projects
    else
      render :action => 'new'
 l(:label_board_new) 
 labelled_form_for @board, :url => project_boards_path(@project) do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 end 
    end
  end
  def edit
  end
 l(:label_board) 
 labelled_form_for @board, :url => project_board_path(@project, @board) do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
  def update
    @board.safe_attributes = params[:board]
    if @board.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to_settings_in_projects
        }
        format.js { head 200 }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
 l(:label_board) 
 labelled_form_for @board, :url => project_board_path(@project, @board) do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_save) 
 end 
        format.js { head 422 }
      end
    end
  end
  def destroy
    if @board.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to_settings_in_projects
  end
private
  def redirect_to_settings_in_projects
    redirect_to settings_project_path(@project, :tab => 'boards')
  end
  def find_board_if_available
    @board = @project.boards.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
