class AddFuzzymatchToPostgres < ActiveRecord::Migration
  def change
    enable_extension 'fuzzystrmatch'
    enable_extension 'pg_trgm'
  end
end
