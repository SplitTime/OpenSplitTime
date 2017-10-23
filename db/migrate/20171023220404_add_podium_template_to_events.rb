class AddPodiumTemplateToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :podium_template, :string
  end
end
