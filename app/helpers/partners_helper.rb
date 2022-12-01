# frozen_string_literal: true

module PartnersHelper
  def link_to_event_group_partner_delete(partner)
    url = event_group_partner_path(partner.partnerable, partner)
    tooltip = "Delete partner"
    options = {method: :delete,
               data: {confirm: "This cannot be undone. Continue?",
                      toggle: :tooltip,
                      placement: :bottom,
                      "original-title" => tooltip},
               class: "btn btn-danger has-tooltip"}
    link_to fa_icon("trash"), url, options
  end

  def link_to_event_group_partner_edit(partner)
    url = edit_event_group_partner_path(partner.partnerable, partner)
    tooltip = "Edit partner"
    options = {data: {toggle: :tooltip,
                      placement: :bottom,
                      "original-title" => tooltip},
               class: "btn btn-primary has-tooltip"}
    link_to fa_icon("pencil-alt"), url, options
  end
end
