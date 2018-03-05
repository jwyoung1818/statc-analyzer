class Blog < ActiveRecord::Base
    def getAll
        Blog.all
    end
end
