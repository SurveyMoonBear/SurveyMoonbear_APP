module SurveyMoonbear
  module Google
    # Data Mapper object for Google's accounts
    class AccountMapper
      def initialize; end

      def load(data)
        build_entity(data)
      end

      def build_entity(data)
        DataMapper.new(data).build_entity
      end

      # Extracts entity specific elements from data structure
      class DataMapper
        def initialize(data)
          @data = data
        end

        def build_entity
          SurveyMoonbear::Entity::Account.new(
            id: nil,
            email: email,
            username: username,
            access_token: access_token
          )
        end

        def email
          @data[:email]
        end

        def username
          @data[:username]
        end

        def access_token
          @data[:access_token]
        end
      end
    end
  end
end
