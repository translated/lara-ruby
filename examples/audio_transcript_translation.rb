# frozen_string_literal: true

require "lara"

# Complete audio transcript translation examples for the Lara Ruby SDK
#
# This example demonstrates the async Audio2Text flow, which returns only the
# translated transcript (JSON) instead of a dubbed audio file:
# - Basic transcript translation
# - Advanced options with memories and glossaries
# - Step-by-step transcript translation with status monitoring

def main
  # All examples can use environment variables for credentials:
  # export LARA_ACCESS_KEY_ID="your-access-key-id"
  # export LARA_ACCESS_KEY_SECRET="your-access-key-secret"

  access_key_id = ENV["LARA_ACCESS_KEY_ID"] || "your-access-key-id"
  access_key_secret = ENV["LARA_ACCESS_KEY_SECRET"] || "your-access-key-secret"

  credentials = Lara::Credentials.new(access_key_id, access_key_secret)
  lara = Lara::Translator.new(credentials: credentials)

  # Replace with your actual audio file path
  sample_file_path = "sample_audio.mp3" # Create this file with your content

  unless File.exist?(sample_file_path)
    puts "Please create a sample audio file at: #{sample_file_path}"
    puts "Add some sample audio content to translate.\n"
    return
  end

  source_lang = "en-US"
  target_lang = "de-DE"

  # Example 1: Basic transcript translation
  puts "=== Basic Transcript Translation ==="
  puts "Translating transcript: #{File.basename(sample_file_path)} from #{source_lang} to #{target_lang}"

  begin
    result = lara.audio.translate_transcript(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang
    )

    puts "✅ Transcript translation completed"
    puts "📝 Translation: #{result.translation}"
    puts "🔎 Segments: #{result.segments.length}\n"
  rescue StandardError => e
    puts "Error translating transcript: #{e}\n"
    return
  end

  # Example 2: Transcript translation with advanced options
  puts "=== Transcript Translation with Advanced Options ==="
  begin
    result2 = lara.audio.translate_transcript(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang,
      adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"], # Replace with actual memory IDs
      glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"] # Replace with actual glossary IDs
    )

    puts "✅ Advanced transcript translation completed"
    puts "📝 Translation: #{result2.translation}\n"
  rescue StandardError => e
    puts "Error in advanced translation: #{e}"
  end
  puts

  # Example 3: Step-by-step transcript translation
  puts "=== Step-by-Step Transcript Translation ==="

  begin
    # Upload audio
    puts "Step 1: Uploading audio..."
    audio = lara.audio.upload_for_transcription(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang,
      adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"], # Replace with actual memory IDs
      glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"] # Replace with actual glossary IDs
    )
    puts "Audio uploaded with ID: #{audio.id}"
    puts "Initial status: #{audio.status}"

    # Check status with polling
    puts "\nStep 2: Checking status..."
    updated_audio = lara.audio.status(audio.id)
    puts "Current status: #{updated_audio.status}"

    # Poll until translation is complete
    while updated_audio.status != Lara::Models::AudioStatus::TRANSLATED
      updated_audio = lara.audio.status(audio.id)
      puts "Current status: #{updated_audio.status}"

      if updated_audio.status == Lara::Models::AudioStatus::ERROR
        raise "Translation failed: #{updated_audio.error_reason || 'Unknown error'}"
      end

      sleep 2
    end

    # Retrieve translated transcript
    puts "\nStep 3: Retrieving translated transcript..."
    result3 = lara.audio.get_translated_transcript(audio.id)

    puts "✅ Step-by-step transcript translation completed"
    puts "📝 Translation: #{result3.translation}"
    puts "🔎 Segments: #{result3.segments.length}"
  rescue StandardError => e
    puts "Error in step-by-step process: #{e}"
  end
end

main if __FILE__ == $PROGRAM_NAME
