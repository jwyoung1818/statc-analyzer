require 'enumerator'

class Skyline::ContentController < Skyline::Skyline2Controller
  
  layout "skyline/layouts/content"
    
  self.default_menu = :content_library   
    
  def index
    if first_element = (Skyline::Configuration.articles + Skyline::Configuration.content_classes).first
	    if first_element.ancestors.include?(Skyline::Article)
	      redirect_to skyline_articles_path(:type => first_element)
	    else
	      redirect_to object_url(first_element, :controller => "skyline/content", :action => "list") 
      end
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|

end

  end
    
  def list
    list_elements!
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 content_for :header do 
 if @stack.size > 1 
 @title = t(:title_sublisting, :scope => [:content, :list], :group => @stack.klass.plural_name, :title => @stack[-2].class.singular_name + " " + @stack[-2].human_id.to_s).html_safe 
 else 
 @title = t(:title, :scope => [:content, :list], :class => @stack.klass.plural_name).html_safe 
 end 
 end 
 Skyline::Presenters::Table.new(@elements,stack.klass,self).output 
 content_for :meta do 
  url_suffix = local_assigns.has_key?(:field) && {:sub => field.name} || {} 
 url_suffix.update(:return_to => return_to) if local_assigns.has_key?(:return_to) 
 link_to button_text(:new), object_url(record,{:action => "create"}.update(url_suffix)), :class => "add button medium green"  
 if klass.exportable? 
 link_to button_text(:export), object_url(record,{:action => "export"}.update(url_suffix)), :class => "button small" 
 end 
 if klass.importable? 
 link_to(
          button_text(:import), 
          object_url(record,{:action => "import"}.update(url_suffix)),
          :remote => true,
          :method => :get, 
          :class => "button small") 
 end 
 t(:info, :scope => [:content,:list]) 
 t(:number_of, :scope => [:content, :pagination], :class => stack.klass.plural_name) 
 @elements.respond_to?(:total_entries) ? @elements.total_entries : @elements.size 
 
 end 
 if @elements.respond_to?(:total_entries) && @elements.total_entries > @elements.per_page 
 content_for :footer do 
 will_paginate @elements 
 end 
 end 

end

  end
  
  def show
    @element = stack.last
    render :layout => "popup"
  end
  
  def edit
    @element = stack.last
    
    # Just redirect away from here like we would have done after a save.
    return redirect_after(:save, @element) if params[:discard]
    
    if request.post?        
      begin
        @element.attributes = params[:element]
        @element.from_version = params[:version].to_i
      rescue ActiveRecord::RecordInvalid
        @element.keep_version!
        messages.now[:error] = l(:content,:flashes,:invalid_record)
        return
      end

      if !@element.matching_versions?
        # Failed version
        show_url = object_url(@element,{:action => "show"})
        messages.now[:notice] = l(:version_conflict, 
                                :scope => [:content, :flashes],
                                :current_version => @element.current_version, 
                                :your_version => params[:version], 
                                :current_author => @element.current_author,
                                :show_link => "<a href='#{show_url}' onclick=\"popup('#{show_url}',800,800,'scrollbars=yes'); return false\">#{t(:see_changes_by, :scope => [:content, :edit], :current_author => @element.current_author)}</a>")
      else
        if @element.save
          notifications[:success] = t(:successfully_saved, :scope => [:content, :flashes], :class => @element.class.singular_name)
          redirect_after :save, @element
        else
          @element.keep_version!
          messages.now[:error] = t(:validation_error, :scope => [:content, :flashes], :class => @element.class.singular_name)
        end        
      end
    end    
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 content_for :header do 
 @title = t :title, :scope => [:content, :edit], :class => stack.klass.singular_name.downcase, :title => stack.current.human_id 
 end 
 content_form :element, {:action => "edit", :multipart => true, :submit_value => "save"} do 
  if @element.class.publishable? 
 t(:publish, :scope => [:content, :edit]) 
 publish_field = Skyline::Content::MetaData::Field.new(:name => 'published', :owner => @element.class) 
 boolean_field('element[published]',@element, publish_field, :class => "checkbox",:id => "element_published") 
 t(:published, :scope => [:content, :edit]) 
 end 
 if @element.class.taggable? 
 t(:meta_information, :scope => [:content, :edit]) 
 tags = @element.available_tags.collect{|tag| content_tag("li", tag.tag)} 
 raw_tags_field = Skyline::Content::MetaData::Field.new(:name => 'raw_tags', :owner => @element.class) 
 t(:tags, :scope => [:content, :edit]) 
 text_area_tag("element[raw_tags]", raw_tags_field.value(@element), :id => "element_raw_tags", :class => "full") 
