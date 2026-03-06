# frozen_string_literal: true

require "lara"

# Complete image translation examples for the Lara Ruby SDK
#
# This example demonstrates:
# - Basic image translation (returns translated image)
# - Advanced options with memories, glossaries, and styles
# - Extracting and translating text from an image

def main
  # All examples can use environment variables for credentials:
  # export LARA_ACCESS_KEY_ID="your-access-key-id"
  # export LARA_ACCESS_KEY_SECRET="your-access-key-secret"

  access_key_id = ENV["LARA_ACCESS_KEY_ID"] || "your-access-key-id"
  access_key_secret = ENV["LARA_ACCESS_KEY_SECRET"] || "your-access-key-secret"

  credentials = Lara::Credentials.new(access_key_id, access_key_secret)
  lara = Lara::Translator.new(credentials: credentials)

  # Replace with your actual image file path
  sample_file_path = "sample_image.png"

  unless File.exist?(sample_file_path)
    puts "Please create a sample image file at: #{sample_file_path}"
    puts "Add an image with text content to translate.\n"
    return
  end

  source_lang = "en"
  target_lang = "de"

  # Example 1: Basic image translation (image output)
  puts "=== Basic Image Translation ==="
  puts "Translating image: #{File.basename(sample_file_path)} from #{source_lang} to #{target_lang}"

  begin
    translated_image = lara.images.translate(
      file_path: sample_file_path,
      source: source_lang,
      target: target_lang,
      text_removal: "overlay"
    )

    output_path = "sample_image_translated.png"
    File.binwrite(output_path, translated_image)

    puts "✅ Image translation completed"
    puts "📄 Translated image saved to: #{File.basename(output_path)}\n"
  rescue StandardError => e
    puts "Error translating image: #{e.message}\n"
    return
  end

  # Example 2: Image translation with advanced options
  puts "=== Image Translation with Advanced Options ==="
  begin
    translated_image2 = lara.images.translate(
      file_path: sample_file_path,
      source: source_lang,
      target: target_lang,
      adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"],      # Replace with actual memory IDs
      glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"],     # Replace with actual glossary IDs
      style: "faithful",
      text_removal: "inpainting"
    )

    output_path2 = "advanced_image_translated.png"
    File.binwrite(output_path2, translated_image2)

    puts "✅ Advanced image translation completed"
    puts "📄 Translated image saved to: #{File.basename(output_path2)}\n"
  rescue StandardError => e
    puts "Error in advanced translation: #{e.message}"
  end
  puts

  # Example 3: Extract and translate text from an image
  puts "=== Extract and Translate Text ==="
  begin
    result = lara.images.translate_text(
      file_path: sample_file_path,
      source: source_lang,
      target: target_lang,
      adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"],      # Replace with actual memory IDs
      glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"],     # Replace with actual glossary IDs
      style: "faithful"
    )

    puts "✅ Extract and translate completed"
    puts "Source language: #{result.source_language}"
    puts "Found #{result.paragraphs.length} text blocks"

    result.paragraphs.each_with_index do |paragraph, index|
      puts "\nText Block #{index + 1}:"
      puts "Original: #{paragraph.text}"
      puts "Translated: #{paragraph.translation}"
    end
  rescue StandardError => e
    puts "Error extracting and translating text: #{e.message}"
  end
end

main if __FILE__ == $PROGRAM_NAME
