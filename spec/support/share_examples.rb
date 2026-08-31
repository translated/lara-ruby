# frozen_string_literal: true

# Shared coverage for the account/group share lifecycle exposed by
# Lara::Glossaries, Lara::Memories and Lara::Styleguides.
#
# The host group must provide the `stub_get`/`stub_post`/`stub_put`/`stub_delete`
# helpers plus these lets:
#   resource_api     - the API object under test (e.g. `glossaries`)
#   resource_path    - collection path (e.g. "/v2/glossaries")
#   resource_id      - id matching the fixture used by `resource_content`
#   resource_content - fixture hash for the shared resource
#   resource_key     - key wrapping the resource in the shares payload (e.g. :glossary)
#   resource_model   - model class returned by the share mutations
#   shares_model     - model class returned by #get_shares
RSpec.shared_examples "a shareable resource" do
  let(:group_id) { "grp_9Zy8Xw7Vu6Ts5Rq4Po3Nm" }
  let(:shares_path) { "#{resource_path}/#{resource_id}/shares" }
  let(:group_shares_path) { "#{shares_path}/groups/#{group_id}" }

  def share_entry(id:, name:, permissions: "read_write")
    {
      "id" => id,
      "name" => name,
      "share_name" => "Shared #{name}",
      "shared_at" => "2024-02-01T10:00:00Z",
      "permissions" => permissions
    }
  end

  def expect_json_body(method, path, body)
    expect(a_request(method, "#{base_url}#{path}").with(body: body.to_json)).to have_been_made
  end

  def expect_empty_body(method, path)
    expect(
      a_request(method, "#{base_url}#{path}").with { |req| req.body.nil? || req.body.empty? }
    ).to have_been_made
  end

  describe "#get_shares" do
    it "returns the shares model with account, group and user entries" do
      stub_get(shares_path,
               resource_key.to_s => resource_content,
               "account" => share_entry(id: "acc_1XyZ2Ab3Cd4Ef5Gh6Ij7Kl", name: "Acme"),
               "groups" => [share_entry(id: group_id, name: "Translators", permissions: "read")],
               "users" => [share_entry(id: "usr_2Bc3De4Fg5Hi6Jk7Lm8No", name: "Jane", permissions: "read")])

      shares = resource_api.get_shares(resource_id)

      expect(shares).to be_a(shares_model)
      expect(shares.public_send(resource_key)).to be_a(resource_model)
      expect(shares.public_send(resource_key).id).to eq(resource_id)
      expect(shares.account).to be_a(Lara::Models::ResourceShareEntry)
      expect(shares.account.name).to eq("Acme")
      expect(shares.account.share_name).to eq("Shared Acme")
      expect(shares.account.shared_at).to eq(Time.iso8601("2024-02-01T10:00:00Z"))
      expect(shares.account.permissions).to eq("read_write")
      expect(shares.groups.map(&:permissions)).to eq(["read"])
      expect(shares.groups.map(&:id)).to eq([group_id])
      expect(shares.users.map(&:name)).to eq(["Jane"])
    end

    it "defaults account, groups and users when the response omits them" do
      stub_get(shares_path, resource_key.to_s => resource_content)

      shares = resource_api.get_shares(resource_id)

      expect(shares.account).to be_nil
      expect(shares.groups).to eq([])
      expect(shares.users).to eq([])
    end
  end

  describe "#add_account_share" do
    it "posts the share name to the shares path" do
      stub_post(shares_path, resource_content)

      result = resource_api.add_account_share(resource_id, name: "Team copy")

      expect(result).to be_a(resource_model)
      expect(result.id).to eq(resource_id)
      expect_json_body(:post, shares_path, { name: "Team copy" })
    end

    it "sends no body when no name is given" do
      stub_post(shares_path, resource_content)

      expect(resource_api.add_account_share(resource_id)).to be_a(resource_model)
      expect_empty_body(:post, shares_path)
    end
  end

  describe "#rename_account_share" do
    it "puts the new name to the shares path" do
      stub_put(shares_path, resource_content)

      result = resource_api.rename_account_share(resource_id, name: "Renamed")

      expect(result).to be_a(resource_model)
      expect_json_body(:put, shares_path, { name: "Renamed" })
    end
  end

  describe "#revoke_account_share" do
    it "deletes the shares path" do
      stub_delete(shares_path, resource_content)

      result = resource_api.revoke_account_share(resource_id)

      expect(result).to be_a(resource_model)
      expect(result.id).to eq(resource_id)
      expect(a_request(:delete, "#{base_url}#{shares_path}")).to have_been_made
    end
  end

  describe "#add_group_share" do
    it "posts the share name to the group shares path" do
      stub_post(group_shares_path, resource_content)

      result = resource_api.add_group_share(resource_id, group_id, name: "Team copy")

      expect(result).to be_a(resource_model)
      expect_json_body(:post, group_shares_path, { name: "Team copy" })
    end

    it "sends no body when no name is given" do
      stub_post(group_shares_path, resource_content)

      expect(resource_api.add_group_share(resource_id, group_id)).to be_a(resource_model)
      expect_empty_body(:post, group_shares_path)
    end
  end

  describe "#rename_group_share" do
    it "puts the new name to the group shares path" do
      stub_put(group_shares_path, resource_content)

      result = resource_api.rename_group_share(resource_id, group_id, name: "Renamed")

      expect(result).to be_a(resource_model)
      expect_json_body(:put, group_shares_path, { name: "Renamed" })
    end
  end

  describe "#revoke_group_share" do
    it "deletes the group shares path" do
      stub_delete(group_shares_path, resource_content)

      result = resource_api.revoke_group_share(resource_id, group_id)

      expect(result).to be_a(resource_model)
      expect(a_request(:delete, "#{base_url}#{group_shares_path}")).to have_been_made
    end
  end
end
