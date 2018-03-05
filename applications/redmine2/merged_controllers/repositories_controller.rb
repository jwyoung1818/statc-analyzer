require 'digest/sha1'
require 'redmine/scm/adapters'
class ChangesetNotFound < Exception; end
class InvalidRevisionParam < Exception; end
class RepositoriesController < ApplicationController
  menu_item :repository
  menu_item :settings, :only => [:new, :create, :edit, :update, :destroy, :committers]
  default_search_scope :changesets
  before_action :find_project_by_project_id, :only => [:new, :create]
  before_action :build_new_repository_from_params, :only => [:new, :create]
  before_action :find_repository, :only => [:edit, :update, :destroy, :committers]
  before_action :find_project_repository, :except => [:new, :create, :edit, :update, :destroy, :committers]
  before_action :find_changeset, :only => [:revision, :add_related_issue, :remove_related_issue]
  before_action :authorize
  accept_rss_auth :revisions
  rescue_from Redmine::Scm::Adapters::CommandFailed, :with => :show_error_command_failed
  def new
    @repository.is_default = @project.repository.nil?
  end
 l(:label_repository_new) 
 labelled_form_for :repository, @repository, :url => project_repositories_path(@project), :html => {:id => 'repository-form'} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 end 
  def create
    if @repository.save
      redirect_to settings_project_path(@project, :tab => 'repositories')
    else
      render :action => 'new'
 l(:label_repository_new) 
 labelled_form_for :repository, @repository, :url => project_repositories_path(@project), :html => {:id => 'repository-form'} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 end 
    end
  end
  def edit
  end
 l(:label_repository) 
 labelled_form_for :repository, @repository, :url => repository_path(@repository), :html => {:method => :put, :id => 'repository-form'} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 end 
  def update
    @repository.safe_attributes = params[:repository]
    if @repository.save
      redirect_to settings_project_path(@project, :tab => 'repositories')
    else
      render :action => 'edit'
 l(:label_repository) 
 labelled_form_for :repository, @repository, :url => repository_path(@repository), :html => {:method => :put, :id => 'repository-form'} do |f| 
 render :partial => 'form', :locals => {:f => f} 
 end 
    end
  end
  def committers
    @committers = @repository.committers
    @users = @project.users.to_a
    additional_user_ids = @committers.collect(&:last).collect(&:to_i) - @users.collect(&:id)
    @users += User.where(:id => additional_user_ids).to_a unless additional_user_ids.empty?
    @users.compact!
    @users.sort!
    if request.post? && params[:committers].present?
      @repository.committer_ids = params[:committers].values.inject({}) {|h, c| h[c.first] = c.last; h}
      flash[:notice] = l(:notice_successful_update)
      redirect_to settings_project_path(@project, :tab => 'repositories')
    end
  end
 l(:label_repository) 
 simple_format(l(:text_repository_usernames_mapping)) 
 if @committers.empty? 
 l(:label_no_data) 
 else 
 form_tag({}) do 
 l(:field_login) 
 l(:label_user) 
 i = 0 
 @committers.each do |committer, user_id| 
 committer 
 hidden_field_tag "committers[#{i}][]", committer, :id => nil 
 select_tag "committers[#{i}][]",
                      content_tag(
                            'option',
                            "-- #{l :actionview_instancetag_blank_option} --",
                            :value => ''
                          ) +
                        options_from_collection_for_select(
                            @users, 'id', 'name', user_id.to_i
                          ) 
 i += 1 
 end 
 submit_tag(l(:button_save)) 
 end 
 end 
  def destroy
    @repository.destroy if request.delete?
    redirect_to settings_project_path(@project, :tab => 'repositories')
  end
  def show
    @repository.fetch_changesets if @project.active? && Setting.autofetch_changesets? && @path.empty?
    @entries = @repository.entries(@path, @rev)
    @changeset = @repository.find_changeset_by_name(@rev)
    if request.xhr?
      @entries ? render(:partial => 'dir_list_content') : head(200)
 @entries.each do |entry| 
 tr_id = Digest::MD5.hexdigest(entry.path)
   depth = params[:depth].to_i 
  ent_path = Redmine::CodesetUtil.replace_invalid_utf8(entry.path)   
  ent_name = Redmine::CodesetUtil.replace_invalid_utf8(entry.name)   
 tr_id 
 params[:parent_id] 
 entry.kind 
18 * depth
           @repository.report_last_commit ? "filename" : "filename_no_report" 
 if entry.is_dir? 
 tr_id 
 escape_javascript(url_for(
                       :action => 'show',
                       :id     => @project,
                       :repository_id => @repository.identifier_param,
                       :path   => to_path_param(ent_path),
                       :rev    => @rev,
                       :depth  => (depth + 1),
                       :parent_id => tr_id)) 
 end 
  link_to ent_name,
          {:action => (entry.is_dir? ? 'show' : 'entry'), :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(ent_path), :rev => @rev},
          :class => (entry.is_dir? ? 'icon icon-folder' : "icon icon-file #{Redmine::MimeType.css_class_of(ent_name)}")
 (entry.size ? number_to_human_size(entry.size) : "?") unless entry.is_dir? 
 if @repository.report_last_commit 
 link_to_revision(entry.changeset, @repository) if entry.changeset 
 distance_of_time_in_words(entry.lastrev.time, Time.now) if entry.lastrev && entry.lastrev.time 
 entry.author 
 entry.changeset.comments.truncate(50) if entry.changeset 
 end 
 end 
    else
      (show_error_not_found; return) unless @entries
      @changesets = @repository.latest_changesets(@path, @rev)
      @properties = @repository.properties(@path, @rev)
      @repositories = @project.repositories
      render :action => 'show'
 call_hook(:view_repositories_show_contextual, { :repository => @repository, :project => @project }) 
 render :partial => 'navigation' 
 content_for :header_tags do 
 javascript_include_tag 'repository_navigation' 
 end 
 if @entry && !@entry.is_dir? && @repository.supports_cat? 
 download_label = @entry.size ? "#{l :button_download} (#{number_to_human_size @entry.size})" : l(:button_download) 
 link_to(download_label,
              {:action => 'raw', :id => @project,
               :repository_id => @repository.identifier_param,
               :path => to_path_param(@path),
               :rev => @rev}, class: 'icon icon-download') 
 end 
 link_to l(:label_statistics),
            {:action => 'stats', :id => @project, :repository_id => @repository.identifier_param},
            :class => 'icon icon-stats' if @repository.supports_all_revisions? 
 form_tag({:action => controller.action_name,
             :id => @project,
             :repository_id => @repository.identifier_param,
             :path => to_path_param(@path),
             :rev => nil},
            {:method => :get, :id => 'revision_selector'}) do 
 if !@repository.branches.nil? && @repository.branches.length > 0 
 l(:label_branch) 
 select_tag :branch,
                   options_for_select([''] + @repository.branches, @rev),
                   :id => 'branch' 
 end 
 if !@repository.tags.nil? && @repository.tags.length > 0 
 l(:label_tag) 
 select_tag :tag,
                   options_for_select([''] + @repository.tags, @rev),
                   :id => 'tag' 
 end 
 if @repository.supports_all_revisions? 
 l(:label_revision) 
 text_field_tag 'rev', @rev, :size => 8 
 end 
 end 
 render :partial => 'breadcrumbs',
               :locals => { :path => @path, :kind => 'dir', :revision => @rev } 
 link_to(@repository.identifier.present? ? @repository.identifier : 'root',
      :action => 'show', :id => @project,
      :repository_id => @repository.identifier_param,
      :path => nil, :rev => @rev) 
