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
  def link_to(name = nil, options = nil, html_options = nil, &)
    effective_html_options = if block_given?
                               options
                             else
                               html_options
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

    super
  end

  def pluralize_with_delimiter(count, singular, plural = nil)
    pluralize(number_with_delimiter(count), singular, plural)
  end

  def docs_url(path = nil)
    base_url = OstConfig.docs_base_url
    URI.join(base_url, path.to_s).to_s
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
