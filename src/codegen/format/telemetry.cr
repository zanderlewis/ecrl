require "../../parser/ast/mod"
require "./value"

module FormatTelemetry
  def self.format_telemetry_value(value : TelemetryValue) : String
    case value
    when TelemetryStringLiteral
      "\"#{value.value.gsub("\"", "\\\"")}\""
    when TelemetryInterpolatedString
      format_interpolated_string(value.segments)
    when TelemetryRawExpr
      FormatValue.format_value_expr(value.expr)
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
