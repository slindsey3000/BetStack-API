# Base controller for API v1
# Provides common functionality for all API controllers
# Includes API key authentication and rate limiting

class Api::V1::BaseController < ApplicationController
  include ApiKeyAuthentication
  include RateLimitable

  private

  # Render JSON collection - returns all results
  def render_collection(collection, serializer_method = :as_json)
    render json: collection.map(&serializer_method)
  end

  # Render single resource
  def render_resource(resource, serializer_method = :as_json)
    render json: resource.send(serializer_method)
  end

  # Handle not found
  def render_not_found(resource_name = "Resource")
    render json: {
      error: "#{resource_name} not found"
    }, status: :not_found
  end
end

