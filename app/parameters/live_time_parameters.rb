class LiveTimeParameters < BaseParameters

  def self.permitted
    [:id, :event_id, :lap, :split_id, :name_extension, :wave, :bib_number, :absolute_time,
     :stopped_here, :with_pacer, :remarks, :batch, :event_slug, :split_slug]
  end
end
