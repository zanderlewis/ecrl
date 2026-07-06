abstract class Expression; end

abstract class ValueExpr; end

class NumberValueExpr < ValueExpr
  property value : String

  def initialize(@value); end
end

class IdentifierValueExpr < ValueExpr
  property name : String

  def initialize(@name); end
end

class NegatedValueExpr < ValueExpr
  property inner : ValueExpr

  def initialize(@inner); end
end

abstract class TelemetryValue; end

class TelemetryStringLiteral < TelemetryValue
  property value : String

  def initialize(@value); end
end

class TelemetryInterpolatedString < TelemetryValue
  property segments : Array(InterpolatedSegment)

  def initialize(@segments); end

  def self.from_lexer(raw : String) : TelemetryInterpolatedString
    segments = [] of InterpolatedSegment
    raw.split('\0').each_with_index do |part, i|
      next if part.empty? && i.even?
      segments << InterpolatedSegment.new(literal: i.even?, value: part)
    end
    new(segments)
  end
end

record InterpolatedSegment,
  literal : Bool,
  value : String

class TelemetryRawExpr < TelemetryValue
  property expr : ValueExpr

  def initialize(@expr); end
end

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

class IfStatement < Expression
  property condition_left : ValueExpr
  property operator : String?
  property condition_right : ValueExpr?
  property then_branch = [] of Expression
  property else_branch = [] of Expression

  def initialize(@condition_left, @operator = nil, @condition_right = nil); end
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
