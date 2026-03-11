# frozen_string_literal: true

module Lara
  class AudioTranslator
    ALLOWED_AUDIO_PARAMS = %i[
      id
      status
      target
      filename
      source
      created_at
      updated_at
      options
      translated_seconds
      total_seconds
      error_reason
    ].freeze

    def initialize(client, s3_client = S3Client.new)
      @client = client
      @s3 = s3_client
      @polling_interval = 2
    end

    # Uploads an audio file to S3 and creates a translation job.
    # @return [Lara::Models::Audio]
    def upload(file_path:, filename:, target:, source: nil, adapt_to: nil, glossaries: nil,
               no_trace: false, style: nil, voice_gender: nil)
      response_data = @client.get("/v2/audio/upload-url", params: { filename: filename })
      url = response_data["url"]
      fields = response_data["fields"]

      @s3.upload(url: url, fields: fields, io: file_path)

      body = {
        s3key: fields["key"],
        target: target,
        source: source,
        adapt_to: adapt_to,
        glossaries: glossaries,
        style: style,
        voice_gender: voice_gender
      }.compact

      headers = {}
      headers["X-No-Trace"] = "true" if no_trace

      response = @client.post("/v2/audio/translate", body: body, headers: headers)
      response_params = response.transform_keys(&:to_sym)
      Lara::Models::Audio.new(**filter_audio_params(response_params))
    end

    # Fetch audio translation status.
    # @return [Lara::Models::Audio]
    def status(id)
      response = @client.get("/v2/audio/#{id}")
      response_params = response.transform_keys(&:to_sym)
      Lara::Models::Audio.new(**filter_audio_params(response_params))
    end

    # Download translated audio bytes.
    # @return [String] bytes
    def download(id)
      url = @client.get("/v2/audio/#{id}/download-url")["url"]
      @s3.download(url: url)
    end

    # Translates an audio file end-to-end
    # @return [String] translated audio bytes
    def translate(file_path:, filename:, target:, source: nil, adapt_to: nil, glossaries: nil,
                  no_trace: false, style: nil, voice_gender: nil)
      audio = upload(file_path: file_path, filename: filename, target: target, source: source,
                     adapt_to: adapt_to, glossaries: glossaries, no_trace: no_trace, style: style,
                     voice_gender: voice_gender)

      max_wait_time = 60 * 15 # 15 minutes
      start = Time.now

      loop do |_|
        current = status(audio.id)

        case current.status
        when Lara::Models::AudioStatus::TRANSLATED
          return download(current.id)
        when Lara::Models::AudioStatus::ERROR
          raise Lara::LaraApiError.new(500, "AudioError",
                                       current.error_reason || "Unknown error")
        end

        raise Timeout::Error if Time.now - start > max_wait_time

        sleep @polling_interval
      end
    end

    private

    def filter_audio_params(params)
      params.slice(*ALLOWED_AUDIO_PARAMS)
    end
  end
end
