# frozen_string_literal: true

module Api
  module V1
    class EventsController < ::Api::V1::BaseController
      include BackgroundNotifiable
      before_action :set_event, except: [:index, :create]
      before_action :authorize_event, except: [:index, :create]

      # GET /api/v1/events/:id
      def show
        serialize_and_render(@event)
      end

      # POST /api/v1/events
      def create
        event = Event.new(permitted_params)
        authorize event

        if event.save
          event.reload
          serialize_and_render(event, status: :created)
        else
          render_errors(event)
        end
      end

      # PUT /api/v1/events/:id
      def update
        if @event.update(permitted_params)
          serialize_and_render(@event)
        else
          render_errors(@event)
        end
      end

      # DELETE /api/v1/events/:id
      def destroy
        if @event.destroy
          serialize_and_render(@event)
        else
          render_errors(@event)
        end
      end

      # GET /api/v1/events/:id/spread
      def spread
        params[:display_style] ||= 'absolute'
        presenter = EventSpreadDisplay.new(event: @event, params: prepared_params)
        serialize_and_render(presenter, serializer: ::Api::V1::EventSpreadSerializer)
      end

      def import
        importer = ETL::ImporterFromContext.build(@event, params, current_user)
        importer.import
        errors = importer.errors + importer.invalid_records.map { |record| jsonapi_error_object(record) }

        if importer.strict?
          if errors.present?
            render json: {errors: errors}, status: :unprocessable_entity
          else
            ETL::EventImportProcess.perform!(@event, importer)
            render json: importer.saved_records, status: :created
          end
        else
          ETL::EventImportProcess.perform!(@event, importer)
          render json: {saved_records: importer.saved_records.map { |record| ActiveModel::SerializableResource.new(record) },
                        destroyed_records: importer.destroyed_records.map { |record| ActiveModel::SerializableResource.new(record) },
                        errors: errors},
                 status: importer.saved_records.present? ? :created : :unprocessable_entity
        end
      end

      private

      def set_event
        @event = Event.friendly.find(params[:id])
      end

      def authorize_event
        authorize @event
      end
    end
  end
end
