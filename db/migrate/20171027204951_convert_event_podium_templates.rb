class ConvertEventPodiumTemplates < ActiveRecord::Migration[5.1]
  def up
    Event.where.not(podium_template: nil).each do |event|
      event.update(podium_template: event.podium_template.parameterize.underscore)
    end
  end

  def down
    Event.where.not(podium_template: nil).each do |event|
      event.update(podium_template: event.podium_template.humanize.titleize)
    end
  end
end
