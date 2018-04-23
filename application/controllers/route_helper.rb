# frozen_string_literal: true

module SurveyMoonbear
  class Api < Roda
    # Represent HTTP response for result
    # Parameters:
    #   - result: Result object with #message to represent
    #   - success_representer: representer class if result is success
    #                          #to_json called if result is failure
    #   - (optional) block to execute before success representation
    # Returns: Json representation of success/failure message
    def represent_response(result, success_representer)
      http_response = HttpResponseRepresenter.new(result.value)
      response.status = http_response.http_code
      if result.success?
        yield if block_given?
        success_representer.new(result.value.message).to_json
      else
        http_response.to_json
      end
    end

    # Extracts sub-resource path from request
    # Parameters: HTTP request (Roda request object)
    # Returns: folder path (string)
    def folder_name_from(request)
      path = request.remaining_path
      path.empty? ? '' : path[1..-1]
    end
  end
end