# frozen_string_literal: true

module EffortsHelper

  def data_status_tag(effort_row)
    if effort_row.bad?
      tag('tr', class: "text-danger")
    elsif effort_row.questionable?
      tag('tr', class: "text-warning")
    else
      tag('tr')
    end
  end
end
