require "../../parser/ast/mod"
require "../format/value"

module EmitMisc
  def self.emit_wait(expr : WaitExpr, io : IO, indent : String, inline : Bool)
    seconds = FormatValue.format_value_expr(expr.seconds)
    io << (inline ? "" : indent) << "waitSeconds(#{seconds});\n"
  end

  def self.emit_call(expr : CallExpr, io : IO, indent : String, inline : Bool)
    args = expr.args.map { |a| FormatValue.format_value_expr(a) }.join(", ")
    io << (inline ? "" : indent) << "#{expr.name}(#{args});\n"
  end
end
