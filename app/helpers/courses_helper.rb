module CoursesHelper
  def link_to_best_efforts_gender(view_object, gender)
    link_to gender.titlecase, best_efforts_course_path(view_object,
                                                 split1: view_object.begin_id,
                                                 split2: view_object.end_id,
                                                 'filter[gender]' => gender,
                                                 'filter[search]' => view_object.search_text),
            disabled: view_object.gender_text == gender,
            class: 'btn btn-sm btn-primary'
  end
end
