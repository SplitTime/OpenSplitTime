class RaceShowView

  attr_reader :race, :courses
  delegate :id, :name, :description, :stewards, :events, to: :race

  def initialize(race, params)
    @race = race
    @events = race.events.select_with_params(params)
    @courses = Course.used_for_race(race)
  end

  def events_count
    events ? events.count : 0
  end

  def courses_count
    courses ? courses.count : 0
  end

  def stewards_count
    stewards ? stewards.count : 0
  end

end