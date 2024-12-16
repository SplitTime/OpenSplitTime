class CreateLotteriesEntrantServiceFormDetails < ActiveRecord::Migration[7.0]
  def change
    create_table :lotteries_entrant_service_details, primary_key: :lottery_entrant_id do |t|
      t.datetime :form_accepted_at
      t.datetime :form_rejected_at
      t.string :form_accepted_comments
      t.string :form_rejected_comments

      t.timestamps
    end
  end
end
