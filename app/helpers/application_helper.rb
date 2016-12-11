module ApplicationHelper
  include TimeFormats

  def base_name(split_id)
    Split.find(split_id).base_name
  end
end