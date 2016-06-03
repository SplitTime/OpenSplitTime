class SplitImporter

  attr_accessor :split_import_report, :split_id_array, :split_failure_array
  attr_reader :import_file, :event, :current_user_id

  def initialize(file, event, current_user_id)
    @import_file = ImportFile.new(file)
    @split_id_array = []
    @split_failure_array = []
    @event = event
    @current_user_id = current_user_id
  end

  def split_import
    return false unless header1.size == header2.size # Split names and distances don't match up
    return false unless effort_offset == 3 # No split data detected
    self.distance_conversion_factor = conversion_factor(header2[1])
    return false unless distance_conversion_factor
    self.running_sub_split_bitkey = 1
    (0...split_title_array.size).each do |i|
      split = create_split(i)
      if split.save
        split_id_array << split.id
        event.splits << split unless event.splits.include?(split)
        self.most_recent_saved_split = split
      else
        split_failure_array << split
      end
      self.running_sub_split_bitkey = (split_distance_array[i] == split_distance_array[i + 1]) ?
          SubSplit.next_bitkey(running_sub_split_bitkey) : 1
    end
  end

  private

  attr_accessor :spreadsheet, :header1, :header2, :distance_conversion_factor, :split_id_array,
                :running_sub_split_bitkey, :most_recent_saved_split

  delegate :spreadsheet, :header1, :header2, :split_offset, :effort_offset, :split_title_array,
           :split_distance_array, :header1_downcase, to: :import_file

  def create_split(i)
    if i == 0 # First one, so find the existing start split or create a new one
      split = event.course.start_split || Split.new(course_id: event.course_id,
                                                    base_name: 'Start',
                                                    distance_from_start: 0,
                                                    sub_split_bitmap: SubSplit::IN_BITKEY, # Start splits have 'in' only
                                                    kind: :start)

    elsif i == split_title_array.size - 1 # Last one, so find the existing finish split or create a new one
      split = event.course.finish_split || Split.new(course_id: event.course_id,
                                                     base_name: 'Finish',
                                                     distance_from_start: (split_distance_array[i] * distance_conversion_factor),
                                                     sub_split_bitmap: SubSplit::IN_BITKEY, # Finish splits have 'in' only
                                                     kind: :finish)

    else # This is not a start or finish, so check running sub_split. If == 1, make a new split.
      # Otherwise update the sub_split_bitmap
      base_name, name_extension = base_name_and_extension(split_title_array[i])
      if running_sub_split_bitkey == SubSplit::IN_BITKEY
        split = Split.new(course_id: event.course_id,
                          base_name: base_name,
                          distance_from_start: (split_distance_array[i] * distance_conversion_factor),
                          sub_split_bitmap: SubSplit::IN_BITKEY,
                          kind: :intermediate)
      else
        split = most_recent_saved_split
        sub_split_bitkey = [SubSplit.bitkey(name_extension), running_sub_split_bitkey].compact.max
        split.sub_split_bitmap = (split.sub_split_bitmap | sub_split_bitkey)
        self.running_sub_split_bitkey = [sub_split_bitkey, running_sub_split_bitkey].max
      end

    end
    split
  end

  def conversion_factor(units)
    units ||= ""
    x = case units.downcase
          when "km"
            1.kilometers.to.meters.value
          when "kilometers"
            1.kilometers.to.meters.value
          when "meters"
            1
          when "miles"
            1.miles.to.meters.value
          when "" # Assume miles if no unit is indicated
            1.miles.to.meters.value
          else
            false
        end
    x ? x.to_f : false
  end

  def base_name_and_extension(split_name)
    base_name = split_name.split.reject { |x| (x.downcase == 'in') | (x.downcase == 'out') }.join(' ')
    name_extension = split_name.gsub(base_name, '').strip
    [base_name, name_extension]
  end

end