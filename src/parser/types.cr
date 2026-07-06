require "./ast"

DEFAULT_JAVA_PACKAGE = "org.firstinspires.ftc.teamcode.teleop"

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
  body : Array(Expression),
  package : String = DEFAULT_JAVA_PACKAGE do
  REQUIRED_CHASSIS_KEYS = ["fl", "fr", "bl", "br"]

  def validate!
    validate_package!
    validate_chassis!
    resolve_encoder_motors!
    validate_body!(body)
  end

  def uses_drive? : Bool
    found = false
    each_statement(body) do |expr|
      found = true if expr.is_a?(DriveMecanumExpr)
    end
    found
  end

  private def validate_package!
    unless package =~ /\A[a-zA-Z_]\w*(\.[a-zA-Z_]\w*)*\z/
      raise "[PARSER] Invalid Java package name: '#{package}'"
    end
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
        validate_motor!(expr.target)
      when SetPositionExpr
        validate_servo!(expr.target)
      end
    end
  end

  private def validate_motor!(name : String)
    type = hardware[name]?
    unless type == "DcMotor" || type == "DcMotorEx"
      if type == "Servo"
        raise "[PARSER] '#{name}' is a servo — use set_position instead of motor methods"
      end
      raise "[PARSER] Unknown motor '#{name}' — declare it with dc \"#{name}\" in define"
    end
  end

  private def validate_servo!(name : String)
    type = hardware[name]?
    unless type == "Servo"
      if type == "DcMotor" || type == "DcMotorEx"
        raise "[PARSER] '#{name}' is a motor — use set_power/set_velocity instead of set_position"
      end
      raise "[PARSER] Unknown servo '#{name}' — declare it with servo \"#{name}\" in define"
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
