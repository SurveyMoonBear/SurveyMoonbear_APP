# frozen_string_literal: false

require_relative './spec_helper.rb'

describe 'Routes intergration tests' do
  describe 'Root Route' do
    it 'should set google sso url and get root route' do
      get '/'
      _(last_response.body).must_include "/account/login/google_callback"
      _(last_response.status).must_equal 200
    end
  end
end