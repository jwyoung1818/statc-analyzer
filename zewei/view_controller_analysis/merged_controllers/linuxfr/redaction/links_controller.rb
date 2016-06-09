# encoding: UTF-8
#
class Redaction::LinksController < RedactionController
  before_action :new_link,  only: [:new, :create]
  before_action :find_link, except: [:new, :create]

  def new
    ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end
end

  def create
    @link.attributes = link_params
    @link.user = current_user
    @link.save
    ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def edit
    if @link.lock_by(current_user)
      ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

    else
      render status: :forbidden, text: "Désolé, #{@link.locker} est déjà en train de modifier ce lien !"
    end
  end

  def update
    @link.attributes = link_params
    @link.update_by(current_user)
    ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def unlock
    @link.unlock
    render nothing: true
  end

protected

  def link_params
    params.require(:link).permit(Link::Accessible)
  end

  def new_link
    @news = News.find(params[:news_id])
    @link = @news.links.new
    enforce_update_permission(@news)
  end

  def find_link
    @link = Link.find(params[:id])
    @news = @link.news
    enforce_update_permission(@news)
  end

end
