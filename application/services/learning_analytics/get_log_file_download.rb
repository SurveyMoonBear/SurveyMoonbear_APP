# frozen_string_literal: true

require 'dry/transaction'

module SurveyMoonbear
  module Service
    class GetLogFileDownload
      include Dry::Transaction
      include Dry::Monads

      step :validate_file_path
      step :prepare_file_for_download

      def call(file_path, base_directory = 'application/public')
        @file_path = file_path
        @base_directory = base_directory

        super(file_path)
      end

      private

      def validate_file_path(input)
        if input =~ /^[a-zA-Z0-9_-]+\.csv$/
          puts "Valid file path. Full path: #{full_path(input)}"
          Success(input)
        else
          puts "Invalid file request for: #{input}"
          Failure("Invalid file request.")
        end
      end

      def prepare_file_for_download(input)
        full_path = full_path(input)
        if File.exist?(full_path)
          puts 'File ready for download...'
          Success(full_path)
        else
          puts "File not found: #{full_path}"
          Failure("File not found.")
        end
      end

      def full_path(file_name)
        File.join(@base_directory, file_name)
      end
    end
  end
end
