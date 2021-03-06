class GanttsController < ApplicationController
  menu_item :gantt
  before_action :find_optional_project
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid
  helper :gantt
  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  include Redmine::Export::PDF
  def show
    @gantt = Redmine::Helpers::Gantt.new(params)
    @gantt.project = @project
    retrieve_query
    @query.group_by = nil
    @gantt.query = @query if @query.valid?
    basename = (@project ? "#{@project.identifier}-" : '') + 'gantt'
    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
 @gantt.view = self 
 if !@query.new_record? && @query.editable_by?(User.current) 
 link_to l(:button_edit), edit_query_path(@query, :gantt => 1), :class => 'icon icon-edit' 
 delete_link query_path(@query, :gantt => 1) 
 end 
 @query.new_record? ? l(:label_gantt) : @query.name 
 form_tag({:controller => 'gantts', :action => 'show',
             :project_id => @project, :month => params[:month],
             :year => params[:year], :months => params[:months]},
             :method => :get, :id => 'query_form') do 
 hidden_field_tag 'set_filter', '1' 
 hidden_field_tag 'gantt', '1' 
 @query.new_record? ? "" : "collapsed" 
 l(:label_filter_plural) 
 @query.new_record? ? "" : "display: none;" 
 render :partial => 'queries/filters', :locals => {:query => @query} 
 l(:label_options) 
 l(:label_related_issues) 
 check_box 'query', 'draw_relations', :id => 'draw_relations' 
 rels = [IssueRelation::TYPE_BLOCKS, IssueRelation::TYPE_PRECEDES] 
 rels.each do |rel| 
 color = Redmine::Helpers::Gantt::DRAW_TYPES[rel][:color] 
 content_tag(:span, '&nbsp;&nbsp;&nbsp;'.html_safe,
                                  :style => "background-color: #{color}") 
 l(IssueRelation::TYPES[rel][:name]) 
 end 
 l(:label_gantt_progress_line) 
 check_box 'query', 'draw_progress_line', :id => 'draw_progress_line' 
 l(:label_display) 
 gantt_zoom_link(@gantt, :in) 
 gantt_zoom_link(@gantt, :out) 
 number_field_tag 'months', @gantt.months, :min => 1, :max => 24, :autocomplete => false 
 l(:label_months_from) 
 select_month(@gantt.month_from, :prefix => "month", :discard_type => true) 
 select_year(@gantt.year_from, :prefix => "year", :discard_type => true) 
 hidden_field_tag 'zoom', @gantt.zoom 
 link_to_function l(:button_apply), '$("#query_form").submit()',
                       :class => 'icon icon-checked' 
 link_to l(:button_clear), { :project_id => @project, :set_filter => 1 },
              :class => 'icon icon-reload' 
 if @query.new_record? && User.current.allowed_to?(:save_queries, @project, :global => true) 
 link_to_function l(:button_save),
                         "$('#query_form').attr('action', '#{ @project ? new_project_query_path(@project) : new_query_path }').submit();",
                         :class => 'icon icon-save' 
 end 
 end 
 error_messages_for 'query' 
 if @query.valid? 
  zoom = 1
  @gantt.zoom.times { zoom = zoom * 2 }
  subject_width = 330
  header_height = 18
  headers_height = header_height
  show_weeks = false
  show_days  = false
  show_day_num = false
  if @gantt.zoom > 1
    show_weeks = true
    headers_height = 2 * header_height
    if @gantt.zoom > 2
        show_days = true
        headers_height = 3 * header_height
        if @gantt.zoom > 3
          show_day_num = true
          headers_height = 4 * header_height
        end
    end
  end
  g_width = ((@gantt.date_to - @gantt.date_from + 1) * zoom).to_i
  @gantt.render(:top => headers_height + 8,
                :zoom => zoom,
                :g_width => g_width,
                :subject_width => subject_width)
  g_height = [(20 * (@gantt.number_of_rows + 6)) + 150, 206].max
  t_height = g_height + headers_height
 if @gantt.truncated 
 l(:notice_gantt_chart_truncated, :max => @gantt.max_rows) 
 end 
 subject_width 
    style  = ""
    style += "position:relative;"
    style += "height: #{t_height + 24}px;"
    style += "width: #{subject_width + 1}px;"
 content_tag(:div, :style => style, :class => "gantt_subjects_container") do 
      style  = ""
      style += "width: #{subject_width}px;"
      style += "height: #{headers_height}px;"
      style += 'background: #eee;'
 content_tag(:div, "", :style => style, :class => "gantt_hdr") 
      style  = ""
      style += "width: #{subject_width}px;"
      style += "height: #{t_height}px;"
      style += 'border-left: 1px solid #c0c0c0;'
      style += 'overflow: hidden;'
 content_tag(:div, "", :style => style, :class => "gantt_hdr") 
 content_tag(:div, :class => "gantt_subjects") do 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 @gantt.subjects.html_safe 
 end 
 end 
 end 
 t_height + 24 
  style  = ""
  style += "width: #{g_width - 1}px;"
  style += "height: #{headers_height}px;"
  style += 'background: #eee;'
 content_tag(:div, '&nbsp;'.html_safe, :style => style, :class => "gantt_hdr") 
  month_f = @gantt.date_from
  left = 0
  height = (show_weeks ? header_height : header_height + g_height)
 @gantt.months.times do 
    width = (((month_f >> 1) - month_f) * zoom - 1).to_i
    style  = ""
    style += "left: #{left}px;"
    style += "width: #{width}px;"
    style += "height: #{height}px;"
 content_tag(:div, :style => style, :class => "gantt_hdr") do 
 link_to "#{month_f.year}-#{month_f.month}",
                @gantt.params.merge(:year => month_f.year, :month => month_f.month),
                :title => "#{month_name(month_f.month)} #{month_f.year}" 
 end 
    left = left + width + 1
    month_f = month_f >> 1
 end 
 if show_weeks 
    left = 0
    height = (show_days ? header_height - 1 : header_height - 1 + g_height)
 if @gantt.date_from.cwday == 1 
      week_f = @gantt.date_from
 else 
      week_f = @gantt.date_from + (7 - @gantt.date_from.cwday + 1)
      width = (7 - @gantt.date_from.cwday + 1) * zoom - 1
      style  = ""
      style += "left: #{left}px;"
      style += "top: 19px;"
      style += "width: #{width}px;"
      style += "height: #{height}px;"
 content_tag(:div, '&nbsp;'.html_safe,
                    :style => style, :class => "gantt_hdr") 
 left = left + width + 1 
 end 
 while week_f <= @gantt.date_to 
      width = ((week_f + 6 <= @gantt.date_to) ?
                  7 * zoom - 1 :
                  (@gantt.date_to - week_f + 1) * zoom - 1).to_i
      style  = ""
      style += "left: #{left}px;"
      style += "top: 19px;"
      style += "width: #{width}px;"
      style += "height: #{height}px;"
 content_tag(:div, :style => style, :class => "gantt_hdr") do 
 content_tag(:small) do 
 week_f.cweek if width >= 16 
 end 
 end 
      left = left + width + 1
      week_f = week_f + 7
 end 
 end 
 if show_day_num 
    left = 0
    height = g_height + header_height*2 - 1
    wday = @gantt.date_from.cwday
    day_num = @gantt.date_from
 (@gantt.date_to - @gantt.date_from + 1).to_i.times do 
      width =  zoom - 1
      style = ""
      style += "left:#{left}px;"
      style += "top:37px;"
      style += "width:#{width}px;"
      style += "height:#{height}px;"
      style += "font-size:0.7em;"
      clss = "gantt_hdr"
      clss << " nwday" if @gantt.non_working_week_days.include?(wday)
 content_tag(:div, :style => style, :class => clss) do 
 day_num.day 
 end 
     left = left + width+1
     day_num = day_num + 1
     wday = wday + 1
     wday = 1 if wday > 7
 end 
 end 
 if show_days 
    left = 0
    height = g_height + header_height - 1
    top = (show_day_num ? 55 : 37)
    wday = @gantt.date_from.cwday
 (@gantt.date_to - @gantt.date_from + 1).to_i.times do 
      width =  zoom - 1
      style  = ""
      style += "left: #{left}px;"
      style += "top: #{top}px;"
      style += "width: #{width}px;"
      style += "height: #{height}px;"
      style += "font-size:0.7em;"
      clss = "gantt_hdr"
      clss << " nwday" if @gantt.non_working_week_days.include?(wday)
 content_tag(:div, :style => style, :class => clss) do 
 day_letter(wday) 
 end 
      left = left + width + 1
      wday = wday + 1
      wday = 1 if wday > 7
 end 
 end 
 form_tag({}, :data => {:cm_url => issues_context_menu_path}) do 
 @gantt.lines.html_safe 
 end 
 if User.current.today >= @gantt.date_from and User.current.today <= @gantt.date_to 
    today_left = (((User.current.today - @gantt.date_from + 1) * zoom).floor() - 1).to_i
    style  = ""
    style += "position: absolute;"
    style += "height: #{g_height}px;"
    style += "top: #{headers_height + 1}px;"
    style += "left: #{today_left}px;"
    style += "width:10px;"
    style += "border-left: 1px dashed red;"
 content_tag(:div, '&nbsp;'.html_safe, :style => style, :id => 'today_line') 
 end 
  style  = ""
  style += "position: absolute;"
  style += "height: #{g_height}px;"
  style += "top: #{headers_height + 1}px;"
  style += "left: 0px;"
  style += "width: #{g_width - 1}px;"
 content_tag(:div, '', :style => style, :id => "gantt_draw_area") 
 link_to("\xc2\xab " + l(:label_previous),
                                 {:params => request.query_parameters.merge(@gantt.params_previous)},
                                 :accesskey => accesskey(:previous)) 
 link_to(l(:label_next) + " \xc2\xbb",
                                 {:params => request.query_parameters.merge(@gantt.params_next)},
                                 :accesskey => accesskey(:next)) 
 other_formats_links do |f| 
 f.link_to_with_query_parameters 'PDF', @gantt.params 
 f.link_to_with_query_parameters('PNG', @gantt.params) if @gantt.respond_to?('to_image') 
 end 
 end # query.valid? 
 content_for :sidebar do 
 render :partial => 'issues/sidebar' 
 end 
 html_title(l(:label_gantt)) 
 content_for :header_tags do 
 javascript_include_tag 'raphael' 
 javascript_include_tag 'gantt' 
 end 
 javascript_tag do 
 raw Redmine::Helpers::Gantt::DRAW_TYPES.to_json 
 end 
 context_menu 
      format.png  { send_data(@gantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @gantt.respond_to?('to_image')
      format.pdf  { send_data(@gantt.to_pdf, :type => 'application/pdf', :filename => "#{basename}.pdf") }
    end
  end
end
