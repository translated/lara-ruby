# frozen_string_literal: true

require "lara"

# Complete audio translation examples for the Lara Ruby SDK
#
# This example demonstrates:
# - Basic audio translation
# - Advanced options with memories and glossaries
# - Step-by-step audio translation with status monitoring

def main
  # All examples can use environment variables for credentials:
  # export LARA_ACCESS_KEY_ID="your-access-key-id"
  # export LARA_ACCESS_KEY_SECRET="your-access-key-secret"

  # Set your credentials here
  access_key_id = ENV["LARA_ACCESS_KEY_ID"] || "your-access-key-id"
  access_key_secret = ENV["LARA_ACCESS_KEY_SECRET"] || "your-access-key-secret"

  credentials = Lara::Credentials.new(access_key_id, access_key_secret)
  lara = Lara::Translator.new(credentials: credentials)

  # Replace with your actual audio file path
  sample_file_path = "sample_audio.mp3"

  unless File.exist?(sample_file_path)
    puts "Please create a sample audio file at: #{sample_file_path}"
    puts "Add some sample audio content to translate.\n"
    return
  end

  # Example 1: Basic audio translation
  puts "=== Basic Audio Translation ==="
  source_lang = "en-US"
  target_lang = "de-DE"

  puts "Translating audio: #{File.basename(sample_file_path)} from #{source_lang} to #{target_lang}"

  begin
    translated_content = lara.audio.translate(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang
    )

    output_path = "sample_audio_translated.mp3"
    File.binwrite(output_path, translated_content)

    puts "✅ Audio translation completed"
    puts "🔊 Translated file saved to: #{File.basename(output_path)}\n"
  rescue StandardError => e
    puts "Error translating audio: #{e}\n"
    return
  end

  # Example 2: Audio translation with advanced options
  puts "=== Audio Translation with Advanced Options ==="
  begin
    translated_content2 = lara.audio.translate(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang,
      adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"], # Replace with actual memory IDs
      glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"] # Replace with actual glossary IDs
    )

    # Save translated audio - replace with your desired output path
    output_path2 = "advanced_audio_translated.mp3"
    File.binwrite(output_path2, translated_content2)

    puts "✅ Advanced audio translation completed"
    puts "🔊 Translated file saved to: #{File.basename(output_path2)}"
  rescue StandardError => e
    puts "Error in advanced translation: #{e}"
  end
  puts

  # Example 3: Step-by-step audio translation
  puts "=== Step-by-Step Audio Translation ==="

  begin
    # Upload audio
    puts "Step 1: Uploading audio..."
    audio = lara.audio.upload(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang,
      adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"], # Replace with actual memory IDs
      glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"] # Replace with actual glossary IDs
    )
    puts "Audio uploaded with ID: #{audio.id}"
    puts "Initial status: #{audio.status}"
    puts

    # Check status
    puts "Step 2: Checking status..."
    updated_audio = lara.audio.status(audio.id)
    puts "Current status: #{updated_audio.status}"

    # Download translated audio
    puts "\nStep 3: Downloading would happen after translation completes..."

    begin
      lara.audio.download(audio.id)
    rescue StandardError => e
      puts "Download demonstration: #{e}"
    end

    puts "✅ Step-by-step translation completed"
  rescue StandardError => e
    puts "Error in step-by-step process: #{e}"
  end
end

main if __FILE__ == $PROGRAM_NAME
