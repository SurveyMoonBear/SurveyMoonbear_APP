# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    # Returns a new study, or nil
    # Usage: Service::GetStudyResultDetail.new.call(study_id: {...})
    class GetStudyResultDetail
      include Dry::Transaction
      include Dry::Monads

      step :get_owned_surveys
      step :get_owned_participants

      private

      # input { study_id: }
      def get_owned_surveys(input)
        surveys = Repository::For[Entity::Survey].find_study(input[:study_id])
        input[:waves] = []
        surveys.map do |survey|
          survey.launches.each do |launch|
            next if launch.responses.length.zero?

            arr_responses = []
            launch.responses.each do |res|
              arr_responses.push(res.respondent_id)
            end

            input[:waves].push({ survey_id: survey.id,
                                 survey_title: survey.title,
                                 launch_id: launch.id,
                                 start_at: launch.started_at.strftime('%Y-%m-%d %H:%M'),
                                 res_len: arr_responses.uniq!.length })
          end
        end

        Success(input)
      rescue StandardError => e
        puts e
        Failure('Failed to get survey details from database.')
      end

      # input { study_id:, waves: }
      def get_owned_participants(input)
        participants = Repository::For[Entity::Participant].find_study(input[:study_id])
        input[:participants] = []
        participants.map do |participant|
          input[:participants].push({ participant_id: participant.id,
                                      participant_nickname: participant.nickname })
        end

        Success(input) # input { study_id:, waves:, participants: }
      rescue StandardError => e
        puts e
        Failure('Failed to get participants from database.')
      end
    end
  end
end
