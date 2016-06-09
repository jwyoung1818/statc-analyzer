#==
# Copyright (C) 2008 James S Urquhart
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#++

class ListsController < ApplicationController
  before_filter :grab_page
  before_filter :load_list, :except => [:index, :new, :create]
  
  cache_sweeper :page_sweeper, :only => [:create, :update, :destroy, :transfer, :reorder]
  
  # GET /lists
  # GET /lists.xml
  def index
    @lists = @page.lists.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lists }
    end
  end

  # GET /lists/1
  # GET /lists/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.js
      format.xml  { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 h(object.name) 
 if object.can_be_edited_by(@logged_user) 
 object.name 
 end 
  url = show.can_be_completed_by(@logged_user) ? "/lists//items/" : nil 
 if show.can_be_completed_by(@logged_user) 
 unless show.is_completed? or !show.can_be_edited_by(@logged_user) 
 page_handle [ ['delete', '-'], ['edit', t('edit')], ['handle', '+'] ], "page_item_handle_", '.listItem' 
 end 
 else 
 show.is_completed? ? render_icon('checked', t('list_item_completed')) : render_icon('not-checked', t('list_item_open')) 
 end 
 (show.is_completed? and show.can_be_edited_by(@logged_user)) ? render_icon('del_gen', '', {:class => 'itemDelete'}) : '' 
 raw(textilize h(show.content), true, {}) 
 
 if object.can_be_edited_by(@logged_user) 
 (@new_list.nil? ? 'display:none' : nil) 
 form_tag page_list_list_items_path(object.page, object), :method => :post do 
 text_field 'list_item', 'content', :class => 'autofocus moderate' 
 t('add_item') 
 t('cancel') 
 end 
 (@new_list.nil? ? nil : 'display:none') 
 t('add_item') 
 end 
 climit = show_item_count 
 citems = object.completed_items 
  url = show.can_be_completed_by(@logged_user) ? "/lists//items/" : nil 
 if show.can_be_completed_by(@logged_user) 
 unless show.is_completed? or !show.can_be_edited_by(@logged_user) 
 page_handle [ ['delete', '-'], ['edit', t('edit')], ['handle', '+'] ], "page_item_handle_", '.listItem' 
 end 
 else 
 show.is_completed? ? render_icon('checked', t('list_item_completed')) : render_icon('not-checked', t('list_item_open')) 
 end 
 (show.is_completed? and show.can_be_edited_by(@logged_user)) ? render_icon('del_gen', '', {:class => 'itemDelete'}) : '' 
 raw(textilize h(show.content), true, {}) 
 
 if climit > 0 and citems.length > climit 
 t('list_item_show') 
 end 

end
 }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 h(object.name) 
 if object.can_be_edited_by(@logged_user) 
 object.name 
 end 
  url = show.can_be_completed_by(@logged_user) ? "/lists//items/" : nil 
 if show.can_be_completed_by(@logged_user) 
 unless show.is_completed? or !show.can_be_edited_by(@logged_user) 
 page_handle [ ['delete', '-'], ['edit', t('edit')], ['handle', '+'] ], "page_item_handle_", '.listItem' 
 end 
 else 
 show.is_completed? ? render_icon('checked', t('list_item_completed')) : render_icon('not-checked', t('list_item_open')) 
 end 
 (show.is_completed? and show.can_be_edited_by(@logged_user)) ? render_icon('del_gen', '', {:class => 'itemDelete'}) : '' 
 raw(textilize h(show.content), true, {}) 
 
 if object.can_be_edited_by(@logged_user) 
 (@new_list.nil? ? 'display:none' : nil) 
 form_tag page_list_list_items_path(object.page, object), :method => :post do 
 text_field 'list_item', 'content', :class => 'autofocus moderate' 
 t('add_item') 
 t('cancel') 
 end 
 (@new_list.nil? ? nil : 'display:none') 
 t('add_item') 
 end 
 climit = show_item_count 
 citems = object.completed_items 
  url = show.can_be_completed_by(@logged_user) ? "/lists//items/" : nil 
 if show.can_be_completed_by(@logged_user) 
 unless show.is_completed? or !show.can_be_edited_by(@logged_user) 
 page_handle [ ['delete', '-'], ['edit', t('edit')], ['handle', '+'] ], "page_item_handle_", '.listItem' 
 end 
 else 
 show.is_completed? ? render_icon('checked', t('list_item_completed')) : render_icon('not-checked', t('list_item_open')) 
 end 
 (show.is_completed? and show.can_be_edited_by(@logged_user)) ? render_icon('del_gen', '', {:class => 'itemDelete'}) : '' 
 raw(textilize h(show.content), true, {}) 
 
 if climit > 0 and citems.length > climit 
 t('list_item_show') 
 end 

