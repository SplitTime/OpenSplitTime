# Madmin Configuration
# Resource locations are automatically added by the engine

Madmin.site_name = "OpenSplitTime Admin"

Rails.application.config.to_prepare do
  # Madmin v2's BelongsTo dropdown fetches up to 25 records in raw DB insertion order
  # (https://github.com/excid3/madmin/blob/v2.3.2/lib/madmin/fields/belongs_to.rb).
  # For a table the size of `organizations` that's an unusable, seemingly-random list.
  # Re-open the field so the visible window honors the associated resource's default
  # sort, the same way the index page and the AJAX search endpoint already do.
  Madmin::Fields::BelongsTo.class_eval do
    def options_for_select(record)
      current_value = record.send(attribute_name)
      resource = associated_resource
      scope = resource.model.excluding(current_value)

      if resource.respond_to?(:default_sort_column) && resource.default_sort_column.present?
        direction = resource.try(:default_sort_direction).presence || "asc"
        scope = scope.order(resource.default_sort_column => direction)
      end

      records = [current_value].compact + scope.limit(25)
      records.map { [Madmin.resource_for(it).display_name(it), it.id] }
    end
  end
end
