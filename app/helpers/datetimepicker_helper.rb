# frozen_string_literal: true

module DatetimepickerHelper
  def datepicker_field(form, method, options = {})
    picker_field(form, method, options.merge(date_only: true))
  end

  def datetimepicker_field(form, method, options = {})
    picker_field(form, method, options.merge(date_only: false))
  end

  private

  def picker_field(form, method, options = {})
    html_id_base = options[:date_only] ? 'datepicker' : 'datetimepicker'
    strftime_format = options[:date_only] ? '%m/%d/%Y' : '%m/%d/%Y %H:%M:%S'
    placeholder_format = options[:date_only] ? 'mm/dd/yyyy' : 'mm/dd/yyyy hh:mm:ss'
    html_id = "#{html_id_base}-#{method.to_s.dasherize}"

    text_field = form.text_field method,
                                 value: form.object.send(method)&.strftime(strftime_format),
                                 placeholder: placeholder_format,
                                 class: 'form-control datetimepicker-input',
                                 data: {target: "##{html_id}"}

    append = content_tag(:div, nil, class: 'input-group-append', data: {target: "##{html_id}", toggle: 'datetimepicker'}) do
      content_tag(:span, nil, class: 'input-group-text far fa-calendar-alt')
    end

    content_tag(:div, nil, class: 'input-group date', id: html_id, data: {'target-input' => 'nearest'}) do
      text_field + append
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
