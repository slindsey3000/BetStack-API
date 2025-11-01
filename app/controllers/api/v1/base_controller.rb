# Base controller for API v1
# Provides common functionality for all API controllers

class Api::V1::BaseController < ApplicationController
  # Default pagination settings
  DEFAULT_PER_PAGE = 50
  MAX_PER_PAGE = 200

  private

  # Paginate a collection
  def paginate(collection)
    page = params[:page].to_i
    page = 1 if page < 1
    
    per_page = params[:per_page].to_i
    per_page = DEFAULT_PER_PAGE if per_page < 1
    per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE

    collection.page(page).per(per_page)
  end

  # Build pagination metadata
  def pagination_meta(collection)
    {
      total: collection.total_count,
      page: collection.current_page,
      per_page: collection.limit_value,
      total_pages: collection.total_pages
    }
  end

  # Render JSON with metadata
  def render_collection(collection, serializer_method = :as_json)
    paginated = paginate(collection)
    
    render json: {
      data: paginated.map(&serializer_method),
      meta: pagination_meta(paginated)
    }
  end

  # Render single resource
  def render_resource(resource, serializer_method = :as_json)
    render json: {
      data: resource.send(serializer_method)
    }
  end

  # Handle not found
  def render_not_found(resource_name = "Resource")
    render json: {
      error: "#{resource_name} not found"
    }, status: :not_found
  end
end

