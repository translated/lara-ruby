# frozen_string_literal: true

require "lara"

# Complete styleguide management examples for the Lara Ruby SDK
#
# This example demonstrates:
# - Create, list, get, update, delete styleguides
# - Sharing a styleguide with the account or a group (add, rename, list, revoke)

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
    # Sharing requires a multi-user account and the appropriate role (account owner for
    # account-wide shares, owner/admin for group shares). Each call returns the shared
    # styleguide, whose `name` reflects the shared copy's name and `shared_at` the share time.
    puts "=== Styleguide Sharing ==="
    begin
      # Share with the whole account/team (the optional name: names the shared copy)
      team_share = lara.styleguides.add_account_share(styleguide_id, name: "Shared with the team")
      puts "Shared with the account as: '#{team_share.name}' (shared at #{team_share.shared_at})"

      # Rename the account/team share
      renamed_team_share = lara.styleguides.rename_account_share(styleguide_id, name: "Team styleguide")
      puts "Renamed account share to: '#{renamed_team_share.name}'"

      # List every share visible to the caller: the account share, group shares and user shares
      shares = lara.styleguides.get_shares(styleguide_id)
      if shares.account
        puts "Account share '#{shares.account.share_name}' (#{shares.account.permissions})"
      end
      shares.groups.each do |group|
        puts "Group #{group.name}: '#{group.share_name}' (#{group.permissions})"
      end
      shares.users.each do |user|
        puts "User #{user.name}: '#{user.share_name}' (#{user.permissions})"
      end

      # Revoke the account/team share
      lara.styleguides.revoke_account_share(styleguide_id)
      puts "Revoked the account share"

      # Group shares work the same way, addressed by a group ID (grp_...)
      group_id = ENV.fetch("LARA_GROUP_ID", nil) # Replace with an actual group ID
      if group_id
        group_share = lara.styleguides.add_group_share(styleguide_id, group_id, name: "Shared with the group")
        puts "Shared with group #{group_id} as: '#{group_share.name}'"

        lara.styleguides.rename_group_share(styleguide_id, group_id, name: "Marketing group")
        puts "Renamed the group share"

        lara.styleguides.revoke_group_share(styleguide_id, group_id)
        puts "Revoked the group share"
      else
        puts "Set LARA_GROUP_ID to try the group sharing methods."
      end
      puts
    rescue StandardError => e
      puts "Error sharing styleguide: #{e.message}"
    end

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
