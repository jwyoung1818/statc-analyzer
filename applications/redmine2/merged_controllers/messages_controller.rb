class MessagesController < ApplicationController
  menu_item :boards
  default_search_scope :messages
  before_action :find_board, :only => [:new, :preview]
  before_action :find_attachments, :only => [:preview]
  before_action :find_message, :except => [:new, :preview]
  before_action :authorize, :except => [:preview, :edit, :destroy]
  helper :boards
  helper :watchers
  helper :attachments
  include AttachmentsHelper
  REPLIES_PER_PAGE = 25 unless const_defined?(:REPLIES_PER_PAGE)
  def show
    page = params[:page]
    if params[:r] && page.nil?
      offset = @topic.children.where("#{Message.table_name}.id < ?", params[:r].to_i).count
      page = 1 + offset / REPLIES_PER_PAGE
    end
    @reply_count = @topic.children.count
    @reply_pages = Paginator.new @reply_count, REPLIES_PER_PAGE, page
    @replies =  @topic.children.
      includes(:author, :attachments, {:board => :project}).
      reorder("#{Message.table_name}.created_on ASC, #{Message.table_name}.id ASC").
      limit(@reply_pages.per_page).
      offset(@reply_pages.offset).
      to_a
    @reply = Message.new(:subject => "RE: #{@message.subject}")
    render :action => "show", :layout => false if request.xhr?
 board_breadcrumb(@message) 
 watcher_link(@topic, User.current) 
 link_to(
          l(:button_quote),
          {:action => 'quote', :id => @topic},
          :method => 'get',
          :class => 'icon icon-comment',
          :remote => true) if !@topic.locked? && authorize_for('messages', 'reply') 
 link_to(
          l(:button_edit),
          {:action => 'edit', :id => @topic},
          :class => 'icon icon-edit'
        ) if @message.editable_by?(User.current) 
 link_to(
          l(:button_delete),
          {:action => 'destroy', :id => @topic},
          :method => :post,
          :data => {:confirm => l(:text_are_you_sure)},
          :class => 'icon icon-del'
         ) if @message.destroyable_by?(User.current) 
 avatar(@topic.author, :size => "24") 
 @topic.subject 
 authoring @topic.created_on, @topic.author 
 textilizable(@topic, :content) 
 link_to_attachments @topic, :author => false, :thumbnails => true 
 unless @replies.empty? 
 l(:label_reply_plural) 
 @reply_count 
 if !@topic.locked? && authorize_for('messages', 'reply') && @replies.size >= 3 
 toggle_link l(:button_reply), "reply", :focus => 'message_content', :scroll => "message_content" 
 end 
 @replies.each do |message| 
 "message-#{message.id}" 
 link_to(
            '',
            {:action => 'quote', :id => message},
            :remote => true,
            :method => 'get',
            :title => l(:button_quote),
            :class => 'icon icon-comment'
          ) if !@topic.locked? && authorize_for('messages', 'reply') 
 link_to(
            '',
            {:action => 'edit', :id => message},
            :title => l(:button_edit),
            :class => 'icon icon-edit'
          ) if message.editable_by?(User.current) 
 link_to(
            '',
            {:action => 'destroy', :id => message},
            :method => :post,
            :data => {:confirm => l(:text_are_you_sure)},
            :title => l(:button_delete),
            :class => 'icon icon-del'
          ) if message.destroyable_by?(User.current) 
 avatar(message.author, :size => "24") 
 link_to message.subject, { :controller => 'messages', :action => 'show', :board_id => @board, :id => @topic, :r => message, :anchor => "message-#{message.id}" } 
 authoring message.created_on, message.author 
 textilizable message, :content, :attachments => message.attachments 
 link_to_attachments message, :author => false, :thumbnails => true 
 end 
 pagination_links_full @reply_pages, @reply_count, :per_page_links => false 
 end 
 if !@topic.locked? && authorize_for('messages', 'reply') 
 toggle_link l(:button_reply), "reply", :focus => 'message_content' 
 form_for @reply, :as => :reply, :url => {:action => 'reply', :id => @topic}, :html => {:multipart => true, :id => 'message-form'} do |f| 
 render :partial => 'form', :locals => {:f => f, :replying => true} 
 submit_tag l(:button_submit) 
 preview_link({:controller => 'messages', :action => 'preview', :board_id => @board}, 'message-form') 
 end 
 end 
 html_title @topic.subject 
  end
  def new
    @message = Message.new
    @message.author = User.current
    @message.board = @board
    @message.safe_attributes = params[:message]
    if request.post?
      @message.save_attachments(params[:attachments])
      if @message.save
        call_hook(:controller_messages_new_after_save, { :params => params, :message => @message})
        render_attachment_warning_if_needed(@message)
        redirect_to board_message_path(@board, @message)
      end
    end
  end
 link_to @board.name, :controller => 'boards', :action => 'show', :project_id => @project, :id => @board 
 l(:label_message_new) 
 form_for @message, :url => {:action => 'new'}, :html => {:multipart => true, :id => 'message-form'} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 submit_tag l(:button_create) 
 preview_link({:controller => 'messages', :action => 'preview', :board_id => @board}, 'message-form') 
 end 
  def reply
    @reply = Message.new
    @reply.author = User.current
    @reply.board = @board
    @reply.safe_attributes = params[:reply]
    @topic.children << @reply
    if !@reply.new_record?
      call_hook(:controller_messages_reply_after_save, { :params => params, :message => @reply})
      attachments = Attachment.attach_files(@reply, params[:attachments])
      render_attachment_warning_if_needed(@reply)
    end
    redirect_to board_message_path(@board, @topic, :r => @reply)
  end
  def edit
    (render_403; return false) unless @message.editable_by?(User.current)
    @message.safe_attributes = params[:message]
    if request.post? && @message.save
      attachments = Attachment.attach_files(@message, params[:attachments])
      render_attachment_warning_if_needed(@message)
      flash[:notice] = l(:notice_successful_update)
      @message.reload
      redirect_to board_message_path(@message.board, @message.root, :r => (@message.parent_id && @message.id))
    end
  end
 board_breadcrumb(@message) 
 avatar(@topic.author, :size => "24") 
 @topic.subject 
 form_for @message, {
               :as => :message,
               :url => {:action => 'edit'},
               :html => {:multipart => true,
                         :id => 'message-form',
                         :method => :post}
          } do |f| 
 render :partial => 'form',
             :locals => {:f => f, :replying => !@message.parent.nil?} 
 submit_tag l(:button_save) 
 preview_link({:controller => 'messages', :action => 'preview', :board_id => @board, :id => @message}, 'message-form') 
 end 
  def destroy
    (render_403; return false) unless @message.destroyable_by?(User.current)
    r = @message.to_param
    @message.destroy
    if @message.parent
      redirect_to board_message_path(@board, @message.parent, :r => r)
    else
      redirect_to project_board_path(@project, @board)
    end
  end
  def quote
    @subject = @message.subject
    @subject = "RE: #{@subject}" unless @subject.starts_with?('RE:')
    @content = "#{ll(Setting.default_language, :text_user_wrote, @message.author)}\n> "
    @content << @message.content.to_s.strip.gsub(%r{<pre>(.*?)</pre>}m, '[...]').gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
  end
  def preview
    message = @board.messages.find_by_id(params[:id])
    @text = (params[:message] || params[:reply])[:content]
    @previewed = message
    render :partial => 'common/preview'
 l(:label_preview) 
 textilizable @text, :attachments => @attachments, :object => @previewed 
  end
private
  def find_message
    return unless find_board
    @message = @board.messages.includes(:parent).find(params[:id])
    @topic = @message.root
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def find_board
    @board = Board.includes(:project).find(params[:board_id])
    @project = @board.project
  rescue ActiveRecord::RecordNotFound
    render_404
    nil
  end
end
