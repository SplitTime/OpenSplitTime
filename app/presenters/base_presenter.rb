# frozen_string_literal: true

class BasePresenter

  def initialize(args)
    raise NotImplementedError, "#{self.class.name} is an abstract class."
  end

  def existing_sort
    params.original_params[:sort]
  end

  def filter_hash
    params[:filter] || {}
  end

  def gender_text
    case genders
    when [0]
      'male'
    when [1]
      'female'
    else
      'combined'
    end
  end

  def genders
    filter_hash[:gender] || [0, 1]
  end

  def page
    params[:page]
  end

  def per_page
    params[:per_page] || 200
  end

  def request_params_digest
    ::Digest::MD5.base64digest(params.to_json)
  end

  def search_text
    params[:search]
  end

  def sort_hash
    params[:sort]
  end

  def sort_string
    sort_hash.map { |field, direction| "#{(direction == :desc ? '-' : '')}#{field}" }.join(',')
  end

  private

  def params
    raise NotImplementedError, "#{self.class.name} must implement a params method."
  end
end
