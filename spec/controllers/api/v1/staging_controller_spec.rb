require 'rails_helper'

describe Api::V1::StagingController do
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
      subregion_count = us.subregions.size
      get :get_countries
      parsed_response = JSON.parse(response.body)
      us_subregions = parsed_response['countries'].find { |country| country['code'] == 'US' }['subregions']
      expect(us_subregions.size).to eq(subregion_count)
    end
  end

  describe '#post_event_course_org' do
    let(:existing_course) { FactoryGirl.create(:course) }
    let(:existing_course_params) { existing_course.attributes.with_indifferent_access.slice(*Course::PERMITTED_PARAMS) }
    let(:existing_organization) { FactoryGirl.create(:organization) }
    let(:existing_organization_params) { existing_organization.attributes.with_indifferent_access.slice(*Organization::PERMITTED_PARAMS) }

    context 'when an existing staging_id is provided' do
      let(:existing_event) { FactoryGirl.create(:event, course: existing_course, organization: existing_organization) }
      let(:existing_event_params) { existing_event.attributes.with_indifferent_access.slice(*Event::PERMITTED_PARAMS) }
      let(:existing_staging_id) { existing_event.staging_id }

      it 'returns a successful 200 response' do
        staging_id = existing_staging_id
        post :post_event_course_org, staging_id: staging_id,
             event: existing_event_params, course: existing_course_params, organization: existing_organization_params
        expect(response).to be_success
      end

      it 'updates provided attributes for an existing organization' do
        staging_id = existing_staging_id
        organization = existing_organization
        new_params = {name: 'Updated Organization Name', description: 'Updated organization description'}
        updated_params = existing_organization_params.merge(new_params)
        post :post_event_course_org, staging_id: staging_id,
             event: existing_event_params, course: existing_course_params, organization: updated_params
        organization.reload
        expect(organization.name).to eq(new_params[:name])
        expect(organization.description).to eq(new_params[:description])
      end

      it 'updates provided attributes for an existing course' do
        staging_id = existing_staging_id
        course = existing_course
        new_params = {name: 'Updated Course Name', description: 'Updated course description'}
        updated_params = existing_course_params.merge(new_params)
        post :post_event_course_org, staging_id: staging_id,
             event: existing_event_params, course: updated_params, organization: existing_organization_params
        course.reload
        expect(course.name).to eq(new_params[:name])
        expect(course.description).to eq(new_params[:description])
      end

      it 'updates provided attributes for an existing event' do
        staging_id = existing_staging_id
        event = existing_event
        new_params = {name: 'Updated Event Name', start_time: '2020-02-02 02:00:00'}
        updated_params = existing_event_params.merge(new_params)
        post :post_event_course_org, staging_id: staging_id,
             event: updated_params, course: existing_course_params, organization: existing_organization_params
        event.reload
        expect(event.name).to eq(new_params[:name])
        expect(event.start_time).to eq(new_params[:start_time].in_time_zone)
      end
    end

    context 'when a new staging_id is provided' do
      let(:new_staging_id) { SecureRandom.uuid }
      let(:new_event_params) { {name: 'New Event Name', start_time: '2017-03-01 06:00:00', laps_required: 1} }
      let(:new_course_params) { {name: 'New Course Name'} }
      let(:new_organization_params) { {name: 'New Organization Name'} }

      it 'returns a successful 200 response' do
        staging_id = new_staging_id
        post :post_event_course_org, staging_id: staging_id,
             event: new_event_params, course: new_course_params, organization: new_organization_params
        expect(response).to be_success
      end

      it 'creates an event using provided parameters and associates existing course and organization' do
        staging_id = new_staging_id
        post :post_event_course_org, staging_id: staging_id,
             event: new_event_params, course: existing_course_params, organization: existing_organization_params
        event = Event.find_by(staging_id: staging_id)
        expect(event.name).to eq(new_event_params[:name])
        expect(event.start_time).to eq(new_event_params[:start_time].in_time_zone)
      end

      it 'creates an event using provided parameters and associates newly created course and organization' do
        staging_id = new_staging_id
        new_params = {name: 'Updated Event Name', start_time: '2020-02-02 02:00:00', laps_required: 1}
        post :post_event_course_org, staging_id: staging_id,
             event: new_params, course: new_course_params, organization: new_organization_params
        event = Event.find_by(staging_id: staging_id)
        expect(event.name).to eq(new_params[:name])
        expect(event.start_time).to eq(new_params[:start_time].in_time_zone)
      end
    end
  end
end