json.splits @splits do |split|
  json.id         split.id
  json.location   split.location
  json.name       split.name
  json.distance   split.distance
  json.order      split.order
  json.vert_gain  split.vert_gain
  json.vert_loss  split.vert_loss
  json.type       split.type
end
