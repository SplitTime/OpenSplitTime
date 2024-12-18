class AddServiceFormDownloadCountToLotteries < ActiveRecord::Migration[7.0]
  def change
    add_column :lotteries, :service_form_download_count, :integer, default: 0
  end
end
