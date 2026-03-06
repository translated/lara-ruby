# frozen_string_literal: true

require "lara"

# Complete document translation examples for the Lara Ruby SDK
#
# This example demonstrates:
# - Basic document translation
# - Advanced options with memories and glossaries
# - Step-by-step document translation with status monitoring

def main
  # All examples can use environment variables for credentials:
  # export LARA_ACCESS_KEY_ID="your-access-key-id"
  # export LARA_ACCESS_KEY_SECRET="your-access-key-secret"

  # Set your credentials here
  access_key_id = ENV["LARA_ACCESS_KEY_ID"] || "your-access-key-id"
  access_key_secret = ENV["LARA_ACCESS_KEY_SECRET"] || "your-access-key-secret"

  credentials = Lara::Credentials.new(access_key_id, access_key_secret)
  lara = Lara::Translator.new(credentials: credentials)

  # Replace with your actual document file path
  sample_file_path = "sample_document.docx" # Create this file with your content

  unless File.exist?(sample_file_path)
    puts "Please create a sample document file at: #{sample_file_path}"
    puts "Add some sample text content to translate.\n"
    return
  end

  # Example 1: Basic document translation
  puts "=== Basic Document Translation ==="
  source_lang = "en-US"
  target_lang = "de-DE"

  puts "Translating document: #{File.basename(sample_file_path)} from #{source_lang} to #{target_lang}"

  begin
    translated_content = lara.documents.translate(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang
    )

    # Save translated document - replace with your desired output path
    output_path = "sample_document_translated.docx"
    File.binwrite(output_path, translated_content)

    puts "✅ Document translation completed"
    puts "📄 Translated file saved to: #{File.basename(output_path)}\n"
  rescue StandardError => e
    puts "Error translating document: #{e}\n"
    return
  end

  # Example 2: Document translation with advanced options
  puts "=== Document Translation with Advanced Options ==="
  begin
    translated_content2 = lara.documents.translate(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang,
      adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"], # Replace with actual memory IDs
      glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"] # Replace with actual glossary IDs
    )

    # Save translated document - replace with your desired output path
    output_path2 = "advanced_document_translated.docx"
    File.binwrite(output_path2, translated_content2)

    puts "✅ Advanced document translation completed"
    puts "📄 Translated file saved to: #{File.basename(output_path2)}"
  rescue StandardError => e
    puts "Error in advanced translation: #{e}"
  end
  puts

  # Example 3: Step-by-step document translation
  puts "=== Step-by-Step Document Translation ==="

  begin
    # Upload document
    puts "Step 1: Uploading document..."
    document = lara.documents.upload(
      file_path: sample_file_path,
      filename: File.basename(sample_file_path),
      source: source_lang,
      target: target_lang,
      adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"], # Replace with actual memory IDs
      glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"] # Replace with actual glossary IDs
    )
    puts "Document uploaded with ID: #{document.id}"
    puts "Initial status: #{document.status}"
    puts

    # Check status
    puts "Step 2: Checking status..."
    updated_document = lara.documents.status(document.id)
    puts "Current status: #{updated_document.status}"

    # Download translated document
    puts "\nStep 3: Downloading would happen after translation completes..."

    begin
      lara.documents.download(document.id)
    rescue StandardError => e
      puts "Download demonstration: #{e}"
    end

    puts "✅ Step-by-step translation completed"
  rescue StandardError => e
    puts "Error in step-by-step process: #{e}"
  end
end

main if __FILE__ == $PROGRAM_NAME
