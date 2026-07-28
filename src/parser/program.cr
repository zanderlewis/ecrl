require "./ast/mod"

DEFAULT_JAVA_PACKAGE = "org.firstinspires.ftc.teamcode.teleop"

enum OpModeKind
  TeleOp
  Autonomous
end

record ChassisWheel,
  name : String,
  direction : String

record Variable,
  id : String,
  value : String | Int64 | Float64

record RoutineDef,
  name : String,
  params : Array(String),
  body : Array(Expression)

record Program,
  module_name : String,
  hardware : Hash(String, String),
  chassis : Hash(String, ChassisWheel),
  vars : Hash(String, Variable),
  routines : Array(RoutineDef),
  kind : OpModeKind,
  name : String,
  group : String,
  body : Array(Expression),
  package : String = DEFAULT_JAVA_PACKAGE do
  def uses_drive? : Bool
    found = false
    each_all_statements do |expr|
      found = true if expr.is_a?(DriveMecanumExpr)
    end
    found
  end

  def uses_deadzone? : Bool
    found = false
    each_all_statements do |expr|
      found = true if contains_deadzone?(expr)
    end
    found
  end

  def uses_wait? : Bool
    found = false
    each_all_statements do |expr|
      found = true if expr.is_a?(WaitExpr)
    end
    found
  end

  private def each_all_statements(&block : Expression ->)
    ProgramWalker.each_statement(body, &block)
    routines.each do |routine|
      ProgramWalker.each_statement(routine.body, &block)
    end
  end

  private def contains_deadzone?(expr : Expression) : Bool
    case expr
    when DriveMecanumExpr
      value_has_deadzone?(expr.y) || value_has_deadzone?(expr.x) || value_has_deadzone?(expr.rx)
    when SetPowerExpr, SetPositionExpr
      value_has_deadzone?(expr.value)
    when SetVelocityExpr
      ticks = expr.ticks_per_rev
      value_has_deadzone?(expr.value) || (!ticks.nil? && value_has_deadzone?(ticks.not_nil!))
    when WaitExpr
      value_has_deadzone?(expr.seconds)
    when CallExpr
      expr.args.any? { |a| value_has_deadzone?(a) }
    when VarReassignmentExpr
      value_has_deadzone?(expr.value)
    when ForStatement
      value_has_deadzone?(expr.init) || value_has_deadzone?(expr.step_value)
    else
      false
    end
  end

  private def value_has_deadzone?(expr : ValueExpr) : Bool
    case expr
    when DeadzoneValueExpr
      true
    when NegatedValueExpr
      value_has_deadzone?(expr.inner)
    when BinaryValueExpr
      value_has_deadzone?(expr.left) || value_has_deadzone?(expr.right)
    else
      false
    end
  end
end
