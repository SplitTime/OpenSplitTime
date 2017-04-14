FactoryGirl.define do
  factory :prepared_params, class: PreparedParams do
    skip_create

    transient do
      params_hash = {data: {id: 1, attributes: {name: 'Joe'}},
                     sort: 'name,-age',
                     fields: {effort: 'name,age,stateCode'},
                     filter: {state_code: 'NM,NY,BC', gender: 'female', search: 'jane'},
                     include: 'efforts,efforts.splitTimes'}
      params ActionController::Parameters.new(params_hash)
      permitted [:id, :name, :age, :state_code, :gender]
      permitted_query [:id, :name, :age, :state_code, :gender]
    end

    initialize_with { new(params, permitted, permitted_query) }
  end
end
