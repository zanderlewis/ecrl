# Compatibility facade matching the old ValueFormatter API
require "./format/value"
require "./format/condition"
require "./format/telemetry"

class ValueFormatter
  def self.get_java_type(value : String | Int64 | Float64) : String
    FormatValue.get_java_type(value)
  end

  def self.format_value(value : String | Int64 | Float64) : String
    FormatValue.format_value(value)
  end

  def self.hardware_field(name : String, type : String) : String
    FormatValue.hardware_field(name, type)
  end

  def self.motor_field(name : String) : String
    FormatValue.motor_field(name)
  end

  def self.translate_gamepad(expr : String) : String
    FormatValue.translate_gamepad(expr)
  end

  def self.format_value_expr(expr : ValueExpr) : String
    FormatValue.format_value_expr(expr)
  end

  def self.format_condition(cond : ConditionExpr) : String
    FormatCondition.format_condition(cond)
  end

  def self.format_telemetry_value(value : TelemetryValue) : String
    FormatTelemetry.format_telemetry_value(value)
  end
end
