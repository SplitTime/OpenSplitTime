class LiveTimeParameters < BaseParameters

  def self.permitted
    [:id, :event_id, :lap, :split_id, :name_extension, :bitkey, :wave, :bib_number, :absolute_time, :military_time,
     :stopped_here, :with_pacer, :remarks, :batch, :source, :event_slug, :split_slug, :split_time_id]
  end
end
