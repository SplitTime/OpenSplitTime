# frozen_string_literal: true

module StrongConfirmHelper
  def link_to_server_strong_confirm(name, path_on_confirm, options)
    link_to name,
            strong_confirm_path(on_confirm: path_on_confirm, message: options[:message], required_pattern: options[:required_pattern]),
            class: options[:class],
            data: { turbo_frame: "form_modal" }
  end

  def link_to_delete_resource(name, path_on_confirm, options)
    resource = options.delete(:resource)
    noteworthy_associations = options.delete(:noteworthy_associations) || []
    additional_warning = options.delete(:additional_warning)
    list_items = to_sentence(noteworthy_associations.map { |e| e.to_s.humanize.downcase } + ["other related information"])
    message = "This will permanently delete the #{resource.name.upcase} #{resource.class.model_name.human.downcase} with all of its #{list_items}."
    message += "\n#{additional_warning}" if additional_warning.present?

    link_with_strong_confirm(name, path_on_confirm, options.merge(message: message,
                                                                  required_pattern: resource.name.upcase,
                                                                  strong_confirm_id: strong_confirm_id_for(resource)))
  end

  def link_for_strong_confirm(name, strong_confirm_id, options)
    render partial: "shared/strong_confirm_link", locals: { name: name,
                                                            strong_confirm_id: strong_confirm_id,
                                                            options: options }
  end

  def link_with_strong_confirm(name, path_on_confirm, options)
    ArgsValidator.validate(params: options, required: [:message, :required_pattern, :strong_confirm_id])
    message = options[:message]
    required_pattern = options[:required_pattern]
    strong_confirm_id = options[:strong_confirm_id]

    render partial: "shared/strong_confirm", locals: { name: name,
                                                       path_on_confirm: path_on_confirm,
                                                       options: options,
                                                       message: message,
                                                       required_pattern: required_pattern,
                                                       strong_confirm_id: strong_confirm_id }
  end

  def strong_confirm_modal(path_on_confirm:, message:, required_pattern:, strong_confirm_id:)
    render partial: "shared/strong_confirm_modal", locals: { path_on_confirm: path_on_confirm,
                                                             message: message,
                                                             required_pattern: required_pattern,
                                                             strong_confirm_id: strong_confirm_id }
  end

  private

  def strong_confirm_id_for(resource)
    "confirm-modal-#{resource.model_name.name.downcase}-#{resource.id}"
  end
end
