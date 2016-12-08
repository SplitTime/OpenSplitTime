class SplitImporter

  attr_reader :split_id_array, :split_failure_array, :splits

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:file_path, :event, :current_user_id],
                           exclusive: [:file_path, :event, :current_user_id],
                           class: self.class)
    @import_file = ImportFile.new(args[:file_path])
    @event = args[:event]
    @current_user_id = args[:current_user_id]
    @split_id_array = []
    @split_failure_array = []
    @splits = SplitBuilder.new(split_header_map).splits
  end

  def split_import
    return false unless import_file.valid_for_split_import?
    substitute_start_finish_splits
    splits.each do |split|
      split.course_id = event.course_id
      if split.save
        split_id_array << split.id
        event.splits << split unless event.splits.include?(split)
      else
        split_failure_array << split
      end
    end
  end

  private

  attr_reader :import_file, :event, :current_user_id, :split_id_array
  attr_writer :splits

  delegate :split_header_map, to: :import_file

  def substitute_start_finish_splits
    self.splits[0] = event.course.start_split || splits[0]
    self.splits[-1] = event.course.finish_split || splits[-1]
  end

end