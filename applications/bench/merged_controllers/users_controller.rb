class UsersController < ApplicationController
  def index
  	for i in 1..8
      users = User.all
    	User.getAll(i)
    	user = User.first
    	id = user.id
  	end
  	render 'index'
 User.all.limit(1) 
 users.each do |user| 
 render partial: 'user'  
 User.all.limit(10) 
 render partial: 'blog' 
 Test 
 Blog.end 
 content_tag(:div) 
 end 
 User.exists? 
 Start rendering etid
 render partial: 'blog1' 
 Test 
 Line 4 
  	users.reload
  	puts "Do nothing with user"
  	users.reload
  end
  def test
    puts "Rendering index"
    render "index"
 User.all.limit(1) 
 users.each do |user| 
 render partial: 'user'  
 User.all.limit(10) 
 render partial: 'blog' 
 Test 
 Blog.end 
 content_tag(:div) 
 end 
 User.exists? 
 Start rendering etid
 render partial: 'blog1' 
 Test 
 Line 4 
    puts " finishing index"
  end
end
