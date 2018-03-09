# This is usersController
class UsersController < ApplicationController
  def index
  	for i in 1..8
      users = User.all
    	User.getAll(i)
    	user = User.first
    	id = user.id
  	end
  	render 'index'
  	users.reload
  	puts "Do nothing with user"
  	users.reload
  end
  def test
    puts "Rendering index"
    render "index"
    puts " finishing index"
  end
end
