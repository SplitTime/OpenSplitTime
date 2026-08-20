class AddUseForProjectionsToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :use_for_projections, :boolean, default: true, null: false
  end
end
