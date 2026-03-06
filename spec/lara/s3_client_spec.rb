# frozen_string_literal: true

require "tempfile"
require "spec_helper"

RSpec.describe Lara::S3Client do
  let(:upload_url) { "https://s3-fake.example.com/upload" }
  let(:download_url) { "https://s3-fake.example.com/download/doc123" }

  describe "#upload" do
    it "succeeds when S3 returns success" do
      stub_request(:post, upload_url).to_return(status: 200, body: "")
      Tempfile.create("upload") do |f|
        f.write("content")
        f.rewind
        expect do
          described_class.new.upload(url: upload_url, fields: { "key" => "k1" },
                                     io: f.path)
        end.not_to raise_error
      end
    end

    it "accepts io as file path string" do
      stub_request(:post, upload_url).to_return(status: 200)
      Tempfile.create("upload") do |f|
        f.write("x")
        f.rewind
        described_class.new.upload(url: upload_url, fields: { "key" => "k1" }, io: f.path)
      end
      expect(WebMock).to have_requested(:post, upload_url)
    end

    it "sends the basename as the filename when io is a file path" do
      stub_request(:post, upload_url).to_return(status: 200)
      Tempfile.create("upload-name") do |f|
        f.write("hello")
        f.rewind
        basename = File.basename(f.path)
        described_class.new.upload(url: upload_url, fields: { "k" => "v" }, io: f.path)
        expect(WebMock).to(have_requested(:post, upload_url).with do |req|
          req.body.to_s.include?("filename=\"#{basename}\"")
        end)
      end
    end

    it "raises LaraError when S3 returns non-success" do
      stub_request(:post, upload_url).to_return(status: 403, body: "Forbidden")
      Tempfile.create("upload") do |f|
        f.rewind
        expect do
          described_class.new.upload(url: upload_url, fields: { "key" => "k1" }, io: f.path)
        end
          .to raise_error(Lara::LaraError, /S3 upload failed/)
      end
    end

    it "wraps Faraday connection errors into Lara::LaraError" do
      stub_request(:post, upload_url).to_raise(Faraday::ConnectionFailed.new("connection failed"))
      Tempfile.create("upload") do |f|
        f.write("x")
        f.rewind
        expect do
          described_class.new.upload(url: upload_url, fields: { "k" => "v" }, io: f.path)
        end.to raise_error(Lara::LaraError, /S3 upload failed/)
      end
    end
  end

  describe "#download" do
    it "returns body on success" do
      stub_request(:get, download_url).to_return(status: 200, body: "file bytes")
      result = described_class.new.download(url: download_url)
      expect(result).to eq("file bytes")
    end

    it "raises LaraError when request fails" do
      stub_request(:get, download_url).to_return(status: 404)
      expect { described_class.new.download(url: download_url) }
        .to raise_error(Lara::LaraError, /S3 download failed/)
    end
  end
end
