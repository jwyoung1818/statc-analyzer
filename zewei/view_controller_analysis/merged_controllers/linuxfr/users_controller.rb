# encoding: utf-8
class UsersController < ApplicationController
  before_action :find_user

  def show
    path = user_path(id: @user, format: params[:format])
    redirect_to path, status: 301 and return if request.path != path
    find_nodes([News, Diary])
    respond_to do |wants|
      wants.html
      wants.atom
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def news
    path = news_user_path(id: @user, format: params[:format])
    redirect_to path, status: 301 and return if request.path != path
    find_nodes(News)
    respond_to do |wants|
      wants.html
      wants.atom { ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end
 }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def journaux
    path = journaux_user_path(id: @user, format: params[:format])
    redirect_to path, status: 301 and return if request.path != path
    find_nodes(Diary)
    respond_to do |wants|
      wants.html
      wants.atom { ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end
 }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def posts
    path = posts_user_path(id: @user, format: params[:format])
    redirect_to path, status: 301 and return if request.path != path
    find_nodes(Post)
    respond_to do |wants|
      wants.html
      wants.atom { ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end
 }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def suivi
    path = suivi_user_path(id: @user, format: params[:format])
    redirect_to path, status: 301 and return if request.path != path
    find_nodes(Tracker)
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def wiki
    path = wiki_user_path(id: @user, format: params[:format])
    redirect_to path, status: 301 and return if request.path != path
    @versions = @user.wiki_versions.order("created_at DESC").page(params[:page])
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def comments
    path = comments_user_path(id: @user, format: params[:format])
    redirect_to path, status: 301 and return if request.path != path
    @dont_index = true
    @comments = @user.comments.published.order('created_at DESC').page(params[:page])
    respond_to do |wants|
      wants.html
      wants.atom { ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end
 }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

protected

  def find_user
    @user = User.find(params[:id])
    raise ActiveRecord::RecordNotFound.new unless @user
    @contents = @user.nodes.visible.by_date.limit(20)
  end

  def find_nodes(klass)
    @dont_index = params.has_key?(:page)
    @order = params[:order]
    @order = "created_at" unless VALID_ORDERS.include?(@order)
    @nodes = Node.public_listing(klass, @order).where("nodes.user_id" => @user.id).page(params[:page])
  end

end
