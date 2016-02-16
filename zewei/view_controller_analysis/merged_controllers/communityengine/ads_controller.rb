class AdsController < BaseController
  
  before_action :login_required
  before_action :admin_required  
  
  uses_tiny_mce do
    {:only => [:new, :edit, :create, :update], :options => configatron.default_mce_options}
  end

  # GET /ads
  # GET /ads.xml
  def index
    @search = Ad.search(params[:q])
    @result = @search.result
    @ads = @result.order('created_at DESC').distinct
    @ads = @result.page(params[:page]).per(15)

    respond_to do |format|
      format.html
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = :ads.l 
  widget do 
 :admin.l 
 link_to_unless_current :features.l, homepage_features_path 
 link_to_unless_current :categories.l, categories_path 
 link_to_unless_current :metro_areas.l, metro_areas_path 
 link_to_unless_current :events.l, admin_events_path 
 link_to_unless_current :statistics.l, statistics_path 
 link_to_unless_current :ads.l, ads_path 
 link_to_unless_current :comments.l, admin_comments_path 
 link_to_unless_current :tags.l, admin_tags_path 
 link_to_unless_current :admin_pages.l, admin_pages_path 
 link_to_unless_current :members.l, admin_users_path 
 if @admin_nav_links.any? 
 @admin_nav_links.each do |link| 
 link_to link[:name], link[:url] 
 end 
 end 
 link_to :cache_clear_link.l, admin_clear_cache_path, data: { confirm: :are_you_sure.l } 
 end 
 
 :search.l 
 bootstrap_form_for @search, :url => ads_path, :layout => :horizontal do |f| 
 f.text_field :name_start, :label => :name.l 
 f.text_field :location_cont, :label => :location.l 
 f.form_group :submit_group do 
 f.primary :search.l 
 end 
 end 
 sort_link @search, :name, :name.l 
 sort_link @search, :published, :published.l 
 sort_link @search, :location, :location.l 
 :actions.l 
 for ad in @ads 
 link_to h(ad.name), ad_path(ad) 
 h ad.published? 
 h ad.location 
 link_to :show.l, ad_path(ad), :class => 'btn btn-default' 
 link_to :edit.l, edit_ad_path(ad), :class => 'btn btn-warning' 
 link_to :delete.l, ad_path(ad), data: { confirm: :are_you_sure.l }, :method => :delete, :class => 'btn btn-danger' 
 end 
 paginate @ads, :theme => 'bootstrap' 
 link_to :new_ad.l, new_ad_path, :class => 'btn btn-success' 

end

  end

  # GET /ads/1
  # GET /ads/1.xml
  def show
    @ad = Ad.find(params[:id])

    respond_to do |format|
      format.html 
    end
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title=@ad.name 
 link_to :back.l, ads_path, :class => 'btn btn-default' 
 link_to :edit.l, edit_ad_path(@ad), :class => 'btn btn-warning' 
 link_to :destroy.l, ad_path(@ad), data: { confirm: :are_you_sure.l }, :method => :delete, :class => 'btn btn-danger' 
 :name.l 
 h @ad.name 
 :html.l 
 raw @ad.html 
 :frequency.l 
 h @ad.frequency 
 :published.l 
 @ad.published? 
 :run.l 
 h @ad.time_constrained? ? "#{@ad.start_date.to_formatted_s(:long)} - #{@ad.end_date.to_formatted_s(:long)}" : 'n/a' 
 :location.l 
 h @ad.location 

end

  end

  # GET /ads/new
  def new
    @ad = Ad.new
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title=:new_ad.l 
 link_to :back.l, ads_path, :class => 'btn btn-default' 
  bootstrap_form_for(@ad, :layout => :horizontal) do |f| 
 f.text_field :name 
 f.text_area :html, :class => "rich_text_editor" 
 f.select :frequency, Ad.frequencies_for_select 
 f.select :audience, Ad.audiences_for_select 
 f.form_group :ad_time_constrained do 
 f.check_box :published, :label => :published.l + '?' 
 f.check_box :time_constrained, :label => :time_constrained.l + '?' 
 end 
  @ad.time_constrained? ? 'block' : 'none' 
 f.datetime_select :start_date 
 f.datetime_select :end_date 
 content_for :end_javascript do 
 end 
 f.text_field :location 
 f.primary :save.l 
 end 
 