t(:available_tags, :scope => [:content, :edit])
 t(:available_tags_info, :scope => [:content, :edit]) 
 if tags.any? 
 tags.join.html_safe 
 else 
 t(:no_tags_available, :scope => [:content,:edit]) 
 end 
 if tags.any? 
 end 
 end 
 
 end 
 content_for :footer do 
  if !@element.matching_versions? 
 t(:version_conflict, :scope => [:content, :edit], :current_author => @element.current_author) 
 show_url = object_url(@element,url_options_for_record(@element,:action => "show")) 
 link_to_function(t(:see_changes_by, :scope => [:content, :edit], :current_author => @element.current_author), 
                  "popup('#{show_url}',800,800,'scrollbars=yes')", :href => show_url) 
 link_to t(:discard_changes, :scope => [:content, :edit]),object_url(@element,url_options_for_record(@element,:discard => 1)) 
 else 
 submit_button :save, :class => "medium green", :onclick => "tinymce.triggerSave(); $('contentform').submit();" 
 end 
 
 end 

end

  end
  
  def delete
    @element = stack.last
    if request.post? || request.xhr?
      if @element.destroy
        notifications[:success] = t(:successfully_deleted, :scope => [:content, :flashes], :class => @element.class.singular_name)
      else
        messages[:error] = t(:fail_deleted, :scope => [:content, :flashes], :class => @element.class.singular_name)
      end
    end
    respond_to do |format|
      format.html{ redirect_after(:delete) }
      format.js { javascript_redirect_to(redirect_url_after(:delete)) }
    end
  end
  
  def order
    if request.xhr? && stack.klass.orderable? && params[:order]
      ids = params[:order].split(",").collect{|s| s.to_i}
      if ids.size > 1 && stack.klass.reorder(ids)
      elsif ids.size <= 1
        render :nothing => true
      else
        list_elements!
      end
    end  
    if !request.xhr?
      redirect_to :action => "list", :types => stack.url_types(:up => 1, :collection => true) 
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 if @elements 
 escape_javascript presenter_for(@elements,stack.klass) 
 else 
 stack.klass.name 
 end 

end

  end
  
  def create
    @element = stack.last    
    @element.attributes = params[:element]
            
    if request.post?
      @element.relate_to(stack.parent) if stack.has_parent?
      if @element.save
        notifications[:success] = t(:successfully_saved, :scope => [:content,:flashes], :class => @element.class.singular_name)
        redirect_after :save, @element
      else
        messages.now[:error] = t(:validation_error, :scope => [:content, :flashes], :class => @element.class.singular_name)
      end
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 content_for :header do 
 @title = t :title, :scope => [:content, :create], :class => stack.klass.singular_name.downcase 
 end 
 content_form :element, {:action => "create", :multipart => true, :submit_value => "save"} do 
  if @element.class.publishable? 
 t(:publish, :scope => [:content, :edit]) 
 publish_field = Skyline::Content::MetaData::Field.new(:name => 'published', :owner => @element.class) 
 boolean_field('element[published]',@element, publish_field, :class => "checkbox",:id => "element_published") 
 t(:published, :scope => [:content, :edit]) 
 end 
 if @element.class.taggable? 
 t(:meta_information, :scope => [:content, :edit]) 
 tags = @element.available_tags.collect{|tag| content_tag("li", tag.tag)} 
 raw_tags_field = Skyline::Content::MetaData::Field.new(:name => 'raw_tags', :owner => @element.class) 
 t(:tags, :scope => [:content, :edit]) 
 text_area_tag("element[raw_tags]", raw_tags_field.value(@element), :id => "element_raw_tags", :class => "full") 
