# frozen_string_literal: true

class ObjectPairer

  def self.pair(args)
    new(args).pair
  end

  def initialize(args)
    @objects = args[:objects]
    @identical_attributes = Array.wrap(args[:identical_attributes])
    @pairing_criteria = args[:pairing_criteria]
  end

  def pair
    left_right_groups.map { |lr_group| pad_and_zip(lr_group[:left_group], lr_group[:right_group]) }.flatten(1)
  end

  private

  attr_reader :objects, :identical_attributes, :pairing_criteria

  def left_right_groups
    grouped_objects.map do |_, objects|
      result = {left_group: [], right_group: []}
      eligible = {left_group: select_objects(objects, left_criteria).to_set,
                  right_group: select_objects(objects, right_criteria).to_set}
      objects.each do |object|
        groups = [:left_group, :right_group].sort_by { |group| result[group].size }
        if eligible[groups.first].include?(object)
          result[groups.first] << object
        elsif eligible[groups.second].include?(object)
          result[groups.second] << object
        end
      end
      result
    end
  end

  def grouped_objects
    objects.group_by_equality { |object| identical_attributes.map { |attribute| object.send(attribute) } }
  end

  def select_objects(objects, criteria)
    objects.select { |object| criteria.all? { |attribute, value| object.send(attribute) == value } }
  end

  def left_criteria
    pairing_criteria.first
  end

  def right_criteria
    pairing_criteria.last
  end

  def pad_and_zip(left_array, right_array)
    left_shortage = right_array.size - left_array.size
    padded_left_array = (left_shortage > 0) ? (left_array + [nil] * left_shortage) : left_array
    padded_left_array.zip(right_array)
  end

end
