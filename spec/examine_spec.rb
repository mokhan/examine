# frozen_string_literal: true

RSpec.describe Examine do
  specify { expect(Examine::VERSION).not_to be_nil }
end
