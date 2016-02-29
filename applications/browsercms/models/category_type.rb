
  class CategoryType < ActiveRecord::Base

    has_many :categories, :class_name => 'Category'
    validates_presence_of :name
    validates_uniqueness_of :name
    is_searchable
    has_content_type :module => :categorization

    include Concerns::IgnoresPublishing

    def self.named(name)
      where(name: name)
    end

    # Return a map when the key is category type id as a string
    # and the value is an array of arrays, each entry having
    # the first value as the category path and the second value
    # being the category id as a string
    def self.category_map
      all.inject(Hash.new([])) do |map, ct|
        map[ct.id.to_s] = ct.category_list.map { |c| [c.path, c.id.to_s] }
        map
      end
    end

    # This is used to get the full list of categories for this category type in the correct order.
    def category_list(order="name")
      list = []
      fn = lambda do |cat|
        list << cat
        cat.children.order(order).each { |c| fn.call(c) }
      end
      categories.top_level.order(order).each { |cat| fn.call(cat) }
      list
    end

    def cannot_be_deleted_message
      categories.count.zero? ? nil : "This cannot be deleted because it is in use in #{categories.count} #{"category".pluralize_unless_one(categories.count)}"
    end

  end