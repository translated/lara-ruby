# frozen_string_literal: true

require_relative "lara/version"
require_relative "lara/credentials"
require_relative "lara/auth_token"
require_relative "lara/errors"
require_relative "lara/client"
require_relative "lara/translator"
require_relative "lara/memories"
require_relative "lara/glossaries"
require_relative "lara/styleguides"
require_relative "lara/s3_client"
require_relative "lara/documents"
require_relative "lara/images"
require_relative "lara/audio"

# Models
require_relative "lara/models/base"
require_relative "lara/models/text"
require_relative "lara/models/memories"
require_relative "lara/models/glossaries"
require_relative "lara/models/documents"
require_relative "lara/models/images"
require_relative "lara/models/audio"

module Lara
  # Ruby SDK for Lara AI-powered translation services
end