dirs = path.split('/')
if 'file' == kind
    filename = dirs.pop
end
link_path = ''
dirs.each do |dir|
    next if dir.blank?
    link_path << '/' unless link_path.empty?
    link_path << "#{dir}"
 link_to dir, :action => 'show', :id => @project, :repository_id => @repository.identifier_param,
                :path => to_path_param(link_path), :rev => @rev 
 end 
 if filename 
 link_to filename,
                   :action => 'entry', :id => @project, :repository_id => @repository.identifier_param,
                   :path => to_path_param("#{link_path}/#{filename}"), :rev => @rev 
 end 
  rev_text = @changeset.nil? ? @rev : format_revision(@changeset)
 "@ #{rev_text}" unless rev_text.blank? 
 html_title(with_leading_slash(path)) 
 if !@entries.nil? && authorize_for('repositories', 'browse') 
 render :partial => 'dir_list' 
 l(:field_name) 
 l(:field_filesize) 
 if @repository.report_last_commit 
 l(:label_revision)  
 l(:label_age)       
 l(:field_author)    
 l(:field_comments)  
 end 
 render :partial => 'dir_list_content' 
 end 
 render_properties(@properties) 
 if authorize_for('repositories', 'revisions') 
 if @changesets && !@changesets.empty? 
 l(:label_latest_revision_plural) 
 render :partial => 'revisions',
              :locals => {:project => @project, :path => @path,
                          :revisions => @changesets, :entry => nil }
 show_revision_graph = ( @repository.supports_revision_graph? && path.blank? ) 
 if show_revision_graph && revisions && revisions.any?
    indexed_commits, graph_space = index_commits(revisions, @repository.branches) do |scmid|
                             url_for(
                               :controller => 'repositories',
                               :action => 'revision',
                               :id => project,
                               :repository_id => @repository.identifier_param,
                               :rev => scmid)
                         end
    render :partial => 'revision_graph',
         :locals => {
            :commits => indexed_commits,
            :space => graph_space
        }
 javascript_tag do 
 commits.to_json.html_safe 
 space 
 end 
 content_for :header_tags do 
 javascript_include_tag 'raphael' 
 javascript_include_tag 'revision_graph' 
 end 
end 
 form_tag(
      {:controller => 'repositories', :action => 'diff', :id => project,
       :repository_id => @repository.identifier_param, :path => to_path_param(path)},
      :method => :get
     ) do 
 l(:label_date) 
 l(:field_author) 
 l(:field_comments) 
 show_diff = revisions.size > 1 
 line_num = 1 
 revisions.each do |changeset| 
 id_style = (show_revision_graph ? "padding-left:#{(graph_space + 1) * 20}px" : nil) 
 content_tag(:td, :class => 'id', :style => id_style) do 
 link_to_revision(changeset, @repository) 
 end 
 radio_button_tag('rev', changeset.identifier, (line_num==1), :id => "cb-#{line_num}", :onclick => "$('#cbto-#{line_num+1}').prop('checked',true);") if show_diff && (line_num < revisions.size) 
 radio_button_tag('rev_to', changeset.identifier, (line_num==2), :id => "cbto-#{line_num}", :onclick => "if ($('#cb-#{line_num}').prop('checked')) {$('#cb-#{line_num-1}').prop('checked',true);}") if show_diff && (line_num > 1) 
 format_time(changeset.committed_on) 
 changeset.user.blank? ? changeset.author.to_s.truncate(30) : link_to_user(changeset.user) 
 textilizable(truncate_at_line_break(changeset.comments), :formatting => Setting.commit_logs_formatting?) 
 line_num += 1 
 end 
 submit_tag(l(:label_view_diff), :name => nil) if show_diff 
 end 
 end 
 has_branches = (!@repository.branches.nil? && @repository.branches.length > 0)
     sep = '' 
 if @repository.supports_all_revisions? && @path.blank? 
 link_to l(:label_view_all_revisions), :action => 'revisions', :id => @project,
                :repository_id => @repository.identifier_param 
 sep = '|' 
 end 
 if @repository.supports_directory_revisions? &&
         ( has_branches || !@path.blank? || !@rev.blank? ) 
 sep 
 link_to l(:label_view_revisions),
                   :action => 'changes',
                   :path   => to_path_param(@path),
                   :id     => @project,
                   :repository_id => @repository.identifier_param,
                   :rev    => @rev 
 end 
 if @repository.supports_all_revisions? 
 content_for :header_tags do 
 auto_discovery_link_tag(
                   :atom,
                   :action => 'revisions', :id => @project,
                   :repository_id => @repository.identifier_param,
                   :key => User.current.rss_key) 
 end 
 other_formats_links do |f| 
 f.link_to 'Atom',
                  :url => {:action => 'revisions', :id => @project,
                           :repository_id => @repository.identifier_param,
                           :key => User.current.rss_key} 
 end 
 end 
 end 
 if @repositories.size > 1 
 content_for :sidebar do 
 l(:label_repository_plural) 
 @repositories.sort.collect {|repo|
          link_to repo.name, 
                  {:controller => 'repositories', :action => 'show',
                   :id => @project, :repository_id => repo.identifier_param, :rev => nil, :path => nil},
                  :class => 'repository' + (repo == @repository ? ' selected' : '')
        }.join('<br />').html_safe 
 end 
 end 
 content_for :header_tags do 
 stylesheet_link_tag "scm" 
 end 
 html_title(l(:label_repository)) 
    end
  end
  alias_method :browse, :show
  def changes
    @entry = @repository.entry(@path, @rev)
    (show_error_not_found; return) unless @entry
    @changesets = @repository.latest_changesets(@path, @rev, Setting.repository_log_display_limit.to_i)
    @properties = @repository.properties(@path, @rev)
    @changeset = @repository.find_changeset_by_name(@rev)
  end
 call_hook(:view_repositories_show_contextual, { :repository => @repository, :project => @project }) 
 render :partial => 'navigation' 
 content_for :header_tags do 
 javascript_include_tag 'repository_navigation' 
 end 
 if @entry && !@entry.is_dir? && @repository.supports_cat? 
 download_label = @entry.size ? "#{l :button_download} (#{number_to_human_size @entry.size})" : l(:button_download) 
 link_to(download_label,
              {:action => 'raw', :id => @project,
               :repository_id => @repository.identifier_param,
               :path => to_path_param(@path),
               :rev => @rev}, class: 'icon icon-download') 
 end 
 link_to l(:label_statistics),
            {:action => 'stats', :id => @project, :repository_id => @repository.identifier_param},
            :class => 'icon icon-stats' if @repository.supports_all_revisions? 
 form_tag({:action => controller.action_name,
             :id => @project,
             :repository_id => @repository.identifier_param,
             :path => to_path_param(@path),
             :rev => nil},
            {:method => :get, :id => 'revision_selector'}) do 
 if !@repository.branches.nil? && @repository.branches.length > 0 
 l(:label_branch) 
 select_tag :branch,
                   options_for_select([''] + @repository.branches, @rev),
                   :id => 'branch' 
 end 
 if !@repository.tags.nil? && @repository.tags.length > 0 
 l(:label_tag) 
 select_tag :tag,
                   options_for_select([''] + @repository.tags, @rev),
                   :id => 'tag' 
 end 
 if @repository.supports_all_revisions? 
 l(:label_revision) 
 text_field_tag 'rev', @rev, :size => 8 
 end 
 end 
 render :partial => 'breadcrumbs', :locals => { :path => @path, :kind => (@entry ? @entry.kind : nil), :revision => @rev } 
 link_to(@repository.identifier.present? ? @repository.identifier : 'root',
      :action => 'show', :id => @project,
      :repository_id => @repository.identifier_param,
      :path => nil, :rev => @rev) 
