ActiveRecord::Schema.define do

  create_table "model_with_uuids", :force => true do |t|
    t.string   "uuid",       :limit => 32
    t.string   "url"
    t.text     "body",       :limit => 16777216
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end