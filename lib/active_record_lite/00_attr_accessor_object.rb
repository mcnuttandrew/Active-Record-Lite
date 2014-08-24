class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name) do       #get
          instance_variable_get("@#{name}")
      end
      define_method("#{name}=".to_sym) do |argument|      #set
          instance_variable_set("@#{name}", argument)
      end
    end
  end
end
