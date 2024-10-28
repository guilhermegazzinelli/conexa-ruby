require 'spec_helper'
require 'conexa/version'

RSpec.describe Conexa::VERSION do
  it { expect(Conexa::VERSION).to_not be_nil }
end