end

  end

  # GET /ads/1;edit
  def edit
    @ad = Ad.find(params[:id])
ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = :editing_ad.l 
 link_to :back.l, ads_path, :class => 'btn btn-default' 
 link_to :show.l, ad_path(@ad), :class => 'btn btn-primary' 
 link_to :destroy.l, ad_path(@ad), data: { confirm: :are_you_sure.l }, :method => :delete, :class => 'btn btn-danger' 
  bootstrap_form_for(@ad, :layout => :horizontal) do |f| 
 f.text_field :name 
 f.text_area :html, :class => "rich_text_editor" 
 f.select :frequency, Ad.frequencies_for_select 
 f.select :audience, Ad.audiences_for_select 
 f.form_group :ad_time_constrained do 
 f.check_box :published, :label => :published.l + '?' 
 f.check_box :time_constrained, :label => :time_constrained.l + '?' 
 end 
  @ad.time_constrained? ? 'block' : 'none' 
 f.datetime_select :start_date 
 f.datetime_select :end_date 
 content_for :end_javascript do 
 end 
 f.text_field :location 
 f.primary :save.l 
 end 
 

end

  end

  # POST /ads
  # POST /ads.xml
  def create
    @ad = Ad.new(ad_params)

    respond_to do |format|
      if @ad.save
        flash[:notice] = :ad_was_successfully_created.l
        format.html { redirect_to ad_url(@ad) }
      else
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title=:new_ad.l 
 link_to :back.l, ads_path, :class => 'btn btn-default' 
  bootstrap_form_for(@ad, :layout => :horizontal) do |f| 
 f.text_field :name 
 f.text_area :html, :class => "rich_text_editor" 
 f.select :frequency, Ad.frequencies_for_select 
 f.select :audience, Ad.audiences_for_select 
 f.form_group :ad_time_constrained do 
 f.check_box :published, :label => :published.l + '?' 
 f.check_box :time_constrained, :label => :time_constrained.l + '?' 
 end 
  @ad.time_constrained? ? 'block' : 'none' 
 f.datetime_select :start_date 
 f.datetime_select :end_date 
 content_for :end_javascript do 
 end 
 f.text_field :location 
 f.primary :save.l 
 end 
 

end
 }
      end
    end
  end

  # PUT /ads/1
  # PUT /ads/1.xml
  def update
    @ad = Ad.find(params[:id])

    respond_to do |format|
      if @ad.update_attributes(ad_params)
        flash[:notice] = :ad_was_successfully_updated.l
        format.html { redirect_to ad_url(@ad) }
      else
        format.html { ruby_code_from_view.ruby_code_from_view do |rb_from_view|
 @page_title = :editing_ad.l 
 link_to :back.l, ads_path, :class => 'btn btn-default' 
 link_to :show.l, ad_path(@ad), :class => 'btn btn-primary' 
 link_to :destroy.l, ad_path(@ad), data: { confirm: :are_you_sure.l }, :method => :delete, :class => 'btn btn-danger' 
  bootstrap_form_for(@ad, :layout => :horizontal) do |f| 
 f.text_field :name 
 f.text_area :html, :class => "rich_text_editor" 
 f.select :frequency, Ad.frequencies_for_select 
 f.select :audience, Ad.audiences_for_select 
 f.form_group :ad_time_constrained do 
 f.check_box :published, :label => :published.l + '?' 
 f.check_box :time_constrained, :label => :time_constrained.l + '?' 
 end 
  @ad.time_constrained? ? 'block' : 'none' 
 f.datetime_select :start_date 
 f.datetime_select :end_date 
 content_for :end_javascript do 
 end 
 f.text_field :location 
 f.primary :save.l 
 end 
 

end
 }
      end
    end
  end

  # DELETE /ads/1
  # DELETE /ads/1.xml
  def destroy
    @ad = Ad.find(params[:id])
    @ad.destroy

    respond_to do |format|
      format.html { redirect_to ads_url }
      format.xml  { head :ok }
    end
  end

  private

  def ad_params
    params[:ad].permit(:html, :name, :frequency, :audience, :published, :time_constrained, :start_date, :end_date, :location)
  end
end
