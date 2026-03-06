# Lara Ruby SDK

[![Ruby Version](https://img.shields.io/badge/ruby-2.6+-blue.svg)](https://ruby-lang.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

This SDK empowers you to build your own branded translation AI leveraging our translation fine-tuned language model.

All major translation features are accessible, making it easy to integrate and customize for your needs.

## 🌍 **Features:**
- **Text Translation**: Single strings, multiple strings, and complex text blocks
- **Document Translation**: Word, PDF, and other document formats with status monitoring
- **Image Translation**: Translate whole images or extract and translate text blocks
- **Audio Translation**: Translate audio files with status monitoring
- **Translation Memory**: Store and reuse translations for consistency
- **Glossaries**: Enforce terminology standards across translations
- **Language Detection**: Automatic source language identification
- **Advanced Options**: Translation instructions and more

## 📚 Documentation

Lara's SDK full documentation is available at [https://developers.laratranslate.com/](https://developers.laratranslate.com/)

## 🚀 Quick Start

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'lara-sdk'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install lara-sdk

### Basic Usage

```ruby
require 'lara'

# Set your credentials using environment variables (recommended)
credentials = Lara::Credentials.new(
  ENV['LARA_ACCESS_KEY_ID'],
  ENV['LARA_ACCESS_KEY_SECRET']
)

# Create translator instance
lara = Lara::Translator.new(credentials: credentials)

# Simple text translation
begin
  result = lara.translate("Hello, world!", target: "fr-FR", source: "en-US")
  puts "Translation: #{result.translation}"
  # Output: Translation: Bonjour, le monde !
rescue => error
  puts "Translation error: #{error.message}"
end
```

## 📖 Examples

The `examples/` directory contains comprehensive examples for all SDK features.

**All examples use environment variables for credentials, so set them first:**
```bash
export LARA_ACCESS_KEY_ID="your-access-key-id"
export LARA_ACCESS_KEY_SECRET="your-access-key-secret"
```

### Text Translation
- **[text_translation.rb](examples/text_translation.rb)** - Complete text translation examples
  - Single string translation
  - Multiple strings translation
  - Translation with instructions
  - TextBlocks translation (mixed translatable/non-translatable content)
  - Auto-detect source language
  - Advanced translation options
  - Get available languages

```bash
cd examples
ruby text_translation.rb
```

### Document Translation
- **[document_translation.rb](examples/document_translation.rb)** - Document translation examples
  - Basic document translation
  - Advanced options with memories and glossaries
  - Step-by-step translation with status monitoring

```bash
cd examples
ruby document_translation.rb
```

### Image Translation
- **[image_translation.rb](examples/image_translation.rb)** - Image translation examples
  - Basic image translation
  - Advanced options with memories and glossaries
  - Extract and translate text from an image

```bash
cd examples
ruby image_translation.rb
```

### Audio Translation
- **[audio_translation.rb](examples/audio_translation.rb)** - Audio translation examples
  - Basic audio translation
  - Advanced options with memories and glossaries
  - Step-by-step audio translation with status monitoring

```bash
cd examples
ruby audio_translation.rb
```

### Translation Memory Management
- **[memories_management.rb](examples/memories_management.rb)** - Memory management examples
  - Create, list, update, delete memories
  - Add individual translations
  - Multiple memory operations
  - TMX file import with progress monitoring
  - Translation deletion
  - Translation with TUID and context

```bash
cd examples
ruby memories_management.rb
```

### Glossary Management
- **[glossaries_management.rb](examples/glossaries_management.rb)** - Glossary management examples
  - Create, list, update, delete glossaries
  - Individual term management (add/remove terms)
  - CSV import with status monitoring
  - Glossary export
  - Glossary terms count
  - Import status checking
  - Add or replace glossary entries
  - Delete glossary entries

```bash
cd examples
ruby glossaries_management.rb
```

## 🔧 API Reference

### Core Components

### 🔐 Authentication

The SDK supports authentication via access key and secret:

```ruby
require 'lara'

credentials = Lara::Credentials.new("your-access-key-id", "your-access-key-secret")
lara = Lara::Translator.new(credentials: credentials)
```

**Environment Variables (Recommended):**
```bash
export LARA_ACCESS_KEY_ID="your-access-key-id"
export LARA_ACCESS_KEY_SECRET="your-access-key-secret"
```

```ruby
require 'lara'

credentials = Lara::Credentials.new(
  ENV['LARA_ACCESS_KEY_ID'],
  ENV['LARA_ACCESS_KEY_SECRET']
)
lara = Lara::Translator.new(credentials: credentials)
```

**Alternative Constructor:**
```ruby
# You can also pass credentials directly to Translator
lara = Lara::Translator.new(
  access_key_id: "your-access-key-id",
  access_key_secret: "your-access-key-secret"
)
```

### 🌍 Translator

```ruby
# Create translator with credentials
lara = Lara::Translator.new(credentials: credentials)
```

#### Text Translation

```ruby
# Basic translation
result = lara.translate("Hello", target: "fr-FR", source: "en-US")

# Multiple strings
result = lara.translate(["Hello", "World"], target: "fr-FR", source: "en-US")

# TextBlocks (mixed translatable/non-translatable content)
require 'lara'

text_blocks = [
  Lara::Models::TextBlock.new(text: "Translatable text", translatable: true),
  Lara::Models::TextBlock.new(text: "<br>", translatable: false),  # Non-translatable HTML
  Lara::Models::TextBlock.new(text: "More translatable text", translatable: true)
]
result = lara.translate(text_blocks, target: "fr-FR", source: "en-US")

# With advanced options
result = lara.translate(
  "Hello",
  target: "fr-FR",
  source: "en-US",
  instructions: ["Formal tone"],
  adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"],  # Replace with actual memory IDs
  glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"],  # Replace with actual glossary IDs
  style: "fluid",
  timeout_ms: 10000
)
```

### 📖 Document Translation
#### Simple document translation

```ruby
# Replace with your actual file path
translated_content = lara.documents.translate(
  file_path: "/path/to/your/document.txt",
  filename: "document.txt",
  source: "en-US",
  target: "fr-FR"
)

# With options
translated_content = lara.documents.translate(
  file_path: "/path/to/your/document.txt",  # Replace with actual file path
  filename: "document.txt",
  source: "en-US",
  target: "fr-FR",
  adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"],  # Replace with actual memory IDs
  glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"],  # Replace with actual glossary IDs
  style: "fluid"
)
```
### Document translation with status monitoring
#### Document upload
```ruby
#Optional: upload options
document = lara.documents.upload(
  file_path: "/path/to/your/document.txt",  # Replace with actual file path
  filename: "document.txt",
  source: "en-US",
  target: "fr-FR",
  adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"],  # Replace with actual memory IDs
  glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"]  # Replace with actual glossary IDs
)
```
#### Document translation status monitoring
```ruby
status = lara.documents.status(document.id)
```
#### Download translated document
```ruby
translated_content = lara.documents.download(document.id)
```

### 🖼️ Image Translation

```ruby
require 'lara'

# Translate an image and receive a translated image as binary data
translated_image = lara.images.translate(
  file_path: "/path/to/your/image.png",  # Replace with actual file path
  source: "en",
  target: "fr",
  text_removal: "inpainting",
  style: "faithful"
)

# Save the translated image
File.binwrite("translated_image.png", translated_image)

# Extract and translate text blocks from an image
result = lara.images.translate_text(
  file_path: "/path/to/your/image.png",  # Replace with actual file path
  source: "en",
  target: "fr",
  adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"],      # Replace with actual memory IDs
  glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"]       # Replace with actual glossary IDs
)

result.paragraphs.each do |paragraph|
  puts "Original: #{paragraph.text}"
  puts "Translated: #{paragraph.translation}"
end
```

### 🔊 Audio Translation
#### Simple audio translation

```ruby
# Replace with your actual file path
translated_content = lara.audio.translate(
  file_path: "/path/to/your/audio.mp3",
  filename: "audio.mp3",
  source: "en-US",
  target: "fr-FR"
)

# With options
translated_content = lara.audio.translate(
  file_path: "/path/to/your/audio.mp3",  # Replace with actual file path
  filename: "audio.mp3",
  source: "en-US",
  target: "fr-FR",
  adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"],  # Replace with actual memory IDs
  glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"],  # Replace with actual glossary IDs
  style: "fluid"
)
```
### Audio translation with status monitoring
#### Audio upload
```ruby
#Optional: upload options
audio = lara.audio.upload(
  file_path: "/path/to/your/audio.mp3",  # Replace with actual file path
  filename: "audio.mp3",
  source: "en-US",
  target: "fr-FR",
  adapt_to: ["mem_1A2b3C4d5E6f7G8h9I0jKl"],  # Replace with actual memory IDs
  glossaries: ["gls_1A2b3C4d5E6f7G8h9I0jKl"]  # Replace with actual glossary IDs
)
```
#### Audio translation status monitoring
```ruby
status = lara.audio.status(audio.id)
```
#### Download translated audio
```ruby
translated_content = lara.audio.download(audio.id)
```

### 🧠 Memory Management

```ruby
# Create memory
memory = lara.memories.create("MyMemory")

# Create memory with external ID (MyMemory integration)
memory = lara.memories.create("Memory from MyMemory", external_id: "aabb1122")  # Replace with actual external ID

# Important: To update/overwrite a translation unit you must provide a tuid. Calls without a tuid always create a new unit and will not update existing entries.
# Add translation to single memory
memory_import = lara.memories.add_translation("mem_1A2b3C4d5E6f7G8h9I0jKl", "en-US", "fr-FR", "Hello", "Bonjour", tuid: "greeting_001")

# Add translation to multiple memories
memory_import = lara.memories.add_translation(["mem_1A2b3C4d5E6f7G8h9I0jKl", "mem_2XyZ9AbC8dEf7GhI6jKlMn"], "en-US", "fr-FR", "Hello", "Bonjour", tuid: "greeting_002")

# Add with context
memory_import = lara.memories.add_translation(
  "mem_1A2b3C4d5E6f7G8h9I0jKl", "en-US", "fr-FR", "Hello", "Bonjour",
  tuid: "tuid", sentence_before: "sentenceBefore", sentence_after: "sentenceAfter"
)

# TMX import from file
memory_import = lara.memories.import_tmx("mem_1A2b3C4d5E6f7G8h9I0jKl", "/path/to/your/memory.tmx")  # Replace with actual TMX file path

# Delete translation
# Important: if you omit tuid, all entries that match the provided fields will be removed
delete_job = lara.memories.delete_translation(
  "mem_1A2b3C4d5E6f7G8h9I0jKl", "en-US", "fr-FR", "Hello", "Bonjour", tuid: "greeting_001"
)

# Wait for import completion
completed_import = lara.memories.wait_for_import(memory_import, max_wait_time: 300)  # 5 minutes
```

### 📚 Glossary Management

```ruby
# Create glossary
glossary = lara.glossaries.create("MyGlossary")

# Import unidirectional CSV from file
glossary_import = lara.glossaries.import_csv("gls_1A2b3C4d5E6f7G8h9I0jKl", "/path/to/your/glossary.csv")  # Replace with actual CSV file path

# Import multidirectional CSV from file
glossary_import = lara.glossaries.import_csv(
  "gls_1A2b3C4d5E6f7G8h9I0jKl",
  "/path/to/your/multidirectional_glossary.csv",  # Replace with actual CSV file path
  content_type: Lara::Glossaries::FileFormat::MULTIDIRECTIONAL
)

# Add (or replace) individual terms to glossary (unidirectional)
terms = [
  { language: "fr-FR", value: "Bonjour" },
  { language: "es-ES", value: "Hola" }
]
lara.glossaries.add_or_replace_entry("gls_1A2b3C4d5E6f7G8h9I0jKl", terms)

# Add (or replace) a multidirectional entry with a custom GUID
terms_with_guid = [
  { language: "en-US", value: "keyboard" },
  { language: "it-IT", value: "tastiera" },
  { language: "fr-FR", value: "clavier" }
]
lara.glossaries.add_or_replace_entry("gls_1A2b3C4d5E6f7G8h9I0jKl", terms_with_guid, guid: "custom-guid-123")

# Remove a specific term from glossary
term_to_remove = { language: "fr-FR", value: "Bonjour" }
lara.glossaries.delete_entry("gls_1A2b3C4d5E6f7G8h9I0jKl", term: term_to_remove)

# Remove a multidirectional entry by GUID
lara.glossaries.delete_entry("gls_1A2b3C4d5E6f7G8h9I0jKl", guid: "custom-guid-123")

# Check import status
import_status = lara.glossaries.get_import_status(import_id)

# Wait for import completion
completed_import = lara.glossaries.wait_for_import(glossary_import, max_wait_time: 300)  # 5 minutes

# Export glossary (unidirectional)
csv_data = lara.glossaries.export("gls_1A2b3C4d5E6f7G8h9I0jKl",
                                  content_type: Lara::Glossaries::FileFormat::UNIDIRECTIONAL,
                                  source: "en-US")

# Export glossary (multidirectional)
csv_data = lara.glossaries.export("gls_1A2b3C4d5E6f7G8h9I0jKl",
                                  content_type: Lara::Glossaries::FileFormat::MULTIDIRECTIONAL)

# Get glossary terms count (includes both unidirectional and multidirectional counts)
counts = lara.glossaries.counts("gls_1A2b3C4d5E6f7G8h9I0jKl")
```

### Translation Options

```ruby
result = lara.translate(
  text,
  target: "fr-FR",                          # Target language (required)
  source: "en-US",                          # Source language (optional, auto-detect if nil)
  source_hint: "en",                        # Hint for source language detection
  adapt_to: ["memory-id"],                  # Memory IDs to adapt to
  glossaries: ["glossary-id"],              # Glossary IDs to use
  instructions: ["instruction"],            # Translation instructions
  style: "fluid",                           # Translation style (fluid, faithful, creative)
  content_type: "text/plain",               # Content type (text/plain, text/html, etc.)
  multiline: true,                          # Enable multiline translation
  timeout_ms: 10000,                        # Request timeout in milliseconds
  no_trace: false,                          # Disable request tracing
  verbose: false,                           # Enable verbose response
)
```

### Language Codes

The SDK supports full language codes (e.g., `en-US`, `fr-FR`, `es-ES`) as well as simple codes (e.g., `en`, `fr`, `es`):

```ruby
# Full language codes (recommended)
result = lara.translate("Hello", target: "fr-FR", source: "en-US")

# Simple language codes
result = lara.translate("Hello", target: "fr", source: "en")
```

### 🌐 Supported Languages

The SDK supports all languages available in the Lara API. Use the `get_languages()` method to get the current list:

```ruby
languages = lara.get_languages
puts "Supported languages: #{languages.join(', ')}"
```

## ⚙️ Configuration

### Error Handling

The SDK provides detailed error information:

```ruby
begin
  result = lara.translate("Hello", target: "fr-FR", source: "en-US")
  puts "Translation: #{result.translation}"
rescue Lara::LaraApiError => error
  puts "API Error [#{error.status_code}]: #{error.message}"
  puts "Error type: #{error.type}"
rescue Lara::LaraError => error
  puts "SDK Error: #{error.message}"
rescue => error
  puts "Unexpected error: #{error.message}"
end
```

## 📋 Requirements

- Ruby 2.6 or higher
- Bundler
- Valid Lara API credentials

## 🧪 Testing

Run the examples to test your setup:

```bash
# All examples use environment variables for credentials, so set them first:
export LARA_ACCESS_KEY_ID="your-access-key-id"
export LARA_ACCESS_KEY_SECRET="your-access-key-secret"
```

```bash
# Run basic text translation example
cd examples
ruby text_translation.rb
```

## 🏗️ Building from Source

```bash
# Clone the repository
git clone https://github.com/translated/lara-ruby.git
cd lara-ruby

# Install dependencies
bundle install
```

## 🧪 Running tests

The test suite uses [RSpec](https://rspec.info/) with [WebMock](https://github.com/bblimke/webmock) to stub HTTP calls, so **no real API requests** are made and no credentials are required.

```bash
# Run all tests
bundle exec rspec spec

# Run with documentation format (lists each example)
bundle exec rspec spec --format documentation

# Run a specific file or example
bundle exec rspec spec/lara/translator_spec.rb
bundle exec rspec spec/lara/translator_spec.rb:45
```

After a run, a coverage report is generated in `coverage/` (via [SimpleCov](https://github.com/simplecov-ruby/simplecov)). Open `coverage/index.html` in a browser to view line coverage.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Happy translating! 🌍✨