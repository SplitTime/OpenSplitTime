require "font_awesome6/rails/icon_helper"

module ApplicationHelper
  include TimeFormats
  include MeasurementFormats
  include FontAwesome6::Rails::IconHelper

  def day_time_current_military_full(zone)
    l(Time.current.in_time_zone(zone), format: :full_day_military_and_zone)
  end

  def badgeize_boolean(boolean)
    return if boolean.nil?

    color = boolean ? "success" : "danger"
    text = humanize_boolean(boolean)
    content_tag(:span, text, class: "badge bg-#{color}")
  end

  def humanize_boolean(boolean)
    case boolean
    when false
      "No"
    when true
      "Yes"
    end
  end

  # Monkey patch link_to so we can do disabled: true in bootstrap
  def link_to(name = nil, options = nil, html_options = nil, &block)
    if block_given?
      effective_html_options = options
    else
      effective_html_options = html_options
    end

    effective_html_options ||= {}

    if effective_html_options.delete(:disabled)
      effective_html_options[:class] = Array(effective_html_options[:class]) << "disabled"
      effective_html_options[:href] = "#"
    end

    if block_given?
      options = effective_html_options
    else
      html_options = effective_html_options
    end

    super(name, options, html_options, &block)
  end

  def pluralize_with_delimiter(count, singular, plural = nil)
    pluralize(number_with_delimiter(count), singular, plural)
  end

  # change the default link renderer for will_paginate
  def will_paginate(collection_or_options = nil, options = {})
    if collection_or_options.is_a? Hash
      options = collection_or_options
      collection_or_options = nil
    end
    options = options.merge renderer: WillPaginate::ActionView::Bootstrap4LinkRenderer unless options[:renderer]
    super(*[collection_or_options, options].compact)
  end

  # Devise helpers

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def resource_class
    User
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