end

  end

  # GET /lists/new
  # GET /lists/new.xml
  def new
    return error_status(true, :cannot_create_list) unless (List.can_be_created_by(@logged_user, @page))
    
    @list = @page.lists.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @list }
    end
  end

  # GET /lists/1/edit
  def edit
    return error_status(true, :cannot_edit_list) unless (@list.can_be_edited_by(@logged_user))
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 "list_header_#{@list.id}_form" 
  form_tag page_list_path(@page, @list), :method => :put do 
 text_field 'list', 'name', :class => 'autofocus moderate' 
 t('rename_list') 
 t('cancel') 
 end 
 
 "list_header_#{@list.id}" 
 "list_header_#{@list.id}_form" 

end

  end

  # POST /lists
  # POST /lists.xml
  def create
    return error_status(true, :cannot_create_list) unless (List.can_be_created_by(@logged_user, @page))
    
    calculate_position
    
    # Make the darn note
    @list = @page.lists.build(params[:list])
    @list.created_by = @logged_user
    @list.name ||= t('List')
    saved = @list.save
    
    # And the slot, don't forget the slot
    if saved
      save_slot(@list)
      @new_list = true
    end

    respond_to do |format|
      if @list.save
        flash[:notice] = 'List was successfully created.'
        format.html { redirect_to(@list) }
        format.js {}
        format.xml  { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 ec = escape_javascript("<div class=\"pageSlot\" id=\"page_slot_#{@slot.id}\" slot=\"#{@slot.id}\"></div>").html_safe 
 if @insert_before 
 @insert_element 
 ec 
 else 
 @insert_element 
 ec 
 end 
 "page_slot_#{@slot.id}" 
  page_url = @page.can_be_edited_by(@logged_user) ? "//" : '' 
 page_url 
 if @page.can_be_edited_by(@logged_user) 
 raw(page_handle widget_options(object), "page_slot_handle_", '.pageWidget') 
 end 
 raw(render :partial => object.view_partial, :locals => {:object => object, :page_slot => page_slot}) 
 
 "page_slot_#{@slot.id}" 

end
 }
      else
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = t('new_page') 
 @tabbed_navigation_items = common_tabs(:pages) 
 @user_navigation_items = user_tabs(nil) 
 form_tag pages_path(:use_route => nil) do 
 raw(error_messages_for :page) 
 raw(text_field 'page', 'title', :id => 'newpage_title', :class => 'long') 
 raw(submit_tag t('page_create')) 
 end 
 pages_path 
 t('page_back') 

