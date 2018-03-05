class JournalsController < ApplicationController
  before_action :find_journal, :only => [:edit, :update, :diff]
  before_action :find_issue, :only => [:new]
  before_action :find_optional_project, :only => [:index]
  before_action :authorize, :only => [:new, :edit, :update, :diff]
  accept_rss_auth :index
  menu_item :issues
  helper :issues
  helper :custom_fields
  helper :queries
  include QueriesHelper
  def index
    retrieve_query
    if @query.valid?
      @journals = @query.journals(:order => "#{Journal.table_name}.created_on DESC",
                                  :limit => 25)
    end
    @title = (@project ? @project.name : Setting.app_title) + ": " + (@query.new_record? ? l(:label_changes_details) : @query.name)
    render :layout => false, :content_type => 'application/atom+xml'
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def diff
    @issue = @journal.issue
    if params[:detail_id].present?
      @detail = @journal.details.find_by_id(params[:detail_id])
    else
      @detail = @journal.details.detect {|d| d.property == 'attr' && d.prop_key == 'description'}
    end
    unless @issue && @detail
      render_404
      return false
    end
    if @detail.property == 'cf'
      unless @detail.custom_field && @detail.custom_field.visible_by?(@issue.project, User.current)
        raise ::Unauthorized
      end
    end
    @diff = Redmine::Helpers::Diff.new(@detail.value, @detail.old_value)
  end
 @issue.tracker 
 @issue.id 
 authoring @journal.created_on, @journal.user, :label => :label_updated_time_by 
 simple_format_without_paragraph @diff.to_html 
 link_to(l(:button_back), issue_path(@issue),
              :onclick => 'if (document.referrer != "") {history.back(); return false;}') 
 html_title "#{@issue.tracker.name} ##{@issue.id}: #{@issue.subject}" 
  def new
    @journal = Journal.visible.find(params[:journal_id]) if params[:journal_id]
    if @journal
      user = @journal.user
      text = @journal.notes
    else
      user = @issue.author
      text = @issue.description
    end
    text = text.to_s.strip.gsub(%r{<pre>(.*?)</pre>}m, '[...]')
    @content = "#{ll(Setting.default_language, :text_user_wrote, user)}\n> "
    @content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  def edit
    (render_403; return false) unless @journal.editable_by?(User.current)
    respond_to do |format|
      format.js
    end
  end
  def update
    (render_403; return false) unless @journal.editable_by?(User.current)
    @journal.safe_attributes = params[:journal]
    @journal.save
    @journal.destroy if @journal.details.empty? && @journal.notes.blank?
    call_hook(:controller_journals_edit_post, { :journal => @journal, :params => params})
    respond_to do |format|
      format.html { redirect_to issue_path(@journal.journalized) }
      format.js
    end
  end
  private
  def find_journal
    @journal = Journal.visible.find(params[:id])
    @project = @journal.journalized.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
