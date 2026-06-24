require "../parser/types"

class ValueFormatter
  def self.get_java_type(value : String | Int64 | Float64) : String
    case value
    when String
      "String"
    when Int64
      "int"
    when Float64
      "double"
    else
      raise "How did you even get this error???"
    end
  end

  def self.format_value(value : String | Int64 | Float64) : String
    case value
    when String
      "\"#{value}\""
    else
      value.to_s
    end
  end
end
