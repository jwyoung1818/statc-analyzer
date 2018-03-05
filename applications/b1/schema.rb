ActiveRecord::Schema.define(version: 20151207180050) do
  create_table "users", force: true do |t|
    t.string   "username",                     limit: 50
    t.string   "email",                        limit: 100
    t.string   "password_digest",              limit: 75
    t.datetime "created_at"
    t.boolean  "email_notifications",                           default: false
    t.boolean  "is_admin",                                      default: false
    t.string   "password_reset_token",         limit: 75
    t.string   "session_token",                limit: 75,       default: "",    null: false
    t.text     "about",                        limit: 16777215
    t.integer  "invited_by_user_id"
    t.boolean  "email_replies",                                 default: false
    t.boolean  "pushover_replies",                              default: false
    t.string   "pushover_user_key"
    t.boolean  "email_messages",                                default: true
    t.boolean  "pushover_messages",                             default: true
    t.boolean  "is_moderator",                                  default: false
    t.boolean  "email_mentions",                                default: false
    t.boolean  "pushover_mentions",                             default: false
    t.string   "rss_token",                    limit: 75
    t.string   "mailing_list_token",           limit: 75
    t.integer  "mailing_list_mode",                             default: 0
    t.integer  "karma",                                         default: 0,     null: false
    t.datetime "banned_at"
    t.integer  "banned_by_user_id"
    t.string   "banned_reason",                limit: 200
    t.datetime "deleted_at"
    t.boolean  "show_avatars",                                  default: false
  end
  create_table "blogs", force: true do |t|
    t.string   "code"
    t.boolean  "is_verified", default: false
    t.string   "email"
    t.string   "name"
    t.text     "memo"
    t.string   "ip_address"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end
end
