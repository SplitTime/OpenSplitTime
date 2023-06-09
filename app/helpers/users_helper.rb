# frozen_string_literal: true

module UsersHelper
  def link_to_delete_user(user)
    url = user_path(user, referrer_path: request.params)
    options = { method: :delete,
                data: { turbo_confirm: "This cannot be undone. Are you sure you want to delete this record?",
                        controller: "tooltip",
                        bs_placement: :bottom,
                        bs_original_title: "Delete user" },
                id: "delete_user_#{user.id}",
                class: "btn btn-sm btn-outline-danger" }

    button_to(url, options) { fa_icon("trash") }
  end

  def button_to_impersonate(user)
    url = admin_impersonate_start_path(user)
    options = { method: :post,
                data: { controller: "tooltip",
                        bs_placement: :bottom,
                        bs_original_title: "Impersonate user" },
                id: "impersonate_user_#{user.id}",
                class: "btn btn-sm btn-warning" }

    button_to(url, options) { fa_icon("theater-masks") }
  end

  def button_to_stop_impersonating
    url = admin_impersonate_stop_path
    options = { method: :post,
                data: { controller: "tooltip",
                        turbo: false,
                        bs_placement: :bottom,
                        bs_original_title: "Impersonate user" },
                class: "btn btn-outline-light" }

    button_to(url, options) { "Stop impersonating" }
  end
end
