# encoding: utf-8
class DashboardController < ApplicationController
  before_action :authenticate_account!
  before_action :reset_notifications, only: [:index]

  def index
    @self_answer = params[:self] == "1"
    @comments = current_user.comments.on_dashboard.limit(30)
    @comments = @comments.where(answered_to_self: false) unless @self_answer
    @posts    = Node.where(user_id: current_user.id).on_dashboard(Post).limit(10)
    @trackers = Node.where(user_id: current_user.id).on_dashboard(Tracker).limit(10)
    @news     = News.where(author_email: current_account.email).candidate
    @drafts   = News.where(author_email: current_account.email).draft
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def answers
    render json: { node_ids: current_account.answers_node_id }
  end

protected

  def reset_notifications
    current_account.reset_answers_notifications
  end

end
