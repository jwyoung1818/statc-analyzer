class CategoriesController < ApplicationController

    skip_before_action :authenticate_user!
    

    def show
      @category = Category.includes(:products).where(products: { status: 1, active: true } ).find(params[:id])
      
      render theme_presenter.page_template_path('categories/show'), format: [:html], layout: theme_presenter.layout_template_path
    end
end