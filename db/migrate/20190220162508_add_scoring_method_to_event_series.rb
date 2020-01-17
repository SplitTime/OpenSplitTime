class AddScoringMethodToEventSeries < ActiveRecord::Migration[5.2]
  def change
    add_column :event_series, :scoring_method, :integer
  end
end
