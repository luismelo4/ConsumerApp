class ProductsController < ApplicationController
  def index
    page = params[:page] || 1
    per_page = params[:per] || 10
    country = params[:country] # Get country filter from params

    if params[:src] == 'mongo'
      products = if country.present?
                   MongoProduct.where(country: country).page(page).per(per_page)
                 else
                   MongoProduct.page(page).per(per_page)
                 end
    else
      products = if country.present?
                   Product.where(country: country).page(page).per(per_page)
                 else
                   Product.page(page).per(per_page)
                 end
    end

    render json: {
      products: products,
      current_page: products.current_page,
      total_pages: products.total_pages,
      total_count: products.total_count
    }, status: :ok
  end

  def show
    product = Product.find(params[:id])
    render json: product
  end

  def search
    # Would have been good to have a search functionality here
  end

  def upload_file
    uploaded_file = params[:file]

    if uploaded_file.present?
      #Starts the file import job
      FileImportJob.perform_async(uploaded_file.path)
      render json: { message: "File upload started." }, status: :ok
    else
      render json: { error: "No file uploaded." }, status: :unprocessable_entity
    end
  end
end
