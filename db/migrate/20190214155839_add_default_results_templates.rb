class AddDefaultResultsTemplates < ActiveRecord::Migration[5.2]
  def change
    Event.find_each(&:save)
    change_column_null :events, :results_template_id, false
    remove_column :events, :podium_template, :string, default: :simple
  end
end
