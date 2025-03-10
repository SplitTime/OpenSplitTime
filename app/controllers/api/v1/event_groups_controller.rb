module Api
  module V1
    class EventGroupsController < ::Api::V1::BaseController
      include BackgroundNotifiable
      before_action :set_resource, except: [:index, :create]

      # GET /api/v1/event_groups/1
      def show
        authorize @resource

        event_group = EventGroup.includes(organization: :stewards, events: [:efforts, :splits]).where(id: @resource.id).first
        serialize_and_render(event_group)
      end

      # POST /api/v1/event_groups/1/import
      def import
        authorize @resource

        limited_response = params[:limited_response]&.to_boolean
        importer = ::Etl::ImporterFromContext.build(@resource, params, current_user)
        importer.import
        errors = importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }

        if errors.present?
          render json: { errors: errors }, status: :unprocessable_entity
        else
          ::Etl::EventGroupImportProcess.perform!(@resource, importer)
          if limited_response
            render json: {}, status: :created
          else
            serialize_and_render(importer.saved_records, status: :created)
          end
        end
      end

      # This endpoint searches for raw_times that have not been reviewed belonging to the event_group,
      # selects a batch, marks them as reviewed, combines them into time_rows, and returns them
      # to the live entry page.
      #
      # Batch size is determined by params[:page][:size]; otherwise the default number will be used.
      # If params[:force_pull] == true, raw_times without a matching split_time will be pulled
      # even if they are marked as already having been reviewed.

      # PATCH /api/v1/event_groups/1/pull_raw_times
      def pull_raw_times
        authorize @resource
        event_group = EventGroup.where(id: @resource.id).includes(events: :splits).first

        force_pull = params[:force_pull]&.to_boolean
        default_record_limit = 50
        record_limit = params.dig(:page, :size) || default_record_limit

        scoped_raw_times = force_pull ? event_group.raw_times.unmatched : event_group.raw_times.unreviewed

        # Order should be by absolute time ascending, and where absolute time is nil, then by entered time ascending.
        # This ordering is important to reduce the risk of incorrectly ordered times in multi-lap events.
        raw_times = scoped_raw_times.order(:absolute_time, :entered_time).limit(record_limit)
        enriched_raw_times = raw_times.with_relation_ids

        raw_time_rows = RowifyRawTimes.build(event_group: event_group, raw_times: enriched_raw_times)
        times_container = SegmentTimesContainer.new(calc_model: :stats)
        raw_time_rows.each { |rtr| VerifyRawTimeRow.perform(rtr, times_container: times_container) }

        raw_times.update_all(reviewed_by: current_user.id, reviewed_at: Time.current)
        report_raw_times_available(event_group)

        render json: { data: { rawTimeRows: raw_time_rows.map { |row| row.serialize } } }, status: :ok
      end

      # This endpoint accepts a single raw_time_row and returns an identical raw_time_row
      # with data_status, split_time_exists, lap, and other attributes set

      # POST /api/v1/event_groups/1/enrich_raw_time_row
      def enrich_raw_time_row
        authorize @resource
        event_group = EventGroup.where(id: @resource.id).includes(:events).first

        raw_times_data = params[:data] || ActionController::Parameters.new({})
        if raw_times_data[:raw_time_row]
          parsed_row = parse_raw_times_data(raw_times_data)
          enriched_row = EnrichRawTimeRow.perform(event_group: event_group, raw_time_row: parsed_row)

          render json: { data: { rawTimeRow: enriched_row.serialize } }, status: :ok
        else
          render json: { errors: [{ title: "Request must be in the form of {data: {rawTimeRow: {rawTimes: [{...}]}}}" }] }, status: :unprocessable_entity
        end
      end

      # This endpoint accepts an array of raw_time_rows, verifies them, saves raw_times and saves or updates
      # related split_time data where appropriate, and returns the others.
      #
      # In all instances, raw_times having bad split_name or bib_number data will be returned.
      # When params[:force_submit] is false/nil, all times having bad data status and all duplicate times will be returned.
      # When params[:force_submit] is true, bad and duplicate times will be forced through.

      # POST /api/v1/event_groups/1/submit_raw_time_rows
      def submit_raw_time_rows
        authorize @resource
        event_group = EventGroup.where(id: @resource.id).includes(:events).first

        data = params[:data] || []
        errors = []
        raw_time_rows = []

        data.each do |raw_times_data|
          if raw_times_data[:raw_time_row]
            raw_time_rows << parse_raw_times_data(raw_times_data)
          else
            errors << { title: "Request must be in the form of {data: {0: {rawTimeRow: {...}}, 1: {rawTimeRow: {...}}}}",
                        detail: { attributes: raw_times_data } }
          end
        end

        if errors.empty?
          force_submit = params[:force_submit] || false
          # If params[:force_submit] is a String, convert it to boolean
          force_submit = force_submit.to_boolean if force_submit.respond_to?(:to_boolean)
          response = Interactors::SubmitRawTimeRows.perform!(event_group: event_group, raw_time_rows: raw_time_rows,
                                                             force_submit: force_submit, mark_as_reviewed: true, current_user_id: current_user.id)
          problem_rows = response.resources[:problem_rows]
          report_raw_times_available(event_group)

          render json: { data: { rawTimeRows: problem_rows.map(&:serialize) } }, status: :created
        else
          render json: { errors: errors }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/event_groups/1/not_expected
      def not_expected
        authorize @resource
        event_group = EventGroup.where(id: @resource).includes(events: :splits).first
        response = FindNotExpectedBibs.perform(event_group, params[:split_name])

        if response.errors.present?
          render json: { errors: response.errors }, status: :unprocessable_entity
        else
          render json: { data: { bib_numbers: response.bib_numbers } }, status: :ok
        end
      end

      private

      def parse_raw_times_data(raw_times_data)
        raw_time_row_attributes = raw_times_data.require(:raw_time_row).permit(raw_times: RawTimeParameters.permitted)
        raw_times_attributes = raw_time_row_attributes[:raw_times] || {}
        # Sometimes raw_times_attributes ends up as an Array, other times as a Hash in the form of {0: {...}, 1: {...}}
        # This line ensures that raw_times_attributes is always an Array.
        raw_times_attributes = raw_times_attributes.values if raw_times_attributes.respond_to?(:values)

        raw_times = raw_times_attributes.map do |attributes|
          id = attributes[:id]
          raw_time = @resource.raw_times.find_by(id: id) if id.present?
          raw_time ||= @resource.raw_times.new

          # If data_status contains an invalid attribute, don't fail
          unless attributes[:data_status].nil? || attributes[:data_status].in?(RawTime.data_statuses.keys)
            attributes[:data_status] = nil
          end

          # :id is already assigned if it is valid; :event_group_id is already assigned by
          # @resource.raw_times.find_by or @resource.raw_times.new
          raw_time.assign_attributes(attributes.except(:id, :event_group_id))
          raw_time.run_callbacks(:validation)
          raw_time
        end

        RawTimeRow.new(raw_times)
      end
    end
  end
end
