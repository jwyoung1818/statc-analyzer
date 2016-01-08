module Cms
  class FormEntriesController < Cms::BaseController

    include ContentRenderingSupport

    helper_method :content_type
    helper Cms::ContentBlockHelper

    allow_guests_to [:submit]

    # Handles public submission of a form.
    def submit
      find_form_and_populate_entry
      if @entry.save
        if @form.show_text?
          show_content_as_page(@form)
          render layout: Cms::Form.layout
        else
          redirect_to @form.confirmation_redirect
        end
        unless @form.notification_email.blank?
          Cms::EmailMessage.create!(
              :recipients => @form.notification_email,
              :subject => "[CMS Form] A new entry has been created",
              :body => "A visitor has filled out the #{@form.name} form. The entry can be found here:
              #{Cms::EmailMessage.absolute_cms_url(cms.form_entry_path(@entry)) }"
          )
        end
      else
        show_content_as_page(@form)
        ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 content_for :main do 
 render file: 'cms/forms/render' 
 end 

end

      end
    end

    def bulk_update
      # Duplicates ContentBlockController#bulk_update
      ids = params[:content_id] || []
      models = ids.collect do |id|
        FormEntry.find(id.to_i)
      end
      
      if params[:commit] == 'Delete'
        deleted = models.select do |m|
          m.destroy
        end
        flash[:notice] = "Deleted #{deleted.size} records."
      end
      
      redirect_to entries_path(params[:form_id])
    end
    
    # Same behavior as ContentBlockController#index
    def index
      @form = Cms::Form.where(id: params[:id]).first
      
      # Allows us to use the content_block/index view
      @content_type = FauxContentType.new(@form)
      @search_filter = SearchFilter.build(params[:search_filter], Cms::FormEntry)
        
      @blocks = Cms::FormEntry.where(form_id: params[:id]).search(@search_filter.term).paginate({page: params[:page], order: params[:order]})
      @entry = Cms::FormEntry.for(@form)

      @total_number_of_items = @blocks.size
     
 content_for :bulk_actions do 
 ruby_code_from_view.ruby_code_from_view do |rb_from_view| 
 link_to("#{@entry.form.name} form", form_path(@entry.form), class: "btn btn-small right ") 
 link_to("New Entry", new_form_entry_path(form_id: @entry.form), class: "btn btn-small btn-primary right") 

end
 
 end 
  render file: 'cms/content_block/index' 

    end

    def edit
      @entry = Cms::FormEntry.find(params[:id])
 use_page_title "Edit Entry" 
 render partial: 'internal_form',
           locals: {model: @entry,
                    url: cms.form_entry_path(@entry)}


    end

    def update
      @entry = Cms::FormEntry.find(params[:id]).enable_validations
      if @entry.update(entry_params(@entry))
        redirect_to form_entry_path(@entry)
      else
        render :edit
      end
    end

    def show
      @entry = Cms::FormEntry.find(params[:id])
 use_page_title "View Entry" 
 render partial: 'buttons', layout: 'page_title' 
 render layout: 'main_with_sidebar' do 
 @entry.form.fields.each do |field| 
 field.label 
 @entry.data_columns[field.name] 
 end 
 end 

    end

    def new
      @entry = Cms::FormEntry.for(Form.find(params[:form_id]))
 use_page_title "New Entry for #{@entry.form.name}" 
 render partial: 'internal_form',
           locals: {model: @entry,
                    url: form_entries_path(@entry)}


    end

    def create
      find_form_and_populate_entry
      if @entry.save
        redirect_to entries_path(@form)
      else
        save_entry_failure
      end
    end

    def save_entry_failure
      render :new
    end

    protected

    def find_form_and_populate_entry
      @form = Cms::Form.find(params[:form_id])
      @entry = Cms::FormEntry.for(@form)
      @entry.attributes = entry_params(@entry)
    end

    def entry_params(entry)
      params.require(:form_entry).permit(entry.permitted_params)
    end

    # Allows Entries to be displayed using same view as Content Blocks.
    class FauxContentType < Cms::ContentType
      def initialize(form)
        @form = form
        self.name = 'Cms::FormEntry'
      end

      def display_name
        'Entry'
      end

      def display_name_plural
        "Entries for #{@form.name} form"
      end
      def columns_for_index
        cols = @form.fields.collect do |field|
          {:label => field.label, :method => field.name}
        end
        cols
      end
    end

    def content_type
      @content_type
    end
    
  end
end