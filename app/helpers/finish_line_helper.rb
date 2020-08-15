module FinishLineHelper
  def effort_button_card_text(effort, time_zone, multiple_events)
    effort_string = bib_effort_name_and_event_name(effort, multiple_events)
    time_string = effort.projected_time.present? ?
                    l(effort.projected_time.in_time_zone(time_zone), format: :day_and_military) :
                    'Time not known'

    "#{effort_string} (#{time_string})"
  end

  def bib_effort_name_and_event_name(effort, multiple_events)
    bib_and_name = "##{effort.bib_number} #{effort.full_name}"
    event_string = multiple_events ? effort.event_short_name : nil
    [bib_and_name, event_string].compact.join(" - ")
  end
end