t(:available_tags, :scope => [:content, :edit])
 t(:available_tags_info, :scope => [:content, :edit]) 
 if tags.any? 
 tags.join.html_safe 
 else 
 t(:no_tags_available, :scope => [:content,:edit]) 
 end 
 if tags.any? 
 end 
 end 
 
 end 
 content_for :footer do 
  if !@element.matching_versions? 
 t(:version_conflict, :scope => [:content, :edit], :current_author => @element.current_author) 
 show_url = object_url(@element,url_options_for_record(@element,:action => "show")) 
 link_to_function(t(:see_changes_by, :scope => [:content, :edit], :current_author => @element.current_author), 
                  "popup('#{show_url}',800,800,'scrollbars=yes')", :href => show_url) 
 link_to t(:discard_changes, :scope => [:content, :edit]),object_url(@element,url_options_for_record(@element,:discard => 1)) 
 else 
 submit_button :save, :class => "medium green", :onclick => "tinymce.triggerSave(); $('contentform').submit();" 
 end 
 
 end 

end

  end
  
  def export
    if stack.size > 1
      exportfile = stack.parent_collection.send("export")
    else
      exportfile = stack.klass.send("export")
    end
    content_type = "application/octet-stream"
    filename = "export_#{Time.now.strftime('%Y-%m-%d')}.xml"
    send_data exportfile.to_s, :type => content_type, :filename => filename
  end
    
  def import
    if request.xhr?
      if stack.size > 1
        @klass = stack.parent_collection.to_s
      else
        @klass = stack.klass.to_s
      end
      
      @url = object_url(stack.current, {:action => "import"})          
    end  
    
    if request.post?
      if params[:xml_file].present?
        xml = params[:xml_file].read
        errors = stack.klass.import(xml)
        if errors === true || errors.empty?
          notifications[:success] = t(:successfully_imported, :scope => [:content, :flashes])
        else
          notifications[:error] = t(:import_failed, :scope => [:content, :flashes], :errors => "<br /><br />\n <ul><li>#{errors.join("</li>\n<li>")}</li></ul>")
        end          
      else
        notifications[:error] = t(:no_import_file_selected, :scope => [:content, :flashes])
      end
      redirect_to params[:return_to]
    end  
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 dialog(
      t(:dialog_title, :scope => [:content, :import]), 
      :partial => "import", 
      :locals => {:url => @url, :klass => @klass},  :width => 400) 

end

  end
  
  # Editor can only be called on editors and when params[:field] is set
  def field
    return unless request.xhr?
    @element = stack.last
    @element.attributes = params[:element]
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 input_id("field","element",params[:field]) 
 escape_javascript content_field(@element.class, 'element', @element.class.fields[params[:field].to_sym] || Field.new(:name => params[:field]), @element) 

end

  end
  
  def error
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 l(:content,:error,:title) 
 l(:content,:error,:body) 

end

  end  
  
  protected
  
  def redirect_after(method,object=nil)
    redirect_to redirect_url_after(method,object)
  end
  
  def redirect_url_after(method,object=nil)
    if method == :save && params[:return_to] == "self"
      types = stack.url_types
      types << object.id if object && !stack.url_types.last.kind_of?(Fixnum)
      {:action => "edit", :types => types}
    else
      params[:return_to] || {:action => "list", :types => stack.url_types(:up => 1, :collection => true)}
    end    
  end
  
  # Create the @elements array according to stack
  def list_elements!
    if stack.size > 1
      @elements = stack.parent && stack.parent_collection.find_for_cms(:all, :filter => params[:filter])
    else
      @count = stack.last.class.count_for_cms(:all,:self_referential => false, :filter => params[:filter])
      @elements = stack.last.class.paginate_for_cms(:page => params[:page], :per_page => 30, :self_referential => false, :filter => params[:filter]).all
    end    
  end  

end