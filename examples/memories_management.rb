# frozen_string_literal: true

require "lara"

# Complete memory management examples for the Lara Ruby SDK
#
# This example demonstrates:
# - Create, list, update, delete memories
# - Add individual translations
# - Multiple memory operations
# - TMX file import with progress monitoring
# - Translation deletion
# - Translation with TUID and context

def main
  # All examples use environment variables for credentials, so set them first:
  # export LARA_ACCESS_KEY_ID="your-access-key-id"
  # export LARA_ACCESS_KEY_SECRET="your-access-key-secret"

  # Set your credentials here
  access_key_id = ENV["LARA_ACCESS_KEY_ID"] || "your-access-key-id"
  access_key_secret = ENV["LARA_ACCESS_KEY_SECRET"] || "your-access-key-secret"

  credentials = Lara::Credentials.new(access_key_id, access_key_secret)
  lara = Lara::Translator.new(credentials: credentials)

  memory_id = nil
  memory_2_to_delete = nil

  begin
    # Example 1: Basic memory management
    puts "=== Basic Memory Management ==="
    memory = lara.memories.create("MyDemoMemory")
    puts "✅ Created memory: #{memory.name} (ID: #{memory.id})"
    memory_id = memory.id

    # Get memory details
    retrieved_memory = lara.memories.get(memory_id)
    if retrieved_memory
      puts "📖 Memory: #{retrieved_memory.name} (Owner: #{retrieved_memory.owner_id})"
    end

    # Update memory
    updated_memory = lara.memories.update(memory_id, "UpdatedDemoMemory")
    puts "📝 Updated name: '#{memory.name}' -> '#{updated_memory.name}'"
    puts

    # List all memories
    memories = lara.memories.list
    puts "📝 Total memories: #{memories.length}"

    # Example 2: Adding translations
    # Important: To update/overwrite a translation unit you must provide a tuid. Calls without a tuid always create a new unit and will not update existing entries.
    puts "=== Adding Translations ==="
    begin
      # Basic translation addition (with TUID)
      mem_import1 = lara.memories.add_translation(memory_id, "en-US", "fr-FR", "Hello", "Bonjour",
                                                  tuid: "greeting_001")
      puts "✅ Added: 'Hello' -> 'Bonjour' with TUID 'greeting_001' (Import ID: #{mem_import1.id})"

      # Translation with context
      mem_import2 = lara.memories.add_translation(
        memory_id, "en-US", "fr-FR", "How are you?", "Comment allez-vous?",
        tuid: "greeting_002",
        sentence_before: "Good morning",
        sentence_after: "Have a nice day"
      )
      puts "✅ Added with context (Import ID: #{mem_import2.id})"
    rescue StandardError => e
      puts "Error adding translations: #{e.message}\n"
    end

    # Example 3: Multiple memory operations
    puts "=== Multiple Memory Operations ==="
    begin
      # Create second memory for multi-memory operations
      memory2 = lara.memories.create("SecondDemoMemory")
      memory_2_id = memory2.id
      puts "✅ Created second memory: #{memory2.name}"

      # Add translation to multiple memories (with TUID)
      memory_ids = [memory_id, memory_2_id]
      multi_import_job = lara.memories.add_translation(memory_ids, "en-US", "it-IT",
                                                       "Hello World!", "Ciao Mondo!", tuid: "greeting_003")
      puts "✅ Added translation to multiple memories (Import ID: #{multi_import_job.id})"
      puts

      # Store for cleanup
      memory_2_to_delete = memory_2_id
    rescue StandardError => e
      puts "Error with multiple memory operations: #{e.message}\n"
      memory_2_to_delete = nil
    end

    # Example 4: TMX import functionality
    puts "=== TMX Import Functionality ==="

    # Replace with your actual TMX file path
    tmx_file_path = "sample_memory.tmx" # Create this file with your TMX content

    if File.exist?(tmx_file_path)
      begin
        puts "Importing TMX file: #{File.basename(tmx_file_path)}"
        tmx_import = lara.memories.import_tmx(memory_id, tmx_file_path)
        puts "Import started with ID: #{tmx_import.id}"
        puts "Initial progress: #{(tmx_import.progress * 100).round}%"

        # Wait for import to complete
        begin
          completed_import = lara.memories.wait_for_import(tmx_import, max_wait_time: 10)
          puts "✅ Import completed!"
          puts "Final progress: #{(completed_import.progress * 100).round}%"
        rescue Timeout::Error
          puts "Import timeout: The import process took too long to complete."
        end
        puts
      rescue StandardError => e
        puts "Error with TMX import: #{e.message}\n"
      end
    else
      puts "TMX file not found: #{tmx_file_path}"
    end

    # Example 5: Translation deletion
    puts "=== Translation Deletion ==="
    begin
      # Delete a specific translation unit (with TUID)
      # Important: if you omit tuid, all entries that match the provided fields will be removed
      delete_job = lara.memories.delete_translation(
        memory_id,
        "en-US",
        "fr-FR",
        "Hello",
        "Bonjour",
        tuid: "greeting_001" # Specify the TUID to delete a specific translation unit
      )
      puts "🗑️  Deleted translation unit (Job ID: #{delete_job.id})"
      puts
    rescue StandardError => e
      puts "Error deleting translation: #{e.message}\n"
    end
  rescue StandardError => e
    puts "Error creating memory: #{e.message}\n"
  ensure
    # Cleanup
    puts "=== Cleanup ==="
    if memory_id
      begin
        deleted_memory = lara.memories.delete(memory_id)
        puts "🗑️  Deleted memory: #{deleted_memory.name}"
      rescue StandardError => e
        puts "Error deleting memory: #{e.message}"
      end
    end

    if memory_2_to_delete
      begin
        deleted_memory2 = lara.memories.delete(memory_2_to_delete)
        puts "🗑️  Deleted second memory: #{deleted_memory2.name}"
      rescue StandardError => e
        puts "Error deleting second memory: #{e.message}"
      end
    end
  end

  puts "\n🎉 Memory management examples completed!"
end

main
