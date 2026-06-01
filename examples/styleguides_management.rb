# frozen_string_literal: true

require "lara"

# Complete styleguide management examples for the Lara Ruby SDK
#
# This example demonstrates:
# - Create, list, get, update, delete styleguides

def main
  access_key_id = ENV["LARA_ACCESS_KEY_ID"] || "your-access-key-id"
  access_key_secret = ENV["LARA_ACCESS_KEY_SECRET"] || "your-access-key-secret"

  credentials = Lara::Credentials.new(access_key_id, access_key_secret)
  lara = Lara::Translator.new(credentials: credentials)

  puts "Styleguides require a specific subscription plan."
  puts "If you encounter errors, please check your subscription level.\n"

  styleguide_id = nil

  begin
    puts "=== Basic Styleguide Management ==="
    initial_content = "Use a formal tone. Prefer British English spelling. Avoid contractions."
    styleguide = lara.styleguides.create(name: "MyDemoStyleguide", content: initial_content)
    puts "Created styleguide: #{styleguide.name} (ID: #{styleguide.id})"
    styleguide_id = styleguide.id

    styleguides = lara.styleguides.list
    puts "Total styleguides: #{styleguides.length}"
    puts

    puts "=== Styleguide Operations ==="
    retrieved = lara.styleguides.get(styleguide_id)
    puts "Styleguide: #{retrieved.name} (Owner: #{retrieved.owner_id})" if retrieved

    renamed = lara.styleguides.update(styleguide_id, name: "UpdatedDemoStyleguide")
    puts "Updated name: '#{styleguide.name}' -> '#{renamed.name}'"

    updated_content = "Use a casual tone. Prefer American English spelling."
    lara.styleguides.update(styleguide_id, content: updated_content)
    puts "Updated content"

    fully_updated = lara.styleguides.update(
      styleguide_id,
      name: "FinalDemoStyleguide",
      content: "Use clear and concise language. Avoid jargon."
    )
    puts "Final name: #{fully_updated.name}"

    missing = lara.styleguides.get("non-existent-id")
    puts missing.nil? ? "Non-existent styleguide correctly returned nil" : "Unexpected result for missing ID"
    puts
  rescue StandardError => e
    puts "Error: #{e.message}"
  ensure
    if styleguide_id
      begin
        deleted = lara.styleguides.delete(styleguide_id)
        puts "Deleted styleguide: #{deleted.name} (ID: #{deleted.id})"
      rescue StandardError => e
        puts "Could not delete styleguide: #{e.message}"
      end
    end
  end
end

main if $PROGRAM_NAME == __FILE__
