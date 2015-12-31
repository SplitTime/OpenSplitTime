json.split do
  json.id         @split.id
  json.course     @split.course
  json.name       @split.name
  json.order      @split.order
  json.vert_gain  @split.vert_gain
  json.vert_loss  @split.vert_loss
end
