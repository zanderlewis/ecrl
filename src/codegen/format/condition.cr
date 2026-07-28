require "../../parser/ast/mod"
require "./value"

module FormatCondition
  def self.format_condition(cond : ConditionExpr) : String
    case cond
    when ValueCondition
      FormatValue.format_value_expr(cond.value)
    when ComparisonCondition
      "#{FormatValue.format_value_expr(cond.left)} #{cond.operator} #{FormatValue.format_value_expr(cond.right)}"
    when AndCondition
      "(#{format_condition(cond.left)} && #{format_condition(cond.right)})"
    when OrCondition
      "(#{format_condition(cond.left)} || #{format_condition(cond.right)})"
    else
      raise "[CODEGEN] Unsupported condition type: #{cond.class}"
    end
  end
end
