class ConvertPodiumTemplates < ActiveRecord::Migration[5.2]
  def up
    add_reference :events, :results_template

    Event.find_each do |event|
      results_template = ResultsTemplate.find_by(temp_key: event.podium_template)
      event.update!(results_template: results_template)
    end
  end

  def down
    remove_reference :events, :results_template
  end
end
