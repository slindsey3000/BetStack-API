# Base controller for API v1
# Provides common functionality for all API controllers

class Api::V1::BaseController < ApplicationController
  # Default pagination settings
  DEFAULT_PER_PAGE = 50
  MAX_PER_PAGE = 200

  private

  # Paginate a collection using simple offset/limit
  def paginate(collection)
    page = params[:page].to_i
    page = 1 if page < 1
    
    per_page = params[:per_page].to_i
    per_page = DEFAULT_PER_PAGE if per_page < 1
    per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE

    offset = (page - 1) * per_page
    
    {
      data: collection.offset(offset).limit(per_page).to_a,
      total: collection.count,
      page: page,
      per_page: per_page
    }
  end

  # Build pagination metadata
  def pagination_meta(page:, per_page:, total:)
    {
      total: total,
      page: page,
      per_page: per_page,
      total_pages: (total.to_f / per_page).ceil
    }
  end

  # Render JSON with metadata
  def render_collection(collection, serializer_method = :as_json)
    result = paginate(collection)
    
    render json: {
      data: result[:data].map(&serializer_method),
      meta: pagination_meta(page: result[:page], per_page: result[:per_page], total: result[:total])
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

