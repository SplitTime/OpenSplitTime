json.array!(@splits) do |split|
  json.extract! split, :id, :split_id, :split_name, :course_id, :split_order, :vert_gain_from_start, :vert_loss_from_start
  json.url split_url(split, format: :json)
end
