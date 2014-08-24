require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    
    varibs = params.keys.map{|el| el.to_s + " = ?"}.join(" AND ")

    new_vals = params.values
    results = DBConnection.execute(<<-SQL, *new_vals)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{varibs}
    SQL
    self.parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
