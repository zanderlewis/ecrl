require "./expression"
require "./value"

class DriveMecanumExpr < Expression
  property y : ValueExpr, x : ValueExpr, rx : ValueExpr

  def initialize(@y, @x, @rx); end
end

class SetPowerExpr < Expression
  property target : String, value : ValueExpr

  def initialize(@target, @value); end
end

class SetVelocityExpr < Expression
  property target : String, value : ValueExpr, ticks_per_rev : ValueExpr?

  def initialize(@target, @value, @ticks_per_rev = nil); end
end

class StopExpr < Expression
  property target : String

  def initialize(@target); end
end

class SetPositionExpr < Expression
  property target : String, value : ValueExpr

  def initialize(@target, @value); end
end
