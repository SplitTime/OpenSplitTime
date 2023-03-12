module Runsignup
  Event = Struct.new(
    :id,
    :name,
    :start_time,
    :end_time,
    keyword_init: true
  )
end
