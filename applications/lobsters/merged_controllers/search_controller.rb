class SearchController < ApplicationController
  def index
    @title = "Search"
    @cur_url = "/search"

    @search = Search.new

    if params[:q].to_s.present?
      @search.q = params[:q].to_s

      if params[:what].present?
        @search.what = params[:what]
      end
      if params[:order].present?
        @search.order = params[:order]
      end
      if params[:page].present?
        @search.page = params[:page].to_i
      end

      if @search.valid?
        @search.search_for_user!(@user)
      end
    end

     form_tag "/search", :method => :get do 
 text_field_tag "q", @search.q, { :size => 40 }.
        merge(@search.q.present? ? {} : { :autofocus => "autofocus" }) 
 radio_button_tag "what", "all", @search.what == "all" 
 radio_button_tag "what", "stories", @search.what == "stories" 
 radio_button_tag "what", "comments", @search.what == "comments" 
 radio_button_tag "order", "relevance", @search.order == "relevance" 
 radio_button_tag "order", "newest", @search.order == "newest" 
 radio_button_tag "order", "points", @search.order == "points" 
 end 
 if @search.total_results > -1 
 @search.total_results 
 @search.total_results == 1 ? "" :
        "s" 
 @search.q 
 @search.results.each do |res| 
 if res.class == Story 
 render :partial => "stories/listdetail",
          :locals => { :story => res } 
 elsif res.class == Comment 
 render "comments/comment", :comment => res,
          :show_story => true, :hide_voters => true 
 end 
 end 
 if @search.total_results > @search.per_page 
 page_numbers_for_pagination(@search.page_count, @search.page).each do |p| 
 if p.is_a?(Integer) 
 raw(@search.to_url_params) 
 p
            
 @search.page == p ? "cur" : "" 
 p
            
 else 
 end 
 end 
 end 
 end 

  end
end
