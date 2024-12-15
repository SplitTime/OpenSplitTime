class AddLotteryEntrantsServiceFormColumns < ActiveRecord::Migration[7.0]
  def change
    add_column :lottery_entrants, :service_form_status, :integer
    add_column :lottery_entrants, :service_form_accepted_at, :datetime
    add_column :lottery_entrants, :service_form_accepted_comments, :string
    add_column :lottery_entrants, :service_form_rejected_at, :datetime
    add_column :lottery_entrants, :service_form_rejected_comments, :string
  end
end
