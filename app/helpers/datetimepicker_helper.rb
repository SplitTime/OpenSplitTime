# frozen_string_literal: true

module DatetimepickerHelper
  def datepicker_field(form, method, options = {})
    picker_field(form, method, options.merge(enable_time: false))
  end

  def datetimepicker_field(form, method, options = {})
    picker_field(form, method, options.merge(enable_time: true))
  end

  private

  def picker_field(form, method, options = {})
    strftime_format = options[:enable_time] ? "%m/%d/%Y %H:%M:%S" : "%m/%d/%Y"
    placeholder_format = options[:enable_time] ? "mm/dd/yyyy hh:mm:ss" : "mm/dd/yyyy"
    object = options[:object] || form.object

    text_field = form.text_field method,
                                 value: object.send(method)&.strftime(strftime_format),
                                 placeholder: placeholder_format,
                                 class: "form-control",
                                 data: {
                                   controller: "flatpickr",
                                   flatpickr_enable_time_value: options[:enable_time],
                                 }

    icon = content_tag(:span, nil, class: "input-group-text far fa-calendar-alt")

    content_tag(:div, nil, class: "input-group") do
      text_field + icon
    end
  end
end

module ActionView
  module Helpers
    class FormBuilder
      def datepicker_field(method, options = {})
        @template.datepicker_field(self, method, options)
      end

      def datetimepicker_field(method, options = {})
        @template.datetimepicker_field(self, method, options)
      end
    end
  end
end
