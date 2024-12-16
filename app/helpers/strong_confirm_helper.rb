# frozen_string_literal: true

module StrongConfirmHelper
  def link_to_strong_confirm(name, path_on_confirm, options)
    params = {
      on_confirm: path_on_confirm,
      message: options[:message],
      required_pattern: options[:required_pattern],
    }

    link_to name, strong_confirm_path(params),
            class: options[:class],
            data: { turbo_frame: "form_modal" }.merge(options[:data] || {})
  end

  def link_to_delete_resource(name, path_on_confirm, options)
    resource = options.delete(:resource)
    noteworthy_associations = options.delete(:noteworthy_associations) || []
    additional_warning = options.delete(:additional_warning)
    list_items = to_sentence(noteworthy_associations.map { |e| e.to_s.humanize.downcase } + ["other related information"])
    message = "This will permanently delete the #{resource.name&.upcase} #{resource.class.model_name.human.downcase} with all of its #{list_items}."
    message += "\n#{additional_warning}" if additional_warning.present?

    link_to_strong_confirm name, path_on_confirm,
                           options.merge(message: message, required_pattern: resource.name&.upcase)
  end
end
