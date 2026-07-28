require "../../parser/ast/mod"
require "../format/value"

module EmitVars
  def self.emit(expr : VarReassignmentExpr, io : IO, indent : String, inline : Bool)
    value = FormatValue.format_value_expr(expr.value)
    io << (inline ? "" : indent) << "#{expr.var_name} = #{value};\n"
  end
end
