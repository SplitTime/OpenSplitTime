class SplitBuilder

  def initialize(header_map)
    @header_map = header_map
  end

  def splits
    sorted_distances.each_with_index.map do |distance, index|
      Split.new(base_name: determine_base_name(distance_grouped_attributes[distance]),
                distance_from_start: distance,
                sub_split_bitmap: sub_split_bitmap(distance_grouped_attributes[distance]),
                kind: kind(index))
    end
  end

  private

  attr_reader :header_map

  def distance_grouped_attributes
    header_map.group_by { |_, distance| distance }
  end

  def sorted_distances
    distance_grouped_attributes.keys.sort
  end

  def determine_base_name(groups)
    distance = groups.first.last
    proposed_names = group_names(groups).map { |name| base(name) }.uniq
    proposed_names.one? ? proposed_names.first : "Name Conflict #{distance}"
  end

  def sub_split_bitmap(groups)
    sub_split_bitkeys(groups).inject(:|)
  end

  def kind(index)
    case
    when index == 0
      :start
    when index == distance_grouped_attributes.size - 1
      :finish
    else
      :intermediate
    end
  end

  def group_names(groups)
    groups.map(&:first)
  end

  def base(name)
    name.split.reject { |word| all_name_extensions.include?(word.downcase) }.join(' ')
  end

  def extension(name)
    name.gsub(base(name), '').strip
  end

  def sub_split_bitkeys(groups)
    case
    when groups.size == 1
      [SubSplit::IN_BITKEY]
    when groups.size == 2
      [SubSplit::IN_BITKEY, SubSplit::OUT_BITKEY]
    else
      group_names(groups)
          .map { |name| extension(name) }
          .map { |extension| SubSplit.bitkey(extension.titlecase) }
    end

  end

  def all_name_extensions
    SubSplit.kinds.map(&:downcase)
  end

end