dirs = path.split('/')
if 'file' == kind
    filename = dirs.pop
end
link_path = ''
dirs.each do |dir|
    next if dir.blank?
    link_path << '/' unless link_path.empty?
    link_path << "#{dir}"
 link_to dir, :action => 'show', :id => @project, :repository_id => @repository.identifier_param,
                :path => to_path_param(link_path), :rev => @rev 
 end 
 if filename 
 link_to filename,
                   :action => 'entry', :id => @project, :repository_id => @repository.identifier_param,
                   :path => to_path_param("#{link_path}/#{filename}"), :rev => @rev 
 end 
  rev_text = @changeset.nil? ? @rev : format_revision(@changeset)
 "@ #{rev_text}" unless rev_text.blank? 
 html_title(with_leading_slash(path)) 
 render :partial => 'link_to_functions' 
 if @entry && @entry.kind == 'file' 
tabs = []
tabs << { name: 'entry', label: :button_view,
          url: {:action => 'entry', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        } if @repository.supports_cat?
tabs << { name: 'changes', label: :label_history,
          url: {:action => 'changes', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        }
tabs << { name: 'annotate', label: :button_annotate,
          url: {:action => 'annotate', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        } if @repository.supports_annotate?
 render :partial => 'common/tabs', :locals => {:tabs => tabs, :selected_tab => action_name} 
 tabs.each do |tab| 
 link_to l(tab[:label]), (tab[:url] || { :tab => tab[:name] }),
                                    :id => "tab-#{tab[:name]}",
                                    :class => (tab[:name] != selected_tab ? nil : 'selected'),
                                    :onclick => tab[:partial] ? "showTab('#{tab[:name]}', this.href); this.blur(); return false;" : nil 
 end 
 tabs.each do |tab| 
 content_tag('div', render(:partial => tab[:partial], :locals => {:tab => tab} ),
                       :id => "tab-content-#{tab[:name]}",
                       :style => (tab[:name] != selected_tab ? 'display:none' : nil),
                       :class => 'tab-content') if tab[:partial] 
 end 
 end 
 render_properties(@properties) 
 render(:partial => 'revisions',
           :locals => {:project => @project, :path => @path, :revisions => @changesets, :entry => @entry }) unless @changesets.empty? 
 show_revision_graph = ( @repository.supports_revision_graph? && path.blank? ) 
 if show_revision_graph && revisions && revisions.any?
    indexed_commits, graph_space = index_commits(revisions, @repository.branches) do |scmid|
                             url_for(
                               :controller => 'repositories',
                               :action => 'revision',
                               :id => project,
                               :repository_id => @repository.identifier_param,
                               :rev => scmid)
                         end
    render :partial => 'revision_graph',
         :locals => {
            :commits => indexed_commits,
            :space => graph_space
        }
 javascript_tag do 
 commits.to_json.html_safe 
 space 
 end 
 content_for :header_tags do 
 javascript_include_tag 'raphael' 
 javascript_include_tag 'revision_graph' 
 end 
end 
 form_tag(
      {:controller => 'repositories', :action => 'diff', :id => project,
       :repository_id => @repository.identifier_param, :path => to_path_param(path)},
      :method => :get
     ) do 
 l(:label_date) 
 l(:field_author) 
 l(:field_comments) 
 show_diff = revisions.size > 1 
 line_num = 1 
 revisions.each do |changeset| 
 id_style = (show_revision_graph ? "padding-left:#{(graph_space + 1) * 20}px" : nil) 
 content_tag(:td, :class => 'id', :style => id_style) do 
 link_to_revision(changeset, @repository) 
 end 
 radio_button_tag('rev', changeset.identifier, (line_num==1), :id => "cb-#{line_num}", :onclick => "$('#cbto-#{line_num+1}').prop('checked',true);") if show_diff && (line_num < revisions.size) 
 radio_button_tag('rev_to', changeset.identifier, (line_num==2), :id => "cbto-#{line_num}", :onclick => "if ($('#cb-#{line_num}').prop('checked')) {$('#cb-#{line_num-1}').prop('checked',true);}") if show_diff && (line_num > 1) 
 format_time(changeset.committed_on) 
 changeset.user.blank? ? changeset.author.to_s.truncate(30) : link_to_user(changeset.user) 
 textilizable(truncate_at_line_break(changeset.comments), :formatting => Setting.commit_logs_formatting?) 
 line_num += 1 
 end 
 submit_tag(l(:label_view_diff), :name => nil) if show_diff 
 end 
 content_for :header_tags do 
   stylesheet_link_tag "scm" 
 end 
 html_title(l(:label_change_plural)) 
  def revisions
    @changeset_count = @repository.changesets.count
    @changeset_pages = Paginator.new @changeset_count,
                                     per_page_option,
                                     params['page']
    @changesets = @repository.changesets.
      limit(@changeset_pages.per_page).
      offset(@changeset_pages.offset).
      includes(:user, :repository, :parents).
      to_a
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.atom { render_feed(@changesets, :title => "#{@project.name}: #{l(:label_revision_plural)}") }
    end
  end
 form_tag(
       {:controller => 'repositories', :action => 'revision', :id => @project,
        :repository_id => @repository.identifier_param},
       :method => :get
     ) do 
 l(:label_revision) 
 text_field_tag 'rev', nil, :size => 8 
 submit_tag 'OK' 
 end 
 l(:label_revision_plural) 
 render :partial => 'revisions',
           :locals => {:project   => @project,
                       :path      => '',
                       :revisions => @changesets,
                       :entry     => nil } 
 show_revision_graph = ( @repository.supports_revision_graph? && path.blank? ) 
 if show_revision_graph && revisions && revisions.any?
    indexed_commits, graph_space = index_commits(revisions, @repository.branches) do |scmid|
                             url_for(
                               :controller => 'repositories',
                               :action => 'revision',
                               :id => project,
                               :repository_id => @repository.identifier_param,
                               :rev => scmid)
                         end
    render :partial => 'revision_graph',
         :locals => {
            :commits => indexed_commits,
            :space => graph_space
        }
 javascript_tag do 
 commits.to_json.html_safe 
 space 
 end 
 content_for :header_tags do 
 javascript_include_tag 'raphael' 
 javascript_include_tag 'revision_graph' 
 end 
end 
 form_tag(
      {:controller => 'repositories', :action => 'diff', :id => project,
       :repository_id => @repository.identifier_param, :path => to_path_param(path)},
      :method => :get
     ) do 
 l(:label_date) 
 l(:field_author) 
 l(:field_comments) 
 show_diff = revisions.size > 1 
 line_num = 1 
 revisions.each do |changeset| 
 id_style = (show_revision_graph ? "padding-left:#{(graph_space + 1) * 20}px" : nil) 
 content_tag(:td, :class => 'id', :style => id_style) do 
 link_to_revision(changeset, @repository) 
 end 
 radio_button_tag('rev', changeset.identifier, (line_num==1), :id => "cb-#{line_num}", :onclick => "$('#cbto-#{line_num+1}').prop('checked',true);") if show_diff && (line_num < revisions.size) 
 radio_button_tag('rev_to', changeset.identifier, (line_num==2), :id => "cbto-#{line_num}", :onclick => "if ($('#cb-#{line_num}').prop('checked')) {$('#cb-#{line_num-1}').prop('checked',true);}") if show_diff && (line_num > 1) 
 format_time(changeset.committed_on) 
 changeset.user.blank? ? changeset.author.to_s.truncate(30) : link_to_user(changeset.user) 
 textilizable(truncate_at_line_break(changeset.comments), :formatting => Setting.commit_logs_formatting?) 
 line_num += 1 
 end 
 submit_tag(l(:label_view_diff), :name => nil) if show_diff 
 end 
 pagination_links_full @changeset_pages,@changeset_count 
 content_for :header_tags do 
 stylesheet_link_tag "scm" 
 auto_discovery_link_tag(
               :atom,
               :params => request.query_parameters.merge(:page => nil, :key => User.current.rss_key),
               :format => 'atom') 
 end 
 other_formats_links do |f| 
 f.link_to 'Atom', :url => {:key => User.current.rss_key} 
 end 
 html_title(l(:label_revision_plural)) 
  def raw
    entry_and_raw(true)
  end
  def entry
    entry_and_raw(false)
  end
 call_hook(:view_repositories_show_contextual, { :repository => @repository, :project => @project }) 
 render :partial => 'navigation' 
 content_for :header_tags do 
 javascript_include_tag 'repository_navigation' 
 end 
 if @entry && !@entry.is_dir? && @repository.supports_cat? 
 download_label = @entry.size ? "#{l :button_download} (#{number_to_human_size @entry.size})" : l(:button_download) 
 link_to(download_label,
              {:action => 'raw', :id => @project,
               :repository_id => @repository.identifier_param,
               :path => to_path_param(@path),
               :rev => @rev}, class: 'icon icon-download') 
 end 
 link_to l(:label_statistics),
            {:action => 'stats', :id => @project, :repository_id => @repository.identifier_param},
            :class => 'icon icon-stats' if @repository.supports_all_revisions? 
 form_tag({:action => controller.action_name,
             :id => @project,
             :repository_id => @repository.identifier_param,
             :path => to_path_param(@path),
             :rev => nil},
            {:method => :get, :id => 'revision_selector'}) do 
 if !@repository.branches.nil? && @repository.branches.length > 0 
 l(:label_branch) 
 select_tag :branch,
                   options_for_select([''] + @repository.branches, @rev),
                   :id => 'branch' 
 end 
 if !@repository.tags.nil? && @repository.tags.length > 0 
 l(:label_tag) 
 select_tag :tag,
                   options_for_select([''] + @repository.tags, @rev),
                   :id => 'tag' 
 end 
 if @repository.supports_all_revisions? 
 l(:label_revision) 
 text_field_tag 'rev', @rev, :size => 8 
 end 
 end 
 render :partial => 'breadcrumbs', :locals => { :path => @path, :kind => 'file', :revision => @rev } 
 link_to(@repository.identifier.present? ? @repository.identifier : 'root',
      :action => 'show', :id => @project,
      :repository_id => @repository.identifier_param,
      :path => nil, :rev => @rev) 
dirs = path.split('/')
if 'file' == kind
    filename = dirs.pop
end
link_path = ''
dirs.each do |dir|
    next if dir.blank?
    link_path << '/' unless link_path.empty?
    link_path << "#{dir}"
 link_to dir, :action => 'show', :id => @project, :repository_id => @repository.identifier_param,
                :path => to_path_param(link_path), :rev => @rev 
 end 
 if filename 
 link_to filename,
                   :action => 'entry', :id => @project, :repository_id => @repository.identifier_param,
                   :path => to_path_param("#{link_path}/#{filename}"), :rev => @rev 
 end 
  rev_text = @changeset.nil? ? @rev : format_revision(@changeset)
 "@ #{rev_text}" unless rev_text.blank? 
 html_title(with_leading_slash(path)) 
 render :partial => 'link_to_functions' 
 if @entry && @entry.kind == 'file' 
tabs = []
tabs << { name: 'entry', label: :button_view,
          url: {:action => 'entry', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        } if @repository.supports_cat?
tabs << { name: 'changes', label: :label_history,
          url: {:action => 'changes', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        }
tabs << { name: 'annotate', label: :button_annotate,
          url: {:action => 'annotate', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        } if @repository.supports_annotate?
 render :partial => 'common/tabs', :locals => {:tabs => tabs, :selected_tab => action_name} 
 tabs.each do |tab| 
 link_to l(tab[:label]), (tab[:url] || { :tab => tab[:name] }),
                                    :id => "tab-#{tab[:name]}",
                                    :class => (tab[:name] != selected_tab ? nil : 'selected'),
                                    :onclick => tab[:partial] ? "showTab('#{tab[:name]}', this.href); this.blur(); return false;" : nil 
 end 
 tabs.each do |tab| 
 content_tag('div', render(:partial => tab[:partial], :locals => {:tab => tab} ),
                       :id => "tab-content-#{tab[:name]}",
                       :style => (tab[:name] != selected_tab ? 'display:none' : nil),
                       :class => 'tab-content') if tab[:partial] 
 end 
 end 
 if Redmine::MimeType.is_type?('image', @path) 
 render :partial => 'common/image', :locals => {:path => url_for(:action => 'raw',
                                                                      :id     => @project,
                                                                      :repository_id => @repository.identifier_param,
                                                                      :path   => @path,
                                                                      :rev    => @rev), :alt => @path} 
 image_tag path, :alt => alt, :class => 'filecontent image' 
 elsif @content 
 render :partial => 'common/file', :locals => {:filename => @path, :content => @content} 
 line_num = 1 
 syntax_highlight_lines(filename, Redmine::CodesetUtil.to_utf8_by_setting(content)).each do |line| 
 line_num 
 line_num 
 line_num 
 line.html_safe 
 line_num += 1 
 end 
 else 
 render :partial => 'common/other',
             :locals => {
               :download_link => @repository.supports_cat? ? link_to(
                 l(:label_no_preview_download),
                 { :action => 'raw', :id => @project,
                   :repository_id => @repository.identifier_param,
                   :path => to_path_param(@path),
                   :rev => @rev },
                :class => 'icon icon-download') : nil } 
 if defined? download_link 
 t(:label_no_preview_alternative_html, link: download_link) 
 else 
 l(:label_no_preview) 
 end 
 end 
 content_for :header_tags do 
 stylesheet_link_tag "scm" 
 end 
  def entry_and_raw(is_raw)
    @entry = @repository.entry(@path, @rev)
    (show_error_not_found; return) unless @entry
    (show; return) if @entry.is_dir?
    if is_raw
      send_opt = { :filename => filename_for_content_disposition(@path.split('/').last) }
      send_type = Redmine::MimeType.of(@path)
      send_opt[:type] = send_type.to_s if send_type
      send_opt[:disposition] = disposition(@path)
      send_data @repository.cat(@path, @rev), send_opt
    else
      if !@entry.size || @entry.size <= Setting.file_max_size_displayed.to_i.kilobyte
        content = @repository.cat(@path, @rev)
        (show_error_not_found; return) unless content
        if content.size <= Setting.file_max_size_displayed.to_i.kilobyte &&
           is_entry_text_data?(content, @path)
          @content = content.gsub("\r\n", "\n")
        end
      end
      @changeset = @repository.find_changeset_by_name(@rev)
    end
  end
  private :entry_and_raw
  def is_entry_text_data?(ent, path)
    return true if Redmine::MimeType.is_type?('text', path)
    return false if Redmine::Scm::Adapters::ScmData.binary?(ent)
    true
  end
  private :is_entry_text_data?
  def annotate
    @entry = @repository.entry(@path, @rev)
    (show_error_not_found; return) unless @entry
    @annotate = @repository.scm.annotate(@path, @rev)
    if @annotate.nil? || @annotate.empty?
      @annotate = nil
      @error_message = l(:error_scm_annotate)
    else
      ann_buf_size = 0
      @annotate.lines.each do |buf|
        ann_buf_size += buf.size
      end
      if ann_buf_size > Setting.file_max_size_displayed.to_i.kilobyte
        @annotate = nil
        @error_message = l(:error_scm_annotate_big_text_file)
      end
    end
    @changeset = @repository.find_changeset_by_name(@rev)
  end
 call_hook(:view_repositories_show_contextual, { :repository => @repository, :project => @project }) 
 render :partial => 'navigation' 
 content_for :header_tags do 
 javascript_include_tag 'repository_navigation' 
 end 
 if @entry && !@entry.is_dir? && @repository.supports_cat? 
 download_label = @entry.size ? "#{l :button_download} (#{number_to_human_size @entry.size})" : l(:button_download) 
 link_to(download_label,
              {:action => 'raw', :id => @project,
               :repository_id => @repository.identifier_param,
               :path => to_path_param(@path),
               :rev => @rev}, class: 'icon icon-download') 
 end 
 link_to l(:label_statistics),
            {:action => 'stats', :id => @project, :repository_id => @repository.identifier_param},
            :class => 'icon icon-stats' if @repository.supports_all_revisions? 
 form_tag({:action => controller.action_name,
             :id => @project,
             :repository_id => @repository.identifier_param,
             :path => to_path_param(@path),
             :rev => nil},
            {:method => :get, :id => 'revision_selector'}) do 
 if !@repository.branches.nil? && @repository.branches.length > 0 
 l(:label_branch) 
 select_tag :branch,
                   options_for_select([''] + @repository.branches, @rev),
                   :id => 'branch' 
 end 
 if !@repository.tags.nil? && @repository.tags.length > 0 
 l(:label_tag) 
 select_tag :tag,
                   options_for_select([''] + @repository.tags, @rev),
                   :id => 'tag' 
 end 
 if @repository.supports_all_revisions? 
 l(:label_revision) 
 text_field_tag 'rev', @rev, :size => 8 
 end 
 end 
 render :partial => 'breadcrumbs', :locals => { :path => @path, :kind => 'file', :revision => @rev } 
 link_to(@repository.identifier.present? ? @repository.identifier : 'root',
      :action => 'show', :id => @project,
      :repository_id => @repository.identifier_param,
      :path => nil, :rev => @rev) 
dirs = path.split('/')
if 'file' == kind
    filename = dirs.pop
end
link_path = ''
dirs.each do |dir|
    next if dir.blank?
    link_path << '/' unless link_path.empty?
    link_path << "#{dir}"
 link_to dir, :action => 'show', :id => @project, :repository_id => @repository.identifier_param,
                :path => to_path_param(link_path), :rev => @rev 
 end 
 if filename 
 link_to filename,
                   :action => 'entry', :id => @project, :repository_id => @repository.identifier_param,
                   :path => to_path_param("#{link_path}/#{filename}"), :rev => @rev 
 end 
  rev_text = @changeset.nil? ? @rev : format_revision(@changeset)
 "@ #{rev_text}" unless rev_text.blank? 
 html_title(with_leading_slash(path)) 
 render :partial => 'link_to_functions' 
 if @entry && @entry.kind == 'file' 
tabs = []
tabs << { name: 'entry', label: :button_view,
          url: {:action => 'entry', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        } if @repository.supports_cat?
tabs << { name: 'changes', label: :label_history,
          url: {:action => 'changes', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        }
tabs << { name: 'annotate', label: :button_annotate,
          url: {:action => 'annotate', :id => @project, :repository_id => @repository.identifier_param, :path => to_path_param(@path), :rev => @rev }
        } if @repository.supports_annotate?
 render :partial => 'common/tabs', :locals => {:tabs => tabs, :selected_tab => action_name} 
 tabs.each do |tab| 
 link_to l(tab[:label]), (tab[:url] || { :tab => tab[:name] }),
                                    :id => "tab-#{tab[:name]}",
                                    :class => (tab[:name] != selected_tab ? nil : 'selected'),
                                    :onclick => tab[:partial] ? "showTab('#{tab[:name]}', this.href); this.blur(); return false;" : nil 
 end 
 tabs.each do |tab| 
 content_tag('div', render(:partial => tab[:partial], :locals => {:tab => tab} ),
                       :id => "tab-content-#{tab[:name]}",
                       :style => (tab[:name] != selected_tab ? 'display:none' : nil),
                       :class => 'tab-content') if tab[:partial] 
 end 
 end 
 if @annotate 
 colors = Hash.new {|k,v| k[v] = (k.size % 12) } 
 line_num = 1; previous_revision = nil 
 syntax_highlight_lines(@path, Redmine::CodesetUtil.to_utf8_by_setting(@annotate.content)).each do |line| 
 revision = @annotate.revisions[line_num - 1] 
 line_num 
 revision.nil? ? 0 : colors[revision.identifier || revision.revision] 
 previous_revision && revision && revision != previous_revision ? 'bloc-change' : nil
 line_num 
 line_num 
 if revision && revision != previous_revision 
 revision.identifier ?
                  link_to_revision(revision, @repository) : format_revision(revision) 
 end 
 if revision && revision != previous_revision 
 author = Redmine::CodesetUtil.to_utf8(revision.author.to_s,
                                                     @repository.repo_log_encoding) 
 author.split('<').first 
 end 
 line.html_safe 
 line_num += 1; previous_revision = revision 
 end 
 else 
 @error_message 
 end 
 html_title(l(:button_annotate)) 
 content_for :header_tags do 
 stylesheet_link_tag 'scm' 
 end 
  def revision
    respond_to do |format|
      format.html
      format.js {render :layout => false}
    end
  end
 unless @changeset.previous.nil? 
 link_to_revision(@changeset.previous, @repository,
      :text => l(:label_previous), :accesskey => accesskey(:previous)) 
 else 
 l(:label_previous) 
 end 
 unless @changeset.next.nil? 
 link_to_revision(@changeset.next, @repository,
      :text => l(:label_next), :accesskey => accesskey(:next)) 
 else 
 l(:label_next) 
 end 
 form_tag({:controller => 'repositories',
               :action     => 'revision',
               :id         => @project,
               :repository_id => @repository.identifier_param,
               :rev        => nil},
               :method     => :get) do 
 text_field_tag 'rev', @rev, :size => 8 
 submit_tag 'OK', :name => nil 
 end 
 render :partial => 'changeset' 
 l(:label_revision) 
 format_revision(@changeset) 
 avatar(@changeset.user, :size => "24") 
 authoring(@changeset.committed_on, @changeset.author) 
 if @changeset.scmid.present? || @changeset.parents.present? || @changeset.children.present? 
 if @changeset.scmid.present? 
 @changeset.scmid 
 end 
 if @changeset.parents.present? 
 l(:label_parent_revision) 
 @changeset.parents.collect{
                |p| link_to_revision(p, @repository, :text => format_revision(p))
              }.join(", ").html_safe 
 end 
 if @changeset.children.present? 
 l(:label_child_revision) 
 @changeset.children.collect{
                |p| link_to_revision(p, @repository, :text => format_revision(p))
               }.join(", ").html_safe 
 end 
 end 
 format_changeset_comments @changeset 
 if @changeset.issues.visible.any? || User.current.allowed_to?(:manage_related_issues, @repository.project) 
 render :partial => 'related_issues' 
 end 
 if User.current.allowed_to?(:browse_repository, @repository.project) 
tabs = []
tabs << { name: 'revision', label: :label_change_plural,
          url: { :action => 'revision',
                 :id     => @project,
                 :repository_id => @repository.identifier_param,
                 :path   => nil,
                 :rev    => @changeset.identifier}
        }
tabs << { name: 'diff', label: :label_view_diff,
          url: { :action => 'diff',
                 :id     => @project,
                 :repository_id => @repository.identifier_param,
                 :path   => "",
                 :rev    => @changeset.identifier }
        } if action_name == 'diff' || @changeset.filechanges.any?
 render :partial => 'common/tabs', :locals => {:tabs => tabs, :selected_tab => action_name} 
 tabs.each do |tab| 
 link_to l(tab[:label]), (tab[:url] || { :tab => tab[:name] }),
                                    :id => "tab-#{tab[:name]}",
                                    :class => (tab[:name] != selected_tab ? nil : 'selected'),
                                    :onclick => tab[:partial] ? "showTab('#{tab[:name]}', this.href); this.blur(); return false;" : nil 
 end 
 tabs.each do |tab| 
 content_tag('div', render(:partial => tab[:partial], :locals => {:tab => tab} ),
                       :id => "tab-content-#{tab[:name]}",
                       :style => (tab[:name] != selected_tab ? 'display:none' : nil),
                       :class => 'tab-content') if tab[:partial] 
 end 
 end 
 if User.current.allowed_to?(:browse_repository, @project) 
 l(:label_added)    
 l(:label_modified) 
 l(:label_copied)   
 l(:label_renamed)  
 l(:label_deleted)  
 render_changeset_changes 
 end 
 content_for :header_tags do 
 stylesheet_link_tag "scm" 
 end 
  title = "#{l(:label_revision)} #{format_revision(@changeset)}"
  title << " - #{@changeset.comments.truncate(80)}"
  html_title(title)
  def add_related_issue
    issue_id = params[:issue_id].to_s.sub(/^#/,'')
    @issue = @changeset.find_referenced_issue_by_id(issue_id)
    if @issue && (!@issue.visible? || @changeset.issues.include?(@issue))
      @issue = nil
    end
    if @issue
      @changeset.issues << @issue
    end
  end
  def remove_related_issue
    @issue = Issue.visible.find_by_id(params[:issue_id])
    if @issue
      @changeset.issues.delete(@issue)
    end
  end
  def diff
    if params[:format] == 'diff'
      @diff = @repository.diff(@path, @rev, @rev_to)
      (show_error_not_found; return) unless @diff
      filename = "changeset_r#{@rev}"
      filename << "_r#{@rev_to}" if @rev_to
      send_data @diff.join, :filename => "#{filename}.diff",
                            :type => 'text/x-patch',
                            :disposition => 'attachment'
    else
      @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
      @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
      if User.current.logged? && @diff_type != User.current.pref[:diff_type]
        User.current.pref[:diff_type] = @diff_type
        User.current.preference.save
      end
      @cache_key = "repositories/diff/#{@repository.id}/" +
                      Digest::MD5.hexdigest("#{@path}-#{@rev}-#{@rev_to}-#{@diff_type}-#{current_language}")
      unless read_fragment(@cache_key)
        @diff = @repository.diff(@path, @rev, @rev_to)
        show_error_not_found unless @diff
      end
      @changeset = @repository.find_changeset_by_name(@rev)
      @changeset_to = @rev_to ? @repository.find_changeset_by_name(@rev_to) : nil
      @diff_format_revisions = @repository.diff_format_revisions(@changeset, @changeset_to)
    end
  end
 if @changeset && @changeset_to.nil? 
 render :partial => 'changeset' 
 l(:label_revision) 
 format_revision(@changeset) 
 avatar(@changeset.user, :size => "24") 
 authoring(@changeset.committed_on, @changeset.author) 
 if @changeset.scmid.present? || @changeset.parents.present? || @changeset.children.present? 
 if @changeset.scmid.present? 
 @changeset.scmid 
 end 
 if @changeset.parents.present? 
 l(:label_parent_revision) 
 @changeset.parents.collect{
                |p| link_to_revision(p, @repository, :text => format_revision(p))
              }.join(", ").html_safe 
 end 
 if @changeset.children.present? 
 l(:label_child_revision) 
 @changeset.children.collect{
                |p| link_to_revision(p, @repository, :text => format_revision(p))
               }.join(", ").html_safe 
 end 
 end 
 format_changeset_comments @changeset 
 if @changeset.issues.visible.any? || User.current.allowed_to?(:manage_related_issues, @repository.project) 
 render :partial => 'related_issues' 
 end 
 if User.current.allowed_to?(:browse_repository, @repository.project) 
tabs = []
tabs << { name: 'revision', label: :label_change_plural,
          url: { :action => 'revision',
                 :id     => @project,
                 :repository_id => @repository.identifier_param,
                 :path   => nil,
                 :rev    => @changeset.identifier}
        }
tabs << { name: 'diff', label: :label_view_diff,
          url: { :action => 'diff',
                 :id     => @project,
                 :repository_id => @repository.identifier_param,
                 :path   => "",
                 :rev    => @changeset.identifier }
        } if action_name == 'diff' || @changeset.filechanges.any?
 render :partial => 'common/tabs', :locals => {:tabs => tabs, :selected_tab => action_name} 
 tabs.each do |tab| 
 link_to l(tab[:label]), (tab[:url] || { :tab => tab[:name] }),
                                    :id => "tab-#{tab[:name]}",
                                    :class => (tab[:name] != selected_tab ? nil : 'selected'),
                                    :onclick => tab[:partial] ? "showTab('#{tab[:name]}', this.href); this.blur(); return false;" : nil 
 end 
 tabs.each do |tab| 
 content_tag('div', render(:partial => tab[:partial], :locals => {:tab => tab} ),
                       :id => "tab-content-#{tab[:name]}",
                       :style => (tab[:name] != selected_tab ? 'display:none' : nil),
                       :class => 'tab-content') if tab[:partial] 
 end 
 end 
 else 
 l(:label_revision) 
 @diff_format_revisions 
 @path 
 end 
 form_tag({:action => 'diff', :id => @project,
              :repository_id => @repository.identifier_param,
              :path => to_path_param(@path), :rev=> @rev}, :method => 'get') do 
 hidden_field_tag('rev_to', params[:rev_to]) if params[:rev_to] 
 l(:label_view_diff) 
 radio_button_tag 'type', 'inline', @diff_type != 'sbs', :onchange => "this.form.submit()" 
 l(:label_diff_inline) 
 radio_button_tag 'type', 'sbs', @diff_type == 'sbs', :onchange => "this.form.submit()" 
 l(:label_diff_side_by_side) 
 end 
 cache(@cache_key) do 
 render :partial => 'common/diff', :locals => {:diff => @diff, :diff_type => @diff_type, :diff_style => @repository.class.scm_name} 
 diff = Redmine::UnifiedDiff.new(
            diff, :type => diff_type,
            :max_lines => Setting.diff_max_lines_displayed.to_i,
            :style => diff_style) 
 diff.each do |table_file| 
 if diff.diff_type == 'sbs' 
 table_file.file_name 
 table_file.each_line do |spacing, line| 
 if spacing 
 end 
 line.nb_line_left 
 line.type_diff_left 
 line.html_line_left.html_safe 
 line.nb_line_right 
 line.type_diff_right 
 line.html_line_right.html_safe 
 end 
 else 
 table_file.file_name 
 table_file.each_line do |spacing, line| 
 if spacing 
 end 
 line.nb_line_left 
 line.nb_line_right 
 line.type_diff 
 line.html_line.html_safe 
 end 
 end 
 end 
 l(:text_diff_truncated) if diff.truncated? 
 end 
 other_formats_links do |f| 
 f.link_to_with_query_parameters 'Diff', {}, :caption => 'Unified diff' 
 end 
 html_title(with_leading_slash(@path), 'Diff') 
 content_for :header_tags do 
 stylesheet_link_tag "scm" 
 end 
  def stats
  end
 l(:label_statistics) 
 javascript_tag do 
 raw url_for(:controller => 'repositories',
    :action => 'graph', :id => @project,
    :repository_id => @repository.identifier_param,
    :graph => "commits_per_month").to_json 
 raw l(:label_revision_plural).to_json 
 raw l(:label_change_plural).to_json 
 raw l(:label_commits_per_month).to_json 
 raw url_for(:controller => 'repositories',
    :action => 'graph', :id => @project,
    :repository_id => @repository.identifier_param,
    :graph => "commits_per_author").to_json 
 raw l(:label_revision_plural).to_json 
 raw l(:label_change_plural).to_json 
 raw l(:label_commits_per_author).to_json 
 end 
 link_to l(:button_back), :action => 'show', :id => @project 
 html_title(l(:label_repository), l(:label_statistics)) 
 content_for :header_tags do 
 javascript_include_tag "Chart.bundle.min" 
 end 
  def graph
    data = nil
    case params[:graph]
    when "commits_per_month"
      data = graph_commits_per_month(@repository)
    when "commits_per_author"
      data = graph_commits_per_author(@repository)
    end
    if data
      render :json => data
    else
      render_404
    end
  end
  private
  def build_new_repository_from_params
    scm = params[:repository_scm] || (Redmine::Scm::Base.all & Setting.enabled_scm).first
    unless @repository = Repository.factory(scm)
      render_404
      return
    end
    @repository.project = @project
    @repository.safe_attributes = params[:repository]
    @repository
  end
  def find_repository
    @repository = Repository.find(params[:id])
    @project = @repository.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  REV_PARAM_RE = %r{\A[a-f0-9]*\Z}i
  def find_project_repository
    @project = Project.find(params[:id])
    if params[:repository_id].present?
      @repository = @project.repositories.find_by_identifier_param(params[:repository_id])
    else
      @repository = @project.repository
    end
    (render_404; return false) unless @repository
    @path = params[:path].is_a?(Array) ? params[:path].join('/') : params[:path].to_s
    @rev = params[:rev].blank? ? @repository.default_branch : params[:rev].to_s.strip
    @rev_to = params[:rev_to]
    unless @rev.to_s.match(REV_PARAM_RE) && @rev_to.to_s.match(REV_PARAM_RE)
      if @repository.branches.blank?
        raise InvalidRevisionParam
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue InvalidRevisionParam
    show_error_not_found
  end
  def find_changeset
    if @rev.present?
      @changeset = @repository.find_changeset_by_name(@rev)
    end
    show_error_not_found unless @changeset
  end
  def show_error_not_found
    render_error :message => l(:error_scm_not_found), :status => 404
  end
  def show_error_command_failed(exception)
    render_error l(:error_scm_command_failed, exception.message)
  end
  def graph_commits_per_month(repository)
    date_to = User.current.today
    date_from = date_to << 11
    date_from = Date.civil(date_from.year, date_from.month, 1)
    commits_by_day = Changeset.
      where("repository_id = ? AND commit_date BETWEEN ? AND ?", repository.id, date_from, date_to).
      group(:commit_date).
      count
    commits_by_month = [0] * 12
    commits_by_day.each {|c| commits_by_month[(date_to.month - c.first.to_date.month) % 12] += c.last }
    changes_by_day = Change.
      joins(:changeset).
      where("#{Changeset.table_name}.repository_id = ? AND #{Changeset.table_name}.commit_date BETWEEN ? AND ?", repository.id, date_from, date_to).
      group(:commit_date).
      count
    changes_by_month = [0] * 12
    changes_by_day.each {|c| changes_by_month[(date_to.month - c.first.to_date.month) % 12] += c.last }
    fields = []
    today = User.current.today
    12.times {|m| fields << month_name(((today.month - 1 - m) % 12) + 1)}
    data = {
      :labels => fields.reverse,
      :commits => commits_by_month[0..11].reverse,
      :changes => changes_by_month[0..11].reverse
    }
  end
  def graph_commits_per_author(repository)
    stats = repository.stats_by_author
    fields, commits_data, changes_data = [], [], []
    stats.each do |name, hsh|
      fields << name
      commits_data << hsh[:commits_count]
      changes_data << hsh[:changes_count]
    end
    fields = fields + [""]*(10 - fields.length) if fields.length<10
    commits_data = commits_data + [0]*(10 - commits_data.length) if commits_data.length<10
    changes_data = changes_data + [0]*(10 - changes_data.length) if changes_data.length<10
    fields = fields.collect {|c| c.gsub(%r{<.+@.+>}, '') }
    data = {
      :labels => fields.reverse,
      :commits => commits_data.reverse,
      :changes => changes_data.reverse
    }
  end
  def disposition(path)
    if Redmine::MimeType.of(@path) == "application/pdf"
      'inline'
    else
      'attachment'
    end
  end
end
