# frozen_string_literal: true

# Small helper around the Operaton REST API for the examples: deploying BPMN
# models and starting process instances. The external task client itself does
# not (and should not) do deployments — the Java examples use the REST API or
# a pre-deployed process for this, too.

require "net/http"
require "json"
require "uri"

module Examples
  class EngineRest
    attr_reader :base_url

    def initialize(base_url = ENV.fetch("OPERATON_BASE_URL", "http://localhost:8080/engine-rest"))
      @base_url = base_url.sub(%r{/+\z}, "")
    end

    def wait_until_ready(timeout: 120)
      deadline = Time.now + timeout
      loop do
        begin
          response = get("/engine")
          return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
        rescue StandardError
          # engine not up yet (connection refused/reset while the container boots)
        end
        raise "Operaton engine at #{base_url} not ready after #{timeout}s" if Time.now > deadline

        print "."
        sleep 2
      end
    end

    def deploy(deployment_name, *bpmn_files)
      boundary = "----OperatonRubyExamples#{Process.pid}"
      parts = []
      parts << form_part(boundary, "deployment-name", deployment_name)
      parts << form_part(boundary, "enable-duplicate-filtering", "true")
      parts << form_part(boundary, "deploy-changed-only", "true")
      bpmn_files.each do |path|
        parts << file_part(boundary, File.basename(path), File.read(path))
      end
      body = "#{parts.join}--#{boundary}--\r\n"

      response = post("/deployment/create", body, "multipart/form-data; boundary=#{boundary}")
      raise "Deployment failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def start_process(process_definition_key, variables: {}, business_key: nil)
      payload = { "variables" => rest_variables(variables) }
      payload["businessKey"] = business_key if business_key

      response = post("/process-definition/key/#{process_definition_key}/start",
                      JSON.generate(payload), "application/json")
      raise "Start failed (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def running_instance_count(process_definition_key)
      response = get("/process-instance/count?processDefinitionKey=#{process_definition_key}")
      JSON.parse(response.body)["count"]
    end

    def history_variables(process_instance_id)
      response = get("/history/variable-instance?processInstanceId=#{process_instance_id}")
      JSON.parse(response.body)
    end

    private

    # Values may be raw Ruby values or pre-built {"value" =>, "type" =>} hashes.
    def rest_variables(variables)
      variables.transform_values do |value|
        next value if value.is_a?(Hash) && value.key?("value")

        case value
        when true, false then { "value" => value, "type" => "Boolean" }
        when Integer then { "value" => value, "type" => value.bit_length < 32 ? "Integer" : "Long" }
        when Float then { "value" => value, "type" => "Double" }
        when nil then { "value" => nil, "type" => "Null" }
        else { "value" => value.to_s, "type" => "String" }
        end
      end
    end

    def form_part(boundary, name, value)
      "--#{boundary}\r\n" \
        "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" \
        "#{value}\r\n"
    end

    def file_part(boundary, filename, content)
      "--#{boundary}\r\n" \
        "Content-Disposition: form-data; name=\"#{filename}\"; filename=\"#{filename}\"\r\n" \
        "Content-Type: application/octet-stream\r\n\r\n" \
        "#{content}\r\n"
    end

    def get(path)
      uri = URI("#{base_url}#{path}")
      Net::HTTP.get_response(uri)
    end

    def post(path, body, content_type)
      uri = URI("#{base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = content_type
      request.body = body
      http.request(request)
    end
  end
end
