# frozen_string_literal: true

require "csv"
require "tempfile"

module ImportJobs
  class BuildFromLottery
    RELEVANT_ATTRIBUTES = [
      "first_name",
      "last_name",
      "gender",
      "birthdate",
      "city",
      "state_code",
      "country_code",
    ].freeze
    
    # @param [::Event] event
    # @param [::Lottery] lottery
    # @return [ImportJob]
    def self.perform(event:, lottery:, user_id:)
      new(event: event, lottery: lottery, user_id: user_id).perform
    end

    # @param [::Event] event
    # @param [::Lottery] lottery
    def initialize(event:, lottery:, user_id:)
      @event = event
      @lottery = lottery
      @user_id = user_id
      validate_setup
    end

    # @return [::ImportJob]
    def perform
      import_job = ::ImportJob.new(
        format: :event_efforts_from_lottery,
        parent_type: "Event",
        parent_id: event.id,
        user_id: user_id,
      )

      temp_file = ::Tempfile.create(["lottery_entrants", ".csv"])
      path = temp_file.path

      ::CSV.open(temp_file, "w") do |csv|
        csv << RELEVANT_ATTRIBUTES

        accepted_entrants.each do |entrant|
          csv << RELEVANT_ATTRIBUTES.map { |attr| entrant.send(attr) }
        end
      end

      temp_file.close

      import_job.file.attach(
        io: ::File.open(path),
        filename: path.split("/").last,
        content_type: "text/csv",
      )

      import_job
    end

    private

    attr_reader :event, :lottery, :user_id, :temp_file_name

    # @return [Array<::LotteryEntrant>]
    def accepted_entrants
      @accepted_entrants ||= lottery.divisions.flat_map(&:accepted_entrants)
                                    .sort_by { |entrant| [entrant.last_name, entrant.first_name] }
    end

    def validate_setup
      lottery_org_id = lottery.organization_id
      event_org_id = event.organization.id

      if lottery_org_id != event_org_id
        raise ArgumentError, "Lottery organization id (#{lottery_org_id}) does not match event organization id (#{event_org_id})"
      end
    end
  end
end