end
 }
        format.js {}
        format.xml  { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 ec = escape_javascript("<div class=\"pageSlot\" id=\"page_slot_#{@slot.id}\" slot=\"#{@slot.id}\"></div>").html_safe 
 if @insert_before 
 @insert_element 
 ec 
 else 
 @insert_element 
 ec 
 end 
 "page_slot_#{@slot.id}" 
  page_url = @page.can_be_edited_by(@logged_user) ? "//" : '' 
 page_url 
 if @page.can_be_edited_by(@logged_user) 
 raw(page_handle widget_options(object), "page_slot_handle_", '.pageWidget') 
 end 
 raw(render :partial => object.view_partial, :locals => {:object => object, :page_slot => page_slot}) 
 
 "page_slot_#{@slot.id}" 

end
 }
      end
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 ec = escape_javascript("<div class=\"pageSlot\" id=\"page_slot_#{@slot.id}\" slot=\"#{@slot.id}\"></div>").html_safe 
 if @insert_before 
 @insert_element 
 ec 
 else 
 @insert_element 
 ec 
 end 
 "page_slot_#{@slot.id}" 
  page_url = @page.can_be_edited_by(@logged_user) ? "//" : '' 
 page_url 
 if @page.can_be_edited_by(@logged_user) 
 raw(page_handle widget_options(object), "page_slot_handle_", '.pageWidget') 
 end 
 raw(render :partial => object.view_partial, :locals => {:object => object, :page_slot => page_slot}) 
 
 "page_slot_#{@slot.id}" 

end

  end

  # PUT /lists/1
  # PUT /lists/1.xml
  def update
    return error_status(true, :cannot_edit_list) unless (@list.can_be_edited_by(@logged_user))
    
    @list.updated_by = @logged_user

    respond_to do |format|
      if @list.update_attributes(params[:list])
        flash[:notice] = 'List was successfully updated.'
        format.html { redirect_to(@list) }
        format.js {}
        format.xml  { head :ok }
      else
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 "list_header_#{@list.id}_form" 
  form_tag page_list_path(@page, @list), :method => :put do 
 text_field 'list', 'name', :class => 'autofocus moderate' 
 t('rename_list') 
 t('cancel') 
 end 
 
 "list_header_#{@list.id}" 
 "list_header_#{@list.id}_form" 

end
 }
        format.js {}
        format.xml  { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 "list_header_#{@list.id}_form" 
 "list_header_#{@list.id}_form" 
 "list_header_#{@list.id}" 
 escape_javascript("<h2 hover_handle=\"page_slot_handle_#{@list.page_slot.id}\">#{h(@list.name)}</h2>").html_safe 
 "list_header_#{@list.id}" 

end
 }
      end
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 "list_header_#{@list.id}_form" 
 "list_header_#{@list.id}_form" 
 "list_header_#{@list.id}" 
 escape_javascript("<h2 hover_handle=\"page_slot_handle_#{@list.page_slot.id}\">#{h(@list.name)}</h2>").html_safe 
 "list_header_#{@list.id}" 

end

  end

  # DELETE /lists/1
  # DELETE /lists/1.xml
  def destroy
    return error_status(true, :cannot_delete_list) unless (@list.can_be_deleted_by(@logged_user))
    
    @slot_id = @list.page_slot.id
    @list.page_slot.destroy
    @list.updated_by = @logged_user
    @list.destroy

    respond_to do |format|
      format.html { redirect_to(lists_url) }
      format.js {}
      format.xml  { head :ok }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 "page_slot_#{@slot_id}" 

end

  end
  
  # PUT /lists/1/transfer
  def transfer
    @item = ListItem.find(params[:list_item][:id])
    
    return error_status(true, :insufficient_permissions) unless (@list.can_be_edited_by(@logged_user) and @item.can_be_edited_by(@logged_user))
    
    @item.list = @list
    @item.save

    respond_to do |format|
      format.html { head :ok }
      format.js { head :ok }
      format.xml  { head :ok }
    end
  end
  
  # POST /lists/1/reorder
  def reorder
    return error_status(true, :cannot_edit_list) unless (@list.can_be_edited_by(@logged_user))
    
    order = params[:items].collect { |id| id.to_i }
    
    @list.list_items.each do |item|
        idx = order.index(item.id)
        item.position = idx
        item.position ||= @list.list_items.length
        item.save!
    end
    
    respond_to do |format|
      format.html { head :ok }
      format.json { head :ok }
      format.xml  { head :ok }
    end
  end

protected

  def load_list
    begin
      @list = @page.lists.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :cannot_find_list)
      return false
    end
    
    true
  end
end
