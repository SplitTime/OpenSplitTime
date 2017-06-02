require 'rails_helper'

describe Api::V1::StagingController do
  let(:existing_event) { FactoryGirl.create(:event, course: existing_course, organization: existing_organization) }
  let(:existing_course) { FactoryGirl.create(:course) }
  let(:existing_organization) { FactoryGirl.create(:organization) }
  let(:existing_staging_id) { existing_event.staging_id }
  let(:new_staging_id) { SecureRandom.uuid }

  login_admin

  describe '#get_countries' do
    it 'returns a successful 200 response' do
      get :get_countries
      expect(response).to be_success
    end

    it 'returns a set of country data that includes all Carmen countries' do
      country_count = Carmen::Country.all.size
      get :get_countries
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['countries'].size).to eq(country_count)
    end

    it 'returns subregions for each country that include all Carmen subregions for that country' do
      us = Carmen::Country.coded('US')
      subregion_count = us.subregions.reject { |subregion| subregion.type == 'apo' }.size
      get :get_countries
      parsed_response = JSON.parse(response.body)
      us_subregions = parsed_response['countries'].find { |country| country['code'] == 'US' }['subregions']
      expect(us_subregions.size).to eq(subregion_count)
    end
  end

  describe '#post_event_course_org' do
    let(:existing_course_params) { existing_course.attributes.with_indifferent_access.slice(*CourseParameters.permitted) }
    let(:existing_organization_params) { existing_organization.attributes.with_indifferent_access.slice(*OrganizationParameters.permitted) }

    context 'when an existing staging_id is provided' do
      let(:existing_event_params) { existing_event.attributes.with_indifferent_access.slice(*EventParameters.permitted) }

      it 'returns a successful 200 response' do
        staging_id = existing_staging_id
        params = {event: existing_event_params,
                  course: existing_course_params,
                  organization: existing_organization_params}
        expected_response = 200
        expected_attributes = {}
        post_and_validate_response(staging_id, params, expected_response, expected_attributes)
      end

      it 'updates provided attributes for an existing organization' do
        new_params = {name: 'Updated Organization Name', description: 'Updated organization description'}
        staging_id = existing_staging_id
        params = {event: existing_event_params,
                  course: existing_course_params,
                  organization: existing_organization_params.merge(new_params)}
        expected_response = 200
        expected_attributes = {organization: [:name, :description]}
        post_and_validate_response(staging_id, params, expected_response, expected_attributes)
      end

      it 'updates provided attributes for an existing course' do
        new_params = {name: 'Updated Course Name', description: 'Updated course description'}
        staging_id = existing_staging_id
        params = {event: existing_event_params,
                  course: existing_course_params.merge(new_params),
                  organization: existing_organization_params}
        expected_response = 200
        expected_attributes = {course: [:name, :description]}
        post_and_validate_response(staging_id, params, expected_response, expected_attributes)
      end

      it 'updates provided attributes for an existing event' do
        new_params = {name: 'Updated Event Name', laps_required: 3}
        staging_id = existing_staging_id
        params = {event: existing_event_params,
                  course: existing_course_params.merge(new_params),
                  organization: existing_organization_params}
        expected_response = 200
        expected_attributes = {event: [:name, :laps_required]}
        post_and_validate_response(staging_id, params, expected_response, expected_attributes)
      end
    end

    context 'when a new staging_id is provided' do
      let(:new_event_params) { {name: 'New Event Name', start_time: '2017-03-01 06:00:00', laps_required: 1} }
      let(:new_course_params) { {name: 'New Course Name', description: 'New course description.'} }
      let(:new_organization_params) { {name: 'New Organization Name'} }

      it 'returns a successful 200 response' do
        staging_id = new_staging_id
        params = {event: new_event_params,
                  course: new_course_params,
                  organization: new_organization_params}
        expected_response = 200
        expected_attributes = {}
        post_and_validate_response(staging_id, params, expected_response, expected_attributes)
      end

      it 'creates an event using provided parameters and associates existing course and organization' do
        staging_id = new_staging_id
        params = {event: new_event_params,
                  course: existing_course_params,
                  organization: existing_organization_params}
        expected_response = 200
        expected_attributes = {event: [:name, :laps_required]}
        post_and_validate_response(staging_id, params, expected_response, expected_attributes)
      end

      it 'creates an event using provided parameters and associates newly created course and organization' do
        staging_id = new_staging_id
        params = {event: new_event_params,
                  course: new_course_params,
                  organization: new_organization_params}
        expected_response = 200
        expected_attributes = {event: [:name, :laps_required]}
        post_and_validate_response(staging_id, params, expected_response, expected_attributes)
      end

      it 'returns a bad request message with descriptive errors and provided data if the event cannot be created' do
        staging_id = new_staging_id
        params = {event: new_event_params.except(:start_time),
                  course: new_course_params,
                  organization: new_organization_params}
        expected_response = 422
        expected_errors = [/Start time can't be blank/]
        post_and_validate_errors(staging_id, params, expected_response, expected_errors)
      end

      it 'returns a bad request message with descriptive errors and provided data if the course cannot be created' do
        staging_id = new_staging_id
        params = {event: new_event_params,
                  course: new_course_params.except(:name),
                  organization: new_organization_params}
        expected_response = 422
        expected_errors = [/Name can't be blank/]
        post_and_validate_errors(staging_id, params, expected_response, expected_errors)
      end

      it 'returns a bad request message with descriptive errors and provided data if the organization cannot be created' do
        staging_id = new_staging_id
        params = {event: new_event_params,
                  course: new_course_params,
                  organization: new_organization_params.except(:name)}
        expected_response = 422
        expected_errors = [/Name can't be blank/]
        post_and_validate_errors(staging_id, params, expected_response, expected_errors)
      end

      it 'does not create any resources if the organization cannot be created' do
        staging_id = new_staging_id
        params = {event: new_event_params,
                  course: new_course_params,
                  organization: new_organization_params.except(:name)}
        expected_response = 422
        expected_errors = []
        post_and_validate_errors(staging_id, params, expected_response, expected_errors)
        expect(Event.all.size).to eq(0)
        expect(Course.all.size).to eq(0)
        expect(Organization.all.size).to eq(0)
      end

      it 'does not create any resources if the course cannot be created' do
        staging_id = new_staging_id
        params = {event: new_event_params,
                  course: new_course_params.except(:name),
                  organization: new_organization_params}
        expected_response = 422
        expected_errors = {}
        post_and_validate_errors(staging_id, params, expected_response, expected_errors)
        expect(Event.all.size).to eq(0)
        expect(Course.all.size).to eq(0)
        expect(Organization.all.size).to eq(0)
      end

      it 'does not create any resources if the event cannot be created' do
        staging_id = new_staging_id
        params = {event: new_event_params.except(:start_time),
                  course: new_course_params,
                  organization: new_organization_params}
        expected_response = 422
        expected_errors = {}
        post_and_validate_errors(staging_id, params, expected_response, expected_errors)
        expect(Event.all.size).to eq(0)
        expect(Course.all.size).to eq(0)
        expect(Organization.all.size).to eq(0)
      end
    end

    def post_and_validate_response(staging_id, params, expected_response, expected_attributes)
      post :post_event_course_org, staging_id: staging_id,
           event: params[:event], course: params[:course], organization: params[:organization]

      parsed_response = JSON.parse(response.body)
      resources = {event: Event.find_by(staging_id: staging_id),
                   course: Course.find_by(id: parsed_response['course']['id']),
                   organization: Organization.find_by(id: parsed_response['organization']['id'])}

      expect(response.status).to eq(expected_response)

      expected_attributes.each do |class_name, attributes|
        attributes.each do |attribute|
          expect(resources[class_name].attributes.with_indifferent_access[attribute])
              .to eq(params[class_name][attribute])
        end
      end
    end

    def post_and_validate_errors(staging_id, params, expected_response, expected_errors)
      post :post_event_course_org, staging_id: staging_id,
           event: params[:event], course: params[:course], organization: params[:organization]

      expect(response.status).to eq(expected_response)

      parsed_response = JSON.parse(response.body)
      message_array = parsed_response['errors'].map { |error| error['detail']['messages'] }.flatten

      expected_errors.each do |error_text|
        expect(message_array).to include(error_text)
      end
    end
  end

  describe '#update_event_visibility' do
    context 'when params[:status] == "public"' do
      let(:status) { 'public' }

      it 'returns a successful 200 response' do
        event = existing_event
        patch :update_event_visibility, staging_id: event.staging_id, status: status
        expect(response).to be_success
      end

      it 'sets concealed status of the event and its related organization, efforts, and participants to false' do
        event = existing_event
        organization = existing_organization
        event.update(concealed: true)
        organization.update(concealed: true)
        efforts = FactoryGirl.create_list(:effort, 3, event: event, concealed: true)
        efforts.each { |effort| effort.participant.update(concealed: true) }
        patch :update_event_visibility, staging_id: event.staging_id, status: status
        event.reload
        organization.reload
        expect(event.concealed).to eq(false)
        expect(organization.concealed).to eq(false)
        event.efforts.each do |effort|
          expect(effort.concealed).to eq(false)
          expect(effort.participant.concealed).to eq(false)
        end
      end
    end

    context 'when params[:status] == "private"' do
      let(:status) { 'private' }

      it 'returns a successful 200 response' do
        event = existing_event
        patch :update_event_visibility, staging_id: event.staging_id, status: status
        expect(response).to be_success
      end

      it 'sets concealed status of the event and its related organization, efforts, and participants to true' do
        event = existing_event
        organization = existing_organization
        event.update(concealed: false)
        organization.update(concealed: false)
        efforts = FactoryGirl.create_list(:effort, 3, event: event, concealed: false)
        efforts.each { |effort| effort.participant.update(concealed: false) }
        patch :update_event_visibility, staging_id: event.staging_id, status: status
        event.reload
        organization.reload
        expect(event.concealed).to eq(true)
        expect(organization.concealed).to eq(true)
        event.efforts.each do |effort|
          expect(effort.concealed).to eq(true)
          expect(effort.participant.concealed).to eq(true)
        end
      end

      it 'does not make a participant private if that participant has other public efforts' do
        event = existing_event
        organization = existing_organization
        event.update(concealed: false)
        organization.update(concealed: false)
        efforts = FactoryGirl.create_list(:effort, 3, event: event, concealed: false)
        efforts.each { |effort| effort.participant.update(concealed: false) }
        p_with_other_effort = efforts.first.participant
        FactoryGirl.create(:effort, participant: p_with_other_effort, concealed: false)
        patch :update_event_visibility, staging_id: event.staging_id, status: status
        event.reload
        organization.reload
        expect(event.concealed).to eq(true)
        expect(organization.concealed).to eq(true)
        event.efforts.each do |effort|
          expect(effort.concealed).to eq(true)
          participant = effort.participant
          if participant == p_with_other_effort
            expect(effort.participant.concealed).to eq(false)
          else
            expect(effort.participant.concealed).to eq(true)
          end
        end
      end
    end

    context 'when params[:status] is not "public" or "private"' do
      it 'returns a bad request response' do
        event = existing_event
        patch :update_event_visibility, staging_id: event.staging_id, status: 'random'
        expect(response).to be_bad_request
      end
    end

    context 'when the staging_id does not exist' do
      it 'returns a not found response' do
        patch :update_event_visibility, staging_id: 123, status: 'public'
        expect(response).to be_not_found
      end
    end
  end
end
