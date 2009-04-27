require 'lib/activerecord_connector'
require 'fixtures/schema.rb'

class ActiveRecordTest < Test::Unit::TestCase
  FIXTURES_PTH = File.join(File.dirname(__FILE__), '/../fixtures')
  dep = defined?(ActiveSupport::Dependencies) ? ActiveSupport::Dependencies : ::Dependencies
  dep.load_paths.unshift FIXTURES_PTH
end