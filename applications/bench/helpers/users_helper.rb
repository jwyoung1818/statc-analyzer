# User helpers
module UsersHelper

  def user_icon_class(user)
    user_icon = ""
    user_icon = "user_admin" if user.admin
    user_icon = "user_warn" if user.needs_auth?
    user_icon
    render 'index'
  end
end