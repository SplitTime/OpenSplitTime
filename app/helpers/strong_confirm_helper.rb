# frozen_string_literal: true

module StrongConfirmHelper
  def link_to_delete_resource(name, path_on_confirm, options)
    resource = options.delete(:resource)
    noteworthy_associations = options.delete(:noteworthy_associations) || []
    list_items = to_sentence(noteworthy_associations.map { |e| e.to_s.humanize.downcase } + ['other related information'])
    message = "This will permanently delete the #{resource.name.upcase} #{resource.class.model_name.human.downcase} with all of its #{list_items}."

    link_with_strong_confirm(name, path_on_confirm, options.merge(message: message,
                                                                  required_pattern: resource.name,
                                                                  strong_confirm_id: strong_confirm_id_for(resource)))
  end

  def link_with_strong_confirm(name, path_on_confirm, options)
    ArgsValidator.validate(params: options, required: [:message, :required_pattern, :strong_confirm_id])
    message = options[:message]
    required_pattern = options[:required_pattern]
    strong_confirm_id = options[:strong_confirm_id]

    render partial: 'shared/strong_confirm', locals: {name: name,
                                                      path_on_confirm: path_on_confirm,
                                                      options: options,
                                                      message: message,
                                                      required_pattern: required_pattern,
                                                      strong_confirm_id: strong_confirm_id}
  end

  private

  def strong_confirm_id_for(resource)
    "confirm-modal-#{resource.model_name.name.downcase}-#{resource.id}"
  end
end
