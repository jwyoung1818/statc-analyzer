# encoding: UTF-8
class Admin::FriendSitesController < AdminController
  before_action :find_friend_site, except: [:index, :new, :create]

  def index
    @friend_sites = FriendSite.all
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def new
    @friend_site = FriendSite.new
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def create
    @friend_site = FriendSite.new
    @friend_site.attributes = params[:friend_site]
    if @friend_site.save
      @friend_site.move_to_bottom
      redirect_to admin_friend_sites_url, notice: "Site ami créé"
    else
      flash.now[:alert] = "Impossible d'enregistrer ce site"
      ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

    end
  end

  def edit
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def update
    @friend_site.attributes = params[:friend_site]
    if @friend_site.save
      redirect_to admin_friend_sites_url, notice: "Site ami modifié"
    else
      flash.now[:alert] = "Impossible d'enregistrer ce site"
      ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

    end
  end

  def destroy
    @friend_site.destroy
    redirect_to admin_friend_sites_url, notice: "Site ami supprimé"
  end

  def lower
    @friend_site.move_lower
    redirect_to admin_friend_sites_url
  end

  def higher
    @friend_site.move_higher
    redirect_to admin_friend_sites_url
  end

protected

  def find_friend_site
    @friend_site = FriendSite.find(params[:id])
  end
end
