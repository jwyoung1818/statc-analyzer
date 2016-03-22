class NodeInfoController < ApplicationController
  respond_to :json
  respond_to :html, only: :statistics

  def jrd
    render json: NodeInfo.jrd(CGI.unescape(node_info_url("123.123").sub("123.123", "%{version}")))
  end

  def document
    if NodeInfo.supported_version?(params[:version])
      document = NodeInfoPresenter.new(params[:version])
      render json: document, content_type: document.content_type
    else
      head :not_found
    end
  end

  def statistics
    respond_to do |format|
      format.json { render json: StatisticsPresenter.new }
      format.all { @statistics = NodeInfoPresenter.new("1.0") }
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 og_prefix 
 page_title yield(:page_title) 
 image_path('favicon.png') 
  if @post.present? 
 oembed_url(:url => post_url(@post)) 
 og_page_post_tags(@post) 
 else 
 og_general_tags 
 end 
 
 chartbeat_head_block 
 include_mixpanel 
 include_color_theme 
 if rtl? 
 stylesheet_link_tag :rtl, media:  'all' 
 end 
 old_browser_js_support 
 javascript_include_tag :ie 
 jquery_include_tag 
 unless @landing_page 
 javascript_include_tag :main, :templates 
 load_javascript_locales 
 end 
 translation_missing_warnings 
 current_user_atom_tag 
 yield(:head) 
 csrf_meta_tag 
 include_gon(camel_case:  true) 
 controller_name 
 action_name 
 yield :before_content 
 
 t("_statistics") 
  activated 
 name 
 value 
 
  activated 
 name 
 value 
 
  activated 
 name 
 value 
 
 if @statistics.expose_user_counts? 
  activated 
 name 
 value 
 
  activated 
 name 
 value 
 
  activated 
 name 
 value 
 
 end 
 if @statistics.expose_posts_counts? 
  activated 
 name 
 value 
 
 end 
 if @statistics.expose_comment_counts? 
  activated 
 name 
 value 
 
 end 
 t("statistics.services") 
 Configuration::KNOWN_SERVICES.each do |service| 
  activated 
 name 
 value 
 
 end 
 
 yield :after_content 
 include_chartbeat 
 include_mixpanel_guid 
 flash_messages 

end

  end
end