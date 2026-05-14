require "csv"

namespace :maintenance do
  desc "Imports monetary donations from a CSV. Usage: rake 'maintenance:import_monetary_donations[path/to.csv]'"
  task :import_monetary_donations, [:path] => :environment do |_, args|
    path = args[:path]
    abort "Usage: rake 'maintenance:import_monetary_donations[path/to.csv]'" if path.blank?
    abort "File not found: #{path}" unless File.exist?(path)

    expected_headers = ["Organization ID", "Date", "Amount", "Source", "Notes"]
    created = 0
    skipped = 0

    rows = CSV.read(path, headers: true)

    missing = expected_headers - rows.headers
    abort "CSV missing required columns: #{missing.join(', ')}" if missing.any?

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        line = index + 2 # account for header row

        organization_id = row["Organization ID"]&.strip
        received_on = row["Date"]&.strip
        amount = row["Amount"]&.strip
        source = row["Source"].to_s.strip.downcase
        note = row["Notes"]&.strip&.presence

        abort "Line #{line}: missing Organization ID" if organization_id.blank?
        abort "Line #{line}: organization #{organization_id} not found" unless Organization.exists?(id: organization_id)
        abort "Line #{line}: unknown source #{source.inspect}" unless MonetaryDonation.sources.key?(source)

        attrs = {
          organization_id: organization_id.to_i,
          received_on: Date.parse(received_on),
          amount: BigDecimal(amount),
          source: source,
          note: note,
        }

        if MonetaryDonation.exists?(attrs.slice(:organization_id, :received_on, :amount, :source, :note))
          skipped += 1
          next
        end

        MonetaryDonation.create!(attrs)
        created += 1
      end
    end

    puts "Created #{created} donations, skipped #{skipped} duplicates."
  end
end
