# frozen_string_literal: true

module UsersHelper
  def link_to_delete_user(user)
    url = user_path(user, referrer_path: request.params)
    options = {method: :delete,
               data: {confirm: "This cannot be undone. Are you sure you want to delete this record?",
                      controller: :tooltip,
                      bs_placement: :bottom,
                      bs_original_title: "Delete user"},
               id: "delete_user_#{user.id}",
               class: "btn btn-danger"}
    link_to fa_icon("trash"), url, options
  end

  def link_to_become_user(user)
    url = admin_impersonate_start_path(user)
    options = {method: :post,
               data: {controller: :tooltip,
                      bs_placement: :bottom,
                      bs_original_title: "Impersonate user"},
               id: "impersonate_user_#{user.id}",
               class: "btn btn-warning"}
    link_to fa_icon("theater-masks"), url, options
  end
end
