json.effort do
  json.id              @effort.id
  json.event           @effort.event
  json.participant     @effort.participant
  json.wave            @effort.wave
  json.bib_number      @effort.bib_number
  json.effort_city     @effort.effort_city
  json.effort_state    @effort.effort_state
  json.effort_country  @effort.effort_country
  json.effort_age      @effort.effort_age
  json.start_time      @effort.start_time
  json.finished        @effort.finished
end
