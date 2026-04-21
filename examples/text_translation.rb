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
# - Translation with styleguides
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

    # Example 8: List available styleguides
    puts "=== List Available Styleguides ==="
    styleguide_id = nil
    styleguides = lara.styleguides.list
    puts "Total styleguides: #{styleguides.size}"
    styleguides.each do |sg|
      puts "  - #{sg.name} (ID: #{sg.id})"
    end
    styleguide_id = styleguides.first&.id if styleguides.any?
    puts

    # Example 9: Get a specific styleguide by ID
    if styleguide_id
      puts "=== Get Styleguide Details ==="
      styleguide = lara.styleguides.get(styleguide_id)
      if styleguide
        puts "Name: #{styleguide.name}"
        puts "ID: #{styleguide.id}"
        puts "Owner: #{styleguide.owner_id}"
        puts "Created: #{styleguide.created_at}"
        puts "Updated: #{styleguide.updated_at}"
      end
      puts
    end

    # Example 10: Translate with a styleguide
    if styleguide_id
      puts "=== Translate with Styleguide ==="
      result_sg = lara.translate(
        "Our team is excited to announce that the new feature is now available for all users.",
        target: "it-IT",
        source: "en-US",
        styleguide_id: styleguide_id
      )
      puts "Original: Our team is excited to announce that the new feature is now available for all users."
      puts "Italian (with styleguide): #{result_sg.translation}\n"
    end

    # Example 11: Translate with styleguide reasoning
    if styleguide_id
      puts "=== Translate with Styleguide Reasoning ==="
      result_sgr = lara.translate(
        "Please submit the required documentation before the deadline.",
        target: "it-IT",
        source: "en-US",
        styleguide_id: styleguide_id,
        styleguide_reasoning: true,
        styleguide_explanation_language: "en-US"
      )
      puts "Original: Please submit the required documentation before the deadline."
      puts "Italian (with styleguide): #{result_sgr.translation}"

      sg_results = result_sgr.styleguide_results
      if sg_results
        puts "Original translation (before styleguide): #{sg_results.original_translation}"

        if sg_results.changes && !sg_results.changes.empty?
          puts "Changes applied: #{sg_results.changes.size}"
          sg_results.changes.each do |change|
            puts "  Change ID: #{change.id}"
            puts "  Before: #{change.original_translation}"
            puts "  After:  #{change.refined_translation}"
            puts "  Why:    #{change.explanation}"
          end
        else
          puts "No changes were needed — translation already matches the styleguide."
        end
      end
      puts
    end

    # Example 12: Get available languages
    puts "=== Available Languages ==="
    languages = lara.get_languages
    puts "Supported languages: #{languages.inspect}"

    # Example 13: Detect language of a given text
    puts "=== Language Detection ==="
    detect_result = lara.detect("Hola, ¿cómo estás?")
    puts "Text: Hola, ¿cómo estás?"
    puts "Detected Language: #{detect_result.language}"
    puts "Content Type: #{detect_result.content_type}\n"

    # Example 14: Translation with reasoning
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

    # Example 15: Detect languages with hint and passlist
    puts "=== Language Detection with Hint and Passlist ==="
    detect_result = lara.detect("Hola, ¿cómo estás?", hint: "es", passlist: %w[es pt it])
    puts "Text: Hola, ¿cómo estás?"
    puts "Detected Language: #{detect_result.language}"

    # Example 12: Quality estimation for a single sentence pair
    puts "=== Quality Estimation: single sentence ==="
    qe_single = lara.quality_estimation(
      source: "en-US",
      target: "it-IT",
      sentence: "Hello, how are you today?",
      translation: "Ciao, come stai oggi?"
    )
    puts "Score: #{qe_single.score}\n"

    # Example 13: Quality estimation for a batch of sentence pairs
    puts "=== Quality Estimation: batch ==="
    qe_batch = lara.quality_estimation(
      source: "en-US",
      target: "it-IT",
      sentence: ["Good morning.", "The weather is nice."],
      translation: ["Buongiorno.", "Il tempo è bello."]
    )
    puts "Scores: #{qe_batch.map(&:score).join(', ')}\n"
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
end

main
