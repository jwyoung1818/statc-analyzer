class CommentsController < ApplicationController
  default_search_scope :news
  model_object News
  before_action :find_model_object
  before_action :find_project_from_association
  before_action :authorize
  def create
    raise Unauthorized unless @news.commentable?
    @comment = Comment.new
    @comment.safe_attributes = params[:comment]
    @comment.author = User.current
    if @news.comments << @comment
      flash[:notice] = l(:label_comment_added)
    end
    redirect_to news_path(@news)
  end
  def destroy
    @news.comments.find(params[:comment_id]).destroy
    redirect_to news_path(@news)
  end
  private
  def find_model_object
    super
    @news = @object
    @comment = nil
    @news
  end
end
