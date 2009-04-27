require 'test/unit'
require 'lib/activerecord_test'
require 'fixtures/model_with_uuids'


class ModelWithUuidTest < ActiveRecordTest
  
  def setup
    Fixtures.create_fixtures(FIXTURES_PTH, 'model_with_uuids')
    
  end
  
  # test new - should add a uuid attribute if not already present
  def test_new_save
    # adds uuid if not present
    obj = ModelWithUuid.new({:url => 'example.com'})
    assert obj.uuid.is_a?(String)  
    assert obj.save!
  end  
  
  # ModelWithUuid.find(uuid_string) should work
  def test_use_uuid_find
    assert_equal "feedproxy.google.com/techcrunch", ModelWithUuid.find("123456uiyhgtt").url
    # also test we didn't break the normal finders
    assert_raise RuntimeError do
      ModelWithUuid.find(1)
    end  
    assert_equal "www.henriquez.net", ModelWithUuid.find(:first, :conditions => ['uuid = ?', '234cfwe234']).url
    assert_equal "www.henriquez.net", ModelWithUuid.find_by_uuid('234cfwe234').url
    assert_equal '234cfwe234', ModelWithUuid.find_by_url("www.henriquez.net").uuid
  end
  
  def test_schema_less_attrs_initialization_and_get
    # if initialized with no arguments, schema less attrs should exist as accessors but be nil
    entry = ModelWithUuid.new
    assert entry.methods.include?("likes")
    assert entry.methods.include?("irrelevants")
    assert !entry.likes
    # if init with arguments, non schema less attrs should not be included in body when set
    # and schema less attrs should be included in body
    entry = ModelWithUuid.new :url => 'yaya', :author_href => "hayyman hey", :likes => ['a', 'b'], :irrelevants => {:a => :b, :c => :d}
    assert !entry.body.has_key?('url')
    assert entry.likes == entry.body['likes']
    assert entry.likes == ['a', 'b'] 
    assert entry.irrelevants ==  {:a => :b, :c => :d}
    entry = ModelWithUuid.new :likes => nil, :irrelevants => {:a => :b, :c => :d}
    assert entry.likes == nil 
    assert entry.irrelevants ==  {:a => :b, :c => :d}
    entry = ModelWithUuid.new :url => nil, :likes => "what?"
    assert entry.likes == "what?"
  end
  
  def test_schema_less_attrs_set_db
    # test setter and getters can be saved to the db and retrieved.
    entry = ModelWithUuid.new :url => 'lkjlkjlkj'
    entry.likes = ['happy', 'dumpty']
    entry.save!
    db_entry = ModelWithUuid.find(entry.uuid)
    assert db_entry.likes == ['happy', 'dumpty']
  end
  

  
end
