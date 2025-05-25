require 'dry/monads'

module SurveyMoonbear
  module Service
    class ListSurveys
      include Dry::Monads::Result::Mixin

      def call(account_id:)
        surveys = Repository::Surveys.find_accessible(account_id)

        Success(surveys || [])
      rescue StandardError => e
        puts "LIST SURVEYS ERROR: #{e.message}"
        Failure('Internal error while listing surveys')
      end
    end
  end
end
