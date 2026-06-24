abstract class Expression; end

class DriveMecanumExpr < Expression
  property y : String, x : String, rx : String

  def initialize(@y, @x, @rx); end
end

class SetPowerExpr < Expression
  property target : String, value : String

  def initialize(@target, @value); end
end

class SetVelocityExpr < Expression
  property target : String, value : String, ticks_per_rev : String?

  def initialize(@target, @value, @ticks_per_rev = nil); end
end

class StopExpr < Expression
  property target : String

  def initialize(@target); end
end

class IfStatement < Expression
  property condition_left : String
  property operator : String?
  property condition_right : String?
  property then_branch = [] of Expression
  property else_branch = [] of Expression

  def initialize(@condition_left, @operator = nil, @condition_right = nil); end
end

class VarReassignmentExpr < Expression
  property var_name : String
  property value : String

  def initialize(@var_name, @value); end
end

class TelemetryAddDataExpr < Expression
  property label : String
  property args : Array(String)

  def initialize(@label, @args); end
end

class TelemetryUpdateExpr < Expression
end
