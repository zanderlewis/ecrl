require "../parser/types"
require "../parser/ast"

class ValueFormatter
  def self.get_java_type(value : String | Int64 | Float64) : String
    case value
    when String  then "String"
    when Int64   then "int"
    when Float64 then "double"
    else            raise "[CODEGEN] Unsupported variable type: #{value.class}"
    end
  end

  def self.format_value(value : String | Int64 | Float64) : String
    case value
    when String then "\"#{value}\""
    else             value.to_s
    end
  end

  def self.motor_field(name : String) : String
    "ecrl__#{name}Motor"
  end

  def self.translate_gamepad(expr : String) : String
    expr.gsub("gpad.", "gamepad1.")
  end

  def self.format_value_expr(expr : ValueExpr) : String
    case expr
    when NumberValueExpr
      expr.value
    when IdentifierValueExpr
      translate_gamepad(expr.name)
    when NegatedValueExpr
      "-#{format_value_expr(expr.inner)}"
    else
      raise "[CODEGEN] Unsupported value expression type: #{expr.class}"
    end
  end

  def self.format_telemetry_value(value : TelemetryValue) : String
    case value
    when TelemetryStringLiteral
      "\"#{value.value.gsub("\"", "\\\"")}\""
    when TelemetryInterpolatedString
      format_interpolated_string(value.segments)
    when TelemetryRawExpr
      format_value_expr(value.expr)
    else
      raise "[CODEGEN] Unsupported telemetry value type: #{value.class}"
    end
  end

  def self.format_interpolated_string(segments : Array(InterpolatedSegment)) : String
    java_parts = [] of String

    segments.each do |segment|
      if segment.literal
        escaped = segment.value.gsub("\\", "\\\\").gsub("\"", "\\\"")
        java_parts << "\"#{escaped}\"" unless escaped.empty?
      else
        java_parts << segment.value.strip
      end
    end

    java_parts.empty? ? "\"\"" : java_parts.join(" + ")
  end
end
