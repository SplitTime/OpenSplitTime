class RemoveServiceFormDownloadCountFromLotteries < ActiveRecord::Migration[7.1]
  def change
    remove_column :lotteries, :service_form_download_count, :integer, default: 0
  end
end
