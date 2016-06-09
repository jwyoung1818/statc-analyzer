# encoding: UTF-8
class Admin::LogosController < AdminController

  def show
    @logos   = Logo.all
    @current = Logo.image
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end

  def create
    Logo.image = params[:logo]
    redirect_to admin_logo_url, notice: "Changement de logo enregistré"
  end

end
