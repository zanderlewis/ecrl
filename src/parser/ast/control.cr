require "./expression"
require "./value"
require "./condition"
require "./telemetry"

class IfStatement < Expression
  property condition : ConditionExpr
  property then_branch = [] of Expression
  property else_branch = [] of Expression

  def initialize(@condition); end
end

class WhileStatement < Expression
  property condition : ConditionExpr
  property body = [] of Expression

  def initialize(@condition); end
end

class ForStatement < Expression
  property var_name : String
  property init : ValueExpr
  property condition : ConditionExpr
  property step_value : ValueExpr
  property body = [] of Expression

  def initialize(@var_name, @init, @condition, @step_value); end
end

class WaitExpr < Expression
  property seconds : ValueExpr

  def initialize(@seconds); end
end

class CallExpr < Expression
  property name : String
  property args : Array(ValueExpr)

  def initialize(@name, @args); end
end

class VarReassignmentExpr < Expression
  property var_name : String
  property value : ValueExpr

  def initialize(@var_name, @value); end
end

class TelemetryAddDataExpr < Expression
  property label : String
  property args : Array(TelemetryValue)

  def initialize(@label, @args); end
end

class TelemetryUpdateExpr < Expression
end
