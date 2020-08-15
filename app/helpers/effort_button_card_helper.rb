module EffortButtonCardHelper
  def effort_button_card_text(arrival, time_zone, multiple_events)
    bib_and_name = "##{arrival.bib_number} #{arrival.full_name}"
    event_string = multiple_events ? arrival.event_short_name : nil
    effort_string = [bib_and_name, event_string].compact.join(" - ")
    time_string = arrival.projected_time.present? ?
                    l(arrival.projected_time.in_time_zone(time_zone), format: :day_and_military) :
                    'Time not known'

    "#{effort_string} (#{time_string})"
  end
end
