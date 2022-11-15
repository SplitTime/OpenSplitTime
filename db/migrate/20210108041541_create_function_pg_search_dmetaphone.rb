class CreateFunctionPgSearchDmetaphone < ActiveRecord::Migration[6.1]
  def change
    create_function :pg_search_dmetaphone
  end
end
