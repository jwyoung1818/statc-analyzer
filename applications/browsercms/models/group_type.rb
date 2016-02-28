
  class GroupType < ActiveRecord::Base
   #attr_accessible :name, :guest, :cms_access

    has_many :groups, :class_name => 'Group'
    has_many :group_type_permissions, :class_name => 'GroupTypePermission'
    has_many :permissions, :through => :group_type_permissions, :class_name => 'Permission'

    scope :guest, -> {where( ["#{GroupType.table_name}.guest = ?", true])}
    scope :non_guest, -> {where( ["#{GroupType.table_name}.guest = ?", false])}

    scope :cms_access, -> {where( ["#{GroupType.table_name}.cms_access = ?", true])}
    scope :non_cms_access, -> {where( ["#{GroupType.table_name}.cms_access = ?", false])}

  end
