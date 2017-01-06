class RaceShowView

  attr_reader :race, :courses, :events
  delegate :id, :name, :description, :stewards, to: :race

  def initialize(race, params)
    @race = race
    @params = params
    @events = race.events.select_with_params(@params[:search]).to_a
    @courses = Course.used_for_race(race)
  end

  def events_count
    events.size
  end

  def courses_count
    courses.size
  end

  def stewards_count
    stewards.size
  end

  def view_text
    case params[:view]
      when 'courses'
        'courses'
      when 'stewards'
        'stewards'
      else
        'events'
    end
  end

  private

  attr_reader :params

end
