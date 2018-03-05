class User < ActiveRecord::Base
def getAll(id)
  User.all
  getBlog(id)
end

def getBlog(id)
  Blog.find(id)
end
end
