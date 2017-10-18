module FeatureMacros
  def create_hardrock_event
    course = create(:course)
    splits = create_list(:splits_hardrock_ccw, 16, course: course)
    event = create(:event, course: course)
    event.splits << splits
    efforts = create_list(:effort, 5, event: event)
    create_list(:split_times_hardrock_36, 30, effort: efforts.first)
    create_list(:split_times_hardrock_38, 30, effort: efforts.second)
    create_list(:split_times_hardrock_41, 30, effort: efforts.third)
    create_list(:split_times_hardrock_43, 30, effort: efforts.fourth)
    create_list(:split_times_hardrock_45, 30, effort: efforts.fifth)
  end

  def clean_up_database
    SplitTime.delete_all
    Effort.delete_all
    AidStation.delete_all
    Split.delete_all
    Event.delete_all
    EventGroup.delete_all
    Course.delete_all
    Organization.delete_all
    Subscription.delete_all
    User.delete_all
    Person.delete_all
  end
end
