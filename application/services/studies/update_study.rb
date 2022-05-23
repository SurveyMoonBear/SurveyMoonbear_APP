# frozen_string_literal: true

require 'dry/transaction'
require 'http'

module SurveyMoonbear
  module Service
    # Return editted study entity of new title
    # Usage: Service::UpdateStudy.new.call(config: <config>, current_account: {...}, study_id: "...", params: "...")
    class UpdateStudy
      include Dry::Transaction
      include Dry::Monads

      step :get_original_study_and_participants
      step :get_checking_status
      step :check_to_disable_notification
      step :check_to_enable_notification
      step :check_to_disable_activity_tracking
      step :check_to_enable_activity_tracking
      step :update_study_in_db

      private

      # input { ... }
      def get_original_study_and_participants(input)
        input[:study] = Repository::For[Entity::Study].find_id(input[:study_id])
        input[:participants] = Repository::For[Entity::Participant].find_study(input[:study_id])
        Success(input)
      rescue
        Failure('Failed to update study title in database')
      end

      def get_checking_status(input)
        input[:params]['enable_notification'] = !input[:params]['enable_notification'].nil?
        input[:params]['track_activity'] = !input[:params]['track_activity'].nil?
        Success(input)
      rescue
        Failure('Failed to update study title in database')
      end

      # input { ... }
      def check_to_disable_notification(input)
        if !input[:params]['enable_notification'] && input[:params]['enable_notification'] != input[:study].enable_notification
          # notification: delete notification -> delete sessions
          notifications = Repository::For[Entity::Notification].find_study(input[:study_id])
          notifications.map { |noti| DeleteNotification.new.call(config: input[:config], notification_id: noti.id) }

          # participant: update participants noti status
          input[:participants].map { |ptcp| Repository::For[Entity::Participant].update_arn(ptcp.id, '', 'disabled') }

          # study: delete study aws topic & delete confirmed participants aws subscription
          Messaging::NotificationSubscriber.new(input[:config]).delete_topic(input[:study].aws_arn)
          input[:study] = Repository::For[Entity::Study].update_arn(input[:study_id], '')
        end

        Success(input)
      rescue
        Failure('Failed to update study title in database')
      end

      # input { ... }
      def check_to_enable_notification(input)
        if input[:params]['enable_notification'] && input[:params]['enable_notification'] != input[:study].enable_notification
          # study: create a new aws topic
          study_arn = Messaging::NotificationSubscriber.new(input[:config]).create_topic(input[:study_id])
          input[:study] = Repository::For[Entity::Study].update_arn(input[:study_id], study_arn)

          # participant: subscribe aws topic, status -> pending
          input[:participants].map do |ptcp|
            arn = Messaging::NotificationSubscriber.new(input[:config]).subscribe_topic(study_arn, ptcp.contact_type, ptcp.email)
            Repository::For[Entity::Participant].update_arn(ptcp.id, arn, 'pending')
          end
        end

        Success(input)
      rescue
        Failure('Failed to update study title in database')
      end

      # input { ... }
      def check_to_disable_activity_tracking(input)
        if !input[:params]['track_activity'] && input[:params]['track_activity'] != input[:study].track_activity
          # participant: unsubscribe all participants' calendar
          UnsubscribeAllCalendars.new.call(config: input[:config], study_id: input[:study_id],
                                           current_account: input[:current_account])
          # participant: update act_status unsubscribed -> disabled
          input[:participants].map do |ptcp|
            Repository::For[Entity::Participant].update_act_status(ptcp.id, 'disabled')
            # event: delete events
            events = Repository::For[Entity::Event].find_participant(ptcp.id)
            Repository::For[Entity::Event].delete_all(events)
          end
        end
        Success(input)
      rescue
        Failure('Failed to update study title in database')
      end

      # input { ... }
      def check_to_enable_activity_tracking(input)
        if input[:params]['track_activity'] && input[:params]['track_activity'] != input[:study].track_activity
          # participant: update act_status disabled -> unsubscribed
          input[:participants].map { |ptcp| Repository::For[Entity::Participant].update_act_status(ptcp.id, 'unsubscribed') }
        end

        Success(input)
      rescue
        Failure('Failed to update study title in database')
      end

      # input { ... }
      def update_study_in_db(input)
        upd_study = Repository::For[Entity::Study].update(input[:study_id], input[:params])
        Success(upd_study)
      rescue
        Failure('Failed to update study title in database')
      end
    end
  end
end
