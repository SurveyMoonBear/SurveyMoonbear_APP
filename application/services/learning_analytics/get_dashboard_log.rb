# frozen_string_literal: true

require 'csv'
require 'date'
require 'dry/transaction'
require 'http'
require 'json'
require 'zlib'

module SurveyMoonbear
  module Service
    class GetDashboardLog
      include Dry::Transaction
      include Dry::Monads

      step :fetch_and_process_archives
      step :combine_user_rows_into_csv

      def call(visual_report_title, visual_report_id)
        @visual_report_title = visual_report_title
        @visual_report_id = visual_report_id
        @folder_path = File.join(__dir__, '../../public')
        ensure_directory
        @token = App.config.PAPERTRAIL_TOKEN

        super()
      end

      private

      def ensure_directory
        Dir.mkdir(@folder_path) unless Dir.exist?(@folder_path)
      end

      def fetch_and_process_archives(input)
        url = 'https://papertrailapp.com/api/v1/archives.json'
        response = HTTP.headers({
                                  'Accept' => 'application/json',
                                  'X-Papertrail-Token' => @token
                                }).get(url)

        if response.status.success?
          archives = JSON.parse(response.body.to_s)
          archives.each do |archive|
            process_archive(archive)
          end
          Success(input)
        else
          Failure("Failed to fetch archives: #{response.status} - #{response.body}")
        end
      end

      def process_archive(archive)
        filename = archive['filename']
        date_str = filename[/\d{4}-\d{2}-\d{2}/]
        today_str = Date.today.strftime('%Y-%m-%d')
        seven_days_ago_str = (Date.today - 7).strftime('%Y-%m-%d')

        if date_str >= seven_days_ago_str && date_str < today_str
          puts "Downloading and processing #{filename}"
          download_and_decompress_archive(archive, filename)
        end
      end

      def download_and_decompress_archive(archive, filename)
        download_url = archive['_links']['download']['href']
        archive_path = "#{@folder_path}/#{filename}"

        download_response = HTTP.follow.get(download_url, headers: { 'X-Papertrail-Token' => @token })
        puts "Response status: #{download_response.status.code}"
        if download_response.status.success?
          File.write(archive_path, download_response.body.to_s)
          puts 'File downloaded successfully.'
          decompress_and_process_file(archive_path)
        else
          puts 'Failed to download file. Check the response details above.'
        end
      end

      def decompress_and_process_file(archive_path)
        Zlib::GzipReader.open(archive_path) do |gz|
          tsv_path = archive_path.sub('.gz', '')
          File.open(tsv_path, 'wb') { |output| IO.copy_stream(gz, output) }
          process_tsv_file(tsv_path)
        end
      rescue Zlib::GzipFile::Error => e
        puts "Failed to decompress: #{e.message}"
      ensure
        File.delete(archive_path) if File.exist?(archive_path)
      end

      def process_tsv_file(tsv_path)
        CSV.open("#{tsv_path}_user_rows.csv", 'w', col_sep: "\t") do |csv|
          File.foreach(tsv_path) do |line|
            # csv << [line] if line.include?("user:")
            csv << [line] if line.include?("dashbord_id: #{@visual_report_id}")
          end
        end
      end

      def combine_user_rows_into_csv(_input)
        file_name = "processed_logs_#{@visual_report_title}.csv"
        file_path = "#{@folder_path}/#{file_name}"
        CSV.open(file_path, 'w', col_sep: "\t") do |csv|
          Dir.glob("#{@folder_path}/*_user_rows.csv").each do |file|
            CSV.foreach(file, col_sep: "\t") do |row|
              modify_and_write_row(row, csv)
            end
          end
        end

        if File.exist?(file_path)
          Success("public/#{file_name}")
        else
          Failure('Failed to create the CSV file')
        end
      end

      def modify_and_write_row(row, csv)
        columns = row.first.split(/\s+/)

        columns[1] = "#{columns[1]} #{columns[2]}"
        columns.delete_at(2)

        columns[2] = "#{columns[2]} #{columns[3]}"
        columns.delete_at(3)

        columns[9] = "#{columns[9]} #{columns[10]}"
        columns.delete_at(10)

        columns[10] = "#{columns[10]} #{columns[11]}"
        columns.delete_at(11)

        csv << columns
      end
    end
  end
end
