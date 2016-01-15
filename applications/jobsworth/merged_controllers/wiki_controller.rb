# encoding: UTF-8
class WikiController < ApplicationController

  def show
    name = params[:id] || t('wiki.frontpage')

    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, name).first
    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = name
      @page.project_id = nil
      ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 @page_title = t("wiki.title", title: "#{@page.name} - #{Setting.productName}") 
 @page.name 
 t("wiki.linking_to_pages") 
 t("wiki.link_helper") 
 form_tag :action => 'create', :id => @page.name do 
 if @page.revisions.empty? 
 t("wiki.no_page_yet") 
 else 
 @page.to_plain_html(params[:rev].to_i) 
 end 
 t("wiki.edit_summary") 
 submit_tag t("button.save"), :class => 'btn'  
 unless @page.revisions.empty?
 end 
 end 

end

    end

  end

  def create
    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, params[:id]).first

    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = params[:id]
      @page.project_id = nil
      @page.save
    end

    @rev = WikiRevision.new
    @rev.wiki_page = @page
    @rev.user = current_user
    @rev.body = params[:body]
    @rev.change = params[:change]
    @rev.save

    @page.reload
    @page.unlock

    # Create event log
    l = @page.event_logs.new
    l.company_id = @page.company_id
    l.project_id = @page.project_id
    l.user_id = current_user.id
    l.event_type = @page.revisions.size < 2 ? EventLog::WIKI_CREATED : EventLog::WIKI_MODIFIED
    l.created_at = @rev.created_at
    l.body = params[:change]
    l.save

    redirect_to :action => 'show', :id => @page.name
  end

  def edit
    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, params[:id]).first
    if @page.nil?
      @page = WikiPage.new
      @page.company_id = current_user.company_id
      @page.name = params[:id]
      @page.project_id = nil
    end

    unless @page.new_record?
      @page.lock(Time.now.utc, current_user.id)
    end
 @page_title = t("wiki.title", title: "#{@page.name} - #{Setting.productName}") 
 @page.name 
 t("wiki.linking_to_pages") 
 t("wiki.link_helper") 
 form_tag :action => 'create', :id => @page.name do 
 if @page.revisions.empty? 
 t("wiki.no_page_yet") 
 else 
 @page.to_plain_html(params[:rev].to_i) 
 end 
 t("wiki.edit_summary") 
 submit_tag t("button.save"), :class => 'btn'  
 unless @page.revisions.empty?
 end 
 end 

  end

  def cancel
    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, params[:id]).first
    if @page
      @page.unlock
    end

    redirect_to :action => 'show', :id => params[:id]

  end

  def cancel_create
    redirect_from_last
  end

  def versions
    @page = WikiPage.where("company_id = ? AND name = ?", current_user.company_id, params[:id]).first
 @page_title = t("wiki.revisions_title", title: "#{@page.name} - #{Setting.productName}")  
 t("wiki.revisions") 
 @page.name 
 if @page.revisions.empty? 
 t("wiki.no_page_yet") 
 form_tag :action => 'create', :id => @page.name do 
 t("button.create") 
 t("button.or")
 link_to t("button.cancel"), :controller => "wiki", :action => "cancel_create", :id => @page.name 
 end 
 else 

  rev_num = @page.revisions.size
  @page.revisions.reverse.each do |revision|

 link_to( t("wiki.revision_n", n: rev_num), :controller => "wiki", :action => "show", :id => @page.name, :rev => rev_num )
 t("shared.time_ago", time: time_ago_in_words(revision.created_at, false)) 
 t("shared.by_html", user: revision.user.name) 
 (" <small> - #{h(revision.change)}</small>").html_safe if revision.change && revision.change.length > 0 

  rev_num = rev_num - 1
  end

 if @page.locked? 
 t("wiki.under_revision_by", user: @page.locked_by.name) 
 tz.utc_to_local(@page.locked_at).strftime(current_user.time_format) 
 end 
 end 

  end

end
