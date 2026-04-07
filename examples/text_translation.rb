# frozen_string_literal: true

require "lara"

# Complete text translation examples for the Lara Ruby SDK
#
# This example demonstrates:
# - Single string translation
# - Multiple strings translation
# - Translation with instructions
# - TextBlocks translation (mixed translatable/non-translatable content)
# - Auto-detect source language
# - Advanced translation options
# - Get available languages
# - Language detection

def main
  # All examples use environment variables for credentials, so set them first:
  # export LARA_ACCESS_KEY_ID="your-access-key-id"
  # export LARA_ACCESS_KEY_SECRET="your-access-key-secret"
  # Falls back to placeholders if not set
  access_key_id = ENV["LARA_ACCESS_KEY_ID"] || "your-access-key-id"
  access_key_secret = ENV["LARA_ACCESS_KEY_SECRET"] || "your-access-key-secret"

  credentials = Lara::Credentials.new(access_key_id, access_key_secret)
  lara = Lara::Translator.new(credentials: credentials)

  begin
    # Example 1: Basic single string translation
    puts "=== Basic Single String Translation ==="
    result1 = lara.translate("Hello, world!", target: "fr-FR", source: "en-US")
    puts "Original: Hello, world!"
    puts "French: #{result1.translation}\n"

    # Example 2: Multiple strings translation
    puts "=== Multiple Strings Translation ==="
    texts = ["Hello", "How are you?", "Goodbye"]
    result2 = lara.translate(texts, target: "es-ES", source: "en-US")
    puts "Original: #{texts.inspect}"
    puts "Spanish: #{result2.translation.inspect}\n"

    # Example 3: TextBlocks translation (mixed translatable/non-translatable content)
    puts "=== TextBlocks Translation ==="
    text_blocks = [
      Lara::Models::TextBlock.new(
        text: "Adventure novels, mysteries, cookbooks—wait, who packed those?", translatable: true
      ),
      Lara::Models::TextBlock.new(text: "<br>", translatable: false), # Non-translatable HTML
      Lara::Models::TextBlock.new(text: "Suddenly, it doesn't feel so deserted after all.",
                                  translatable: true),
      Lara::Models::TextBlock.new(text: '<div class="separator"></div>', translatable: false), # Non-translatable HTML
      Lara::Models::TextBlock.new(text: "Every page you turn is a new journey, and the best part?",
                                  translatable: true)
    ]

    result3 = lara.translate(text_blocks, target: "it-IT", source: "en-US")
    puts "Original TextBlocks: #{text_blocks.length} blocks"
    puts "Translated blocks: #{result3.translation.length}"
    result3.translation.each_with_index do |translation, i|
      puts "Block #{i + 1}: #{translation['text']}"
    end
    puts

    # Example 4: Translation with instructions
    puts "=== Translation with Instructions ==="
    result4 = lara.translate(
      "Could you send me the report by tomorrow morning?",
      target: "de-DE",
      source: "en-US",
      instructions: ["Be formal", "Use technical terminology"]
    )
    puts "Original: Could you send me the report by tomorrow morning?"
    puts "German (formal): #{result4.translation}\n"

    # Example 5: Auto-detecting source language
    puts "=== Auto-detect Source Language ==="
    result5 = lara.translate("Bonjour le monde!", target: "en-US")
    puts "Original: Bonjour le monde!"
    puts "Detected source: #{result5.source_language}"
    puts "English: #{result5.translation}\n"

    # Example 6: Advanced options with comprehensive settings
    puts "=== Translation with Advanced Options ==="

    result6 = lara.translate(
      "This is a comprehensive translation example",
      target: "it-IT",
      source: "en-US",
      adapt_to: %w[mem_1A2b3C4d5E6f7G8h9I0jKl mem_2XyZ9AbC8dEf7GhI6jKlMn], # Replace with actual memory IDs
      glossaries: %w[gls_1A2b3C4d5E6f7G8h9I0jKl gls_2XyZ9AbC8dEf7GhI6jKlMn], # Replace with actual glossary IDs
      instructions: ["Be professional"],
      style: "fluid",
      content_type: "text/plain",
      timeout_ms: 10_000
    )
    puts "Original: This is a comprehensive translation example"
    puts "Italian (with all options): #{result6.translation}\n"

    # Example 7: Translation with profanity filter
    puts "=== Translation with Profanity Filter ==="
    profanity_text = "Don't be such a tool."
    result7 = lara.translate(profanity_text, target: "it-IT", source: "en-US", profanity_filter: "detect")
    puts "Original: #{profanity_text}"
    puts "Detect mode: #{result7.translation}"
    if result7.profanities
      puts "Masked text: #{result7.profanities.masked_text}"
      puts "Profanities found: #{result7.profanities.profanities.length}"
    end

    result7b = lara.translate(profanity_text, target: "it-IT", source: "en-US", profanity_filter: "hide")
    puts "Hide mode: #{result7b.translation}"

    result7c = lara.translate(profanity_text, target: "it-IT", source: "en-US", profanity_filter: "avoid")
    puts "Avoid mode: #{result7c.translation}\n"

    # Example 8: Get available languages
    puts "=== Available Languages ==="
    languages = lara.get_languages
    puts "Supported languages: #{languages.inspect}"

    # Example 9: Detect language of a given text
    puts "=== Language Detection ==="
    detect_result = lara.detect("Hola, ¿cómo estás?")
    puts "Text: Hola, ¿cómo estás?"
    puts "Detected Language: #{detect_result.language}"
    puts "Content Type: #{detect_result.content_type}\n"

    # Example 10: Translation with reasoning
    puts "=== Translation with Reasoning ==="
    result10 = lara.translate(
      "Wonderful cavernous interior in a central but quiet and private area!",
      target: "it-IT",
      source: "en-US",
      reasoning: true
    ) do |partial_result|
      puts "Partial result: #{partial_result.translation}"
    end
    puts "Final result: #{result10.translation}\n"

    # Example 11: Detect languages with hint and passlist
    puts "=== Language Detection with Hint and Passlist ==="
    detect_result = lara.detect("Hola, ¿cómo estás?", hint: "es", passlist: %w[es pt it])
    puts "Text: Hola, ¿cómo estás?"
    puts "Detected Language: #{detect_result.language}"
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
end

main
