require_relative 'associatable'

module Associatable
  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = 
              through_options.model_class.assoc_options[source_name]
      key_value = self.send(through_options.foreign_key) 
      
      srce = source_options.table_name
      srce_pk = source_options.primary_key
      srce_fk = source_options.foreign_key
      
      thru = through_options.table_name
      thru_pk = through_options.primary_key
      
      result = DBConnection.execute(<<-SQL, key_value)
              SELECT
                  #{srce}.*
              FROM
                  #{thru} 
              JOIN 
                  #{srce}
              ON
                  #{thru}.#{srce_fk} = #{srce}.#{srce_pk}
              WHERE
                  #{thru}.#{thru_pk} = ?
              SQL
      source_options.model_class.parse_all(result).first
    end
  end
end
