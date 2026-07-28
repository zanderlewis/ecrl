require "../../parser/ast/mod"
require "../format/telemetry"

module EmitTelemetry
  def self.emit(expr : Expression, io : IO, indent : String, inline : Bool)
    case expr
    when TelemetryAddDataExpr
      args_str = expr.args.map { |arg| FormatTelemetry.format_telemetry_value(arg) }.join(", ")
      if args_str.empty?
        io << (inline ? "" : indent) << "telemetry.addData(\"#{expr.label}\", \"\");\n"
      else
        io << (inline ? "" : indent) << "telemetry.addData(\"#{expr.label}\", #{args_str});\n"
      end
    when TelemetryUpdateExpr
      io << (inline ? "" : indent) << "telemetry.update();\n"
    else
      raise "[CODEGEN] Not a telemetry expression: #{expr.class}"
    end
  end
end
