# frozen_string_literal: true

module LotteryHelper
  def link_to_division_delete(division)
    url = organization_lottery_lottery_division_path(division.organization, division.lottery, division)
    tooltip = "Delete this division"
    options = {method: :delete,
               data: {confirm: "This will delete the division, together with all related entrants. Are you sure you want to proceed?",
                      turbo: false,
                      toggle: :tooltip,
                      placement: :bottom,
                      "original-title" => tooltip},
               class: "btn btn-danger btn-sm has-tooltip"}
    link_to fa_icon("trash"), url, options
  end

  def link_to_division_edit(division)
    url = edit_organization_lottery_lottery_division_path(division.organization, division.lottery, division)
    tooltip = "Edit this division"
    options = {data: {toggle: :tooltip,
                      placement: :bottom,
                      "original-title" => tooltip},
               class: "btn btn-primary btn-sm has-tooltip"}
    link_to fa_icon("pencil-alt"), url, options
  end
end
