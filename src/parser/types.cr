require "./ast"

record ChassisWheel,
  name : String,
  direction : String

record Variable,
  id : String,
  value : String | Int64 | Float64

record Program,
  module_name : String,
  hardware : Hash(String, String),
  chassis : Hash(String, ChassisWheel),
  vars : Hash(String, Variable),
  name : String,
  group : String,
  body : Array(Expression) do
  REQUIRED_CHASSIS_KEYS = ["fl", "fr", "bl", "br"]

  def validate!
    validate_chassis!
    resolve_encoder_motors!
    validate_body!(body)
  end

  private def validate_chassis!
    return if chassis.empty?

    missing = REQUIRED_CHASSIS_KEYS - chassis.keys.to_a
    unless missing.empty?
      raise "[PARSER] Drivetrain is missing required wheel keys: #{missing.join(", ")}"
    end
  end

  private def resolve_encoder_motors!
    each_statement(body) do |expr|
      if expr.is_a?(SetVelocityExpr) && hardware.has_key?(expr.target)
        hardware[expr.target] = "DcMotorEx"
      end
    end
  end

  private def validate_body!(statements : Array(Expression))
    each_statement(statements) do |expr|
      case expr
      when DriveMecanumExpr
        if chassis.empty?
          raise "[PARSER] drive() requires a drivetrain in define"
        end
      when SetPowerExpr, SetVelocityExpr, StopExpr
        unless hardware.has_key?(expr.target)
          raise "[PARSER] Unknown device '#{expr.target}' — declare it with dc \"#{expr.target}\" in define"
        end
      end
    end
  end

  private def each_statement(statements : Array(Expression), &block : Expression ->)
    statements.each do |expr|
      yield expr
      case expr
      when IfStatement
        each_statement(expr.then_branch, &block)
        each_statement(expr.else_branch, &block)
      end
    end
  end
end
