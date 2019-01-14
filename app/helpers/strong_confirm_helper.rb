# frozen_string_literal: true

module StrongConfirmHelper
  def link_with_strong_confirm(name, path_on_confirm, options)
    resource = options.delete(:resource)
    noteworthy_associations = options.delete(:noteworthy_associations) || []

    render partial: 'shared/strong_confirm', locals: {name: name,
                                                      path_on_confirm: path_on_confirm,
                                                      resource: resource,
                                                      noteworthy_associations: noteworthy_associations,
                                                      options: options,
                                                      strong_confirm_id: strong_confirm_id_for(resource)}
  end

  private

  def strong_confirm_id_for(resource)
    "confirm-modal-#{resource.model_name.name.downcase}-#{resource.id}"
  end
end
