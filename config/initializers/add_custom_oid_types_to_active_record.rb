ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
  def initialize_type_map_with_postgres_oids mapping
    initialize_type_map_without_postgres_oids mapping
    register_class_with_limit mapping, 'participants',
                              ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::Integer
  end

  alias_method_chain :initialize_type_map, :postgres_oids
end