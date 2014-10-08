require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    result = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}"
    SQL
    result[0].map {|el| el.to_sym }
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column){ attributes[column] }
      define_method("#{column}=".to_sym){|argument| attributes[column] = argument }
     end
  end

  def self.table_name=(table_name)
    instance_variable_set("@#{table_name}", table_name)
  end

  def self.table_name
    #only works in case of two words, fuck it, return later use a loop
    string_name = self.name.to_s
    x = string_name.index(/.[A-Z]/)
    if x != nil
      front = string_name.take(x + 1)
      back = string_name.split("") - front + ['s']
      "#{front.join("").downcase}_#{back.join("").downcase}"
    else
      string_name.downcase + 's'
    end
  end

  def self.all
    result = DBConnection.execute2(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    result.delete_at(0)
    self.parse_all(result)
  end

  def self.parse_all(results)
   results.map {|el| self.new(el) unless el.nil?}
  end

  def self.find(id)
    result = DBConnection.execute2(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
      LIMIT 
        2
    SQL
    self.parse_all([result[1]])[0]
  end

  def attributes
    @attributes ||= Hash.new
  end

  def insert
    col_names = self.class.columns
    quest_marks = (['?'] * (col_names.length )).join(", ")
    result = DBConnection.execute2(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names.join(", ")})
      VALUES
        (#{quest_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = {})
    class_columns = self.class.columns
    params.keys.each do |key|
      sym_key = key.to_sym
       if class_columns.include?(sym_key)
          self.send("#{sym_key}=".to_sym, params[key])
       else 
         raise "unknown attribute '#{sym_key}'"
       end
    end
  end

  def save
    self.id.nil? ? self.insert : self.update
  end

  def update
    col_names = self.class.columns.map{|el| el.to_s + " = ?"}.join(", ")
    id_value = self.id.to_i
    DBConnection.execute2(<<-SQL,  *attribute_values)
    UPDATE
      #{self.class.table_name}
    SET
      #{col_names}
    WHERE
      id = #{id_value}
    SQL
  end

  def attribute_values
    self.class.columns.map do |col|
      self.send("#{col}".to_sym)
    end
  end
end
