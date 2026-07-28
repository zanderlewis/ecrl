require "../../parser/ast/mod"
require "../format/value"
require "../format/condition"

module EmitControl
  def self.emit_if_header(expr : IfStatement, io : IO, indent : String, inline : Bool)
    cond = FormatCondition.format_condition(expr.condition)
    io << (inline ? "" : indent) << "if (#{cond}) {\n"
  end

  def self.emit_while_header(expr : WhileStatement, io : IO, indent : String)
    cond = FormatCondition.format_condition(expr.condition)
    io << indent << "while (#{cond}) {\n"
  end

  def self.emit_for_header(expr : ForStatement, io : IO, indent : String)
    java_type = FormatValue.java_type_for_init(expr.init)
    init = FormatValue.format_value_expr(expr.init)
    cond = FormatCondition.format_condition(expr.condition)
    step = FormatValue.format_value_expr(expr.step_value)
    io << indent << "for (#{java_type} #{expr.var_name} = #{init}; #{cond}; #{expr.var_name} = #{step}) {\n"
  end
end
