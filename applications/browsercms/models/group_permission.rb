
  class GroupPermission < ActiveRecord::Base

    extend DefaultAccessible

    belongs_to :group, :class_name => 'Group'
    belongs_to :permission, :class_name => 'Permission'

    validates_uniqueness_of :permission_id, :scope => :group_id

  end
