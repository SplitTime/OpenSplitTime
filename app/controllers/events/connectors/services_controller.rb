module Events
  class Connectors::ServicesController < ::Connectors::ServicesController
    # GET /events/1/connector_services/:service_identifier/preview_sync
    def preview_sync
      preview_presenter = ::EventSyncPreviewPresenter.new(@connectable, view_context,
                                                          previewer: event_syncing_interactor)
      render :preview_sync, locals: { event: @connectable, presenter: preview_presenter }
    end

    # POST /events/1/connector_services/:service_identifier/sync
    def sync
      import_job = ImportJob.create!(
        parent: @connectable,
        user: current_user,
        format: service_identifier,
        status: :waiting,
      )
      ::SyncEntrantsJob.perform_later(import_job.id)

      render :sync_entrants, locals: {
        event: @connectable,
        service: @service,
        view_context: view_context,
        import_job: import_job,
      }
    end

    private

    def set_connectable
      @connectable = Event.friendly.find(params[:event_id])
    end

    def event_syncing_interactor
      ::Connectors::Service::SYNCING_INTERACTORS[service_identifier]
    end
  end
end
