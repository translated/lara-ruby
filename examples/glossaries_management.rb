# frozen_string_literal: true

require "lara"

# Complete glossary management examples for the Lara Ruby SDK
#
# This example demonstrates:
# - Create, list, update, delete glossaries
# - Individual term management (add/remove terms)
# - CSV import with status monitoring
# - Glossary export (sync and async, unidirectional and multidirectional)
# - Glossary terms count (unidirectional and multidirectional)
# - Import status checking
# - Add or replace glossary entries (with and without GUID)
# - Delete glossary entries (by term or by GUID)
# - Sharing a glossary with the account or a group (add, rename, list, revoke)

def main
  # All examples can use environment variables for credentials:
  # export LARA_ACCESS_KEY_ID="your-access-key-id"
  # export LARA_ACCESS_KEY_SECRET="your-access-key-secret"

  # Set your credentials here
  access_key_id = ENV["LARA_ACCESS_KEY_ID"] || "your-access-key-id"
  access_key_secret = ENV["LARA_ACCESS_KEY_SECRET"] || "your-access-key-secret"

  credentials = Lara::Credentials.new(access_key_id, access_key_secret)
  lara = Lara::Translator.new(credentials: credentials)

  puts "🗒️  Glossaries require a specific subscription plan."
  puts "   If you encounter errors, please check your subscription level.\n"

  glossary_id = nil

  begin
    # Example 1: Basic glossary management
    puts "=== Basic Glossary Management ==="
    glossary = lara.glossaries.create("MyDemoGlossary")
    puts "✅ Created glossary: #{glossary.name} (ID: #{glossary.id})"
    glossary_id = glossary.id

    # List all glossaries
    glossaries = lara.glossaries.list
    puts "📝 Total glossaries: #{glossaries.length}"
    puts

    # Example 2: Glossary operations
    puts "=== Glossary Operations ==="
    # Get glossary details
    retrieved_glossary = lara.glossaries.get(glossary_id)
    if retrieved_glossary
      puts "📖 Glossary: #{retrieved_glossary.name} (Owner: #{retrieved_glossary.owner_id})"
    end

    # Get glossary terms count
    counts = lara.glossaries.counts(glossary_id)
    if counts.unidirectional&.length&.positive?
      counts.unidirectional.each do |lang, count|
        puts "   #{lang}: #{count} entries"
      end
    end

    # Update glossary
    updated_glossary = lara.glossaries.update(glossary_id, "UpdatedDemoGlossary")
    puts "📝 Updated name: '#{glossary.name}' -> '#{updated_glossary.name}'"
    puts

    # Example 3: Term management
    puts "=== Term Management ==="

    # Add (or replace) individual terms to glossary
    begin
      terms = [
        { language: "fr-FR", value: "Bonjour" },
        { language: "es-ES", value: "Hola" }
      ]
      lara.glossaries.add_or_replace_entry(glossary_id, terms)
      puts "✅ Terms added successfully to glossary"
      puts
    rescue StandardError => e
      puts "⚠️  Could not add terms: #{e.message}\n"
    end

    # Remove a specific term from glossary
    begin
      term_to_remove = { language: "fr-FR", value: "Bonjour" }
      lara.glossaries.delete_entry(glossary_id, term: term_to_remove)
      puts "✅ Term removed successfully from glossary"
      puts
    rescue StandardError => e
      puts "⚠️  Could not remove term: #{e.message}\n"
    end

    # Example 4: CSV import functionality
    puts "=== CSV Import Functionality ==="

    # Replace with your actual CSV file path
    csv_file_path = "sample_glossary.csv" # Create this file with your glossary data

    if File.exist?(csv_file_path)
      puts "Importing CSV file: #{File.basename(csv_file_path)}"
      csv_import = lara.glossaries.import_csv(glossary_id, csv_file_path)
      puts "Import started with ID: #{csv_import.id}"
      puts "Initial progress: #{(csv_import.progress * 100).round}%"

      # Check import status manually
      puts "Checking import status..."
      import_status = lara.glossaries.get_import_status(csv_import.id)
      puts "Current progress: #{(import_status.progress * 100).round}%"

      # Wait for import to complete
      begin
        completed_import = lara.glossaries.wait_for_import(csv_import, max_wait_time: 10)
        puts "✅ Import completed!"
        puts "Final progress: #{(completed_import.progress * 100).round}%"
      rescue Timeout::Error
        puts "Import timeout: The import process took too long to complete."
      end
      puts
    else
      puts "CSV file not found: #{csv_file_path}"
    end

    # Example 4: CSV import with a callback URL (async notification when import completes)
    puts "=== CSV Import with Callback URL ==="
    if File.exist?(csv_file_path)
      begin
        callback_url = "https://your-server.example.com/lara/import-callback" # Replace with your endpoint
        import_with_callback = lara.glossaries.import_csv(glossary_id, csv_file_path,
                                                          callback_url: callback_url)
        puts "Import started with ID: #{import_with_callback.id} (callback: #{callback_url})"

        # You can also combine content_type, gzip, and callback_url:
        # lara.glossaries.import_csv(glossary_id, csv_file_path,
        #                            content_type: Lara::Glossaries::FileFormat::MULTIDIRECTIONAL,
        #                            gzip: true,
        #                            callback_url: callback_url)
        puts
      rescue StandardError => e
        puts "Error starting CSV import with callback: #{e.message}\n"
      end
    end

    # Example 5: Export functionality
    puts "=== Export Functionality ==="
    begin
      # Export as CSV table unidirectional format
      puts "📤 Exporting as CSV table unidirectional..."
      csv_uni_data = lara.glossaries.export(glossary_id, content_type: Lara::Glossaries::FileFormat::UNIDIRECTIONAL,
                                                         source: "en-US")
      puts "✅ CSV unidirectional export successful (#{csv_uni_data.length} bytes)"

      # Export as CSV table multidirectional format
      puts "📤 Exporting as CSV table multidirectional..."
      csv_multi_data = lara.glossaries.export(glossary_id, content_type: Lara::Glossaries::FileFormat::MULTIDIRECTIONAL)
      puts "✅ CSV multidirectional export successful (#{csv_multi_data.length} bytes)"

      # Save sample exports to files - replace with your desired output paths
      export_uni_file_path = "exported_glossary_uni.csv"
      export_multi_file_path = "exported_glossary_multi.csv"
      File.binwrite(export_uni_file_path, csv_uni_data)
      File.binwrite(export_multi_file_path, csv_multi_data)
      puts "💾 Sample unidirectional export saved to: #{export_uni_file_path}"
      puts "💾 Sample multidirectional export saved to: #{export_multi_file_path}"

      # Async export — returns a job_id; the result is delivered to your callback URL when ready
      puts "📤 Starting async export..."
      export_job = lara.glossaries.export_async(
        glossary_id,
        callback_url: "https://your-server.example.com/lara/export-callback", # Replace with your actual callback URL
        content_type: Lara::Glossaries::FileFormat::UNIDIRECTIONAL,
        source: "en-US"
      )
      puts "✅ Async export started (job ID: #{export_job.job_id})"
      puts "   The export result will be delivered to your callback URL when ready."
      puts
    rescue StandardError => e
      puts "Error with export: #{e.message}\n"
    end

    # Example 6: Glossary Terms Count
    puts "=== Glossary Terms Count ==="
    begin
      # Get detailed counts
      detailed_counts = lara.glossaries.counts(glossary_id)

      puts "📊 Detailed glossary terms count:"

      if detailed_counts.unidirectional && !detailed_counts.unidirectional.empty?
        puts "   Unidirectional entries by language pair:"
        detailed_counts.unidirectional.each do |lang_pair, count|
          puts "     #{lang_pair}: #{count} terms"
        end
      else
        puts "   No unidirectional entries found"
      end

      if detailed_counts.multidirectional
        puts "   Multidirectional entries: #{detailed_counts.multidirectional}"
      end

      total_entries = 0
      total_entries += detailed_counts.unidirectional.values.sum if detailed_counts.unidirectional
      total_entries += detailed_counts.multidirectional if detailed_counts.multidirectional
      puts "   Total entries: #{total_entries}"
      puts
    rescue StandardError => e
      puts "Error getting glossary terms count: #{e.message}\n"
    end

    # Example 7: Add or replace glossary entries
    puts "=== Add or Replace Glossary Entries ==="
    begin
      # Add a new entry with multiple language terms
      terms = [
        { language: "en-US", value: "computer" },
        { language: "it-IT", value: "computer" }
      ]
      add_result = lara.glossaries.add_or_replace_entry(glossary_id, terms)
      puts "✅ Entry added/replaced (import ID: #{add_result.id})"

      # Wait for the import to complete
      completed_add = lara.glossaries.wait_for_import(add_result)
      puts "   Import progress: #{(completed_add.progress * 100).round}%"

      # Add another entry with a custom GUID (multidirectional)
      terms_with_guid = [
        { language: "en-US", value: "keyboard" },
        { language: "it-IT", value: "tastiera" }
      ]
      add_with_guid_result = lara.glossaries.add_or_replace_entry(glossary_id, terms_with_guid,
                                                                  guid: "custom-guid-123")
      puts "✅ Entry added with GUID (import ID: #{add_with_guid_result.id})"
      lara.glossaries.wait_for_import(add_with_guid_result)

      # Replace an existing entry by using the same GUID
      updated_terms = [
        { language: "en-US", value: "keyboard" },
        { language: "it-IT", value: "tastiera" },
        { language: "fr-FR", value: "clavier" }
      ]
      replace_result = lara.glossaries.add_or_replace_entry(glossary_id, updated_terms,
                                                            guid: "custom-guid-123")
      puts "✅ Entry replaced with updated terms (import ID: #{replace_result.id})"
      lara.glossaries.wait_for_import(replace_result)
      puts
    rescue StandardError => e
      puts "Error adding/replacing entry: #{e.message}\n"
    end

    # Example 8: Delete glossary entries
    puts "=== Delete Glossary Entries ==="
    begin
      # Delete an entry by GUID (multidirectional)
      delete_by_guid_result = lara.glossaries.delete_entry(glossary_id, guid: "custom-guid-123")
      puts "✅ Entry deleted by GUID (import ID: #{delete_by_guid_result.id})"
      lara.glossaries.wait_for_import(delete_by_guid_result)

      # Delete an entry by term
      term = { language: "en-US", value: "computer" }
      delete_by_term_result = lara.glossaries.delete_entry(glossary_id, term: term)
      puts "✅ Entry deleted by term: #{term[:language]} -> \"#{term[:value]}\" (import ID: #{delete_by_term_result.id})"
      lara.glossaries.wait_for_import(delete_by_term_result)
      puts
    rescue StandardError => e
      puts "Error deleting entry: #{e.message}\n"
    end
    # Example 9: Glossary sharing
    # Sharing requires a multi-user account and the appropriate role (account owner for
    # account-wide shares, owner/admin for group shares). Each call returns the shared
    # glossary, whose `name` reflects the shared copy's name and `shared_at` the share time.
    puts "=== Glossary Sharing ==="
    begin
      # Share with the whole account/team (the optional name: names the shared copy)
      team_share = lara.glossaries.add_account_share(glossary_id, name: "Shared with the team")
      puts "🤝 Shared with the account as: '#{team_share.name}' (shared at #{team_share.shared_at})"

      # Rename the account/team share
      renamed_team_share = lara.glossaries.rename_account_share(glossary_id, name: "Team glossary")
      puts "📝 Renamed account share to: '#{renamed_team_share.name}'"

      # List every share visible to the caller: the account share, group shares and user shares
      shares = lara.glossaries.get_shares(glossary_id)
      if shares.account
        puts "👥 Account share '#{shares.account.share_name}' (#{shares.account.permissions})"
      end
      shares.groups.each do |group|
        puts "👥 Group #{group.name}: '#{group.share_name}' (#{group.permissions})"
      end
      shares.users.each do |user|
        puts "👤 User #{user.name}: '#{user.share_name}' (#{user.permissions})"
      end

      # Revoke the account/team share
      lara.glossaries.revoke_account_share(glossary_id)
      puts "🚫 Revoked the account share"

      # Group shares work the same way, addressed by a group ID (grp_...)
      group_id = ENV.fetch("LARA_GROUP_ID", nil) # Replace with an actual group ID
      if group_id
        group_share = lara.glossaries.add_group_share(glossary_id, group_id, name: "Shared with the group")
        puts "🤝 Shared with group #{group_id} as: '#{group_share.name}'"

        lara.glossaries.rename_group_share(glossary_id, group_id, name: "Marketing group")
        puts "📝 Renamed the group share"

        lara.glossaries.revoke_group_share(glossary_id, group_id)
        puts "🚫 Revoked the group share"
      else
        puts "Set LARA_GROUP_ID to try the group sharing methods."
      end
      puts
    rescue StandardError => e
      puts "Error sharing glossary: #{e.message}"
    end

  rescue StandardError => e
    puts "Error creating glossary: #{e.message}\n"
    return
  ensure
    # Cleanup
    puts "=== Cleanup ==="
    if glossary_id
      begin
        deleted_glossary = lara.glossaries.delete(glossary_id)
        puts "🗑️  Deleted glossary: #{deleted_glossary.name}"

        # Clean up export files
        %w[exported_glossary_uni.csv exported_glossary_multi.csv].each do |f|
          if File.exist?(f)
            File.delete(f)
            puts "🗑️  Cleaned up export file: #{f}"
          end
        end
      rescue StandardError => e
        puts "Error deleting glossary: #{e.message}"
      end
    end
  end

  puts "\n🎉 Glossary management examples completed!"
end

main
