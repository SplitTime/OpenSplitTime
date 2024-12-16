class RemoveServiceAttributesFromLotteryEntrants < ActiveRecord::Migration[7.0]
  def change
    remove_column :lottery_entrants, :service_form_status, :integer
    remove_column :lottery_entrants, :service_form_accepted_at, :datetime
    remove_column :lottery_entrants, :service_form_accepted_comments, :string
    remove_column :lottery_entrants, :service_form_rejected_at, :datetime
    remove_column :lottery_entrants, :service_form_rejected_comments, :string
  end
end
