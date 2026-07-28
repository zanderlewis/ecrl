require "./ast/mod"
require "./program"

module ProgramWalker
  def self.each_statement(statements : Array(Expression), &block : Expression ->)
    statements.each do |expr|
      yield expr
      case expr
      when IfStatement
        each_statement(expr.then_branch, &block)
        each_statement(expr.else_branch, &block)
      when WhileStatement
        each_statement(expr.body, &block)
      when ForStatement
        each_statement(expr.body, &block)
      end
    end
  end
end

module ProgramValidator
  REQUIRED_CHASSIS_KEYS = ["fl", "fr", "bl", "br"]

  def self.validate!(program : Program)
    validate_package!(program)
    validate_chassis!(program)
    resolve_encoder_motors!(program)
    validate_routines!(program)
    validate_body!(program, program.body)
    program.routines.each { |r| validate_body!(program, r.body) }
  end

  private def self.validate_package!(program : Program)
    unless program.package =~ /\A[a-zA-Z_]\w*(\.[a-zA-Z_]\w*)*\z/
      raise "[PARSER] Invalid Java package name: '#{program.package}'"
    end
  end

  private def self.validate_chassis!(program : Program)
    return if program.chassis.empty?

    missing = REQUIRED_CHASSIS_KEYS - program.chassis.keys.to_a
    unless missing.empty?
      raise "[PARSER] Drivetrain is missing required wheel keys: #{missing.join(", ")}"
    end
  end

  private def self.resolve_encoder_motors!(program : Program)
    ProgramWalker.each_statement(program.body) do |expr|
      upgrade_velocity!(program, expr)
    end
    program.routines.each do |routine|
      ProgramWalker.each_statement(routine.body) do |expr|
        upgrade_velocity!(program, expr)
      end
    end
  end

  private def self.upgrade_velocity!(program : Program, expr : Expression)
    if expr.is_a?(SetVelocityExpr) && program.hardware.has_key?(expr.target)
      program.hardware[expr.target] = "DcMotorEx"
    end
  end

  private def self.validate_routines!(program : Program)
    names = {} of String => Int32
    program.routines.each do |routine|
      if names.has_key?(routine.name)
        raise "[PARSER] Duplicate routine '#{routine.name}'"
      end
      names[routine.name] = routine.params.size

      reserved = {"drive", "wait", "deadzone"}
      if reserved.includes?(routine.name)
        raise "[PARSER] Routine name '#{routine.name}' is reserved"
      end
    end

    check_calls = ->(statements : Array(Expression)) {
      ProgramWalker.each_statement(statements) do |expr|
        if expr.is_a?(CallExpr)
          unless names.has_key?(expr.name)
            raise "[PARSER] Unknown routine '#{expr.name}'"
          end
          expected = names[expr.name]
          if expr.args.size != expected
            raise "[PARSER] Routine '#{expr.name}' expects #{expected} argument(s), got #{expr.args.size}"
          end
        end
      end
    }

    check_calls.call(program.body)
    program.routines.each { |r| check_calls.call(r.body) }
  end

  private def self.validate_body!(program : Program, statements : Array(Expression))
    ProgramWalker.each_statement(statements) do |expr|
      case expr
      when DriveMecanumExpr
        if program.chassis.empty?
          raise "[PARSER] drive() requires a drivetrain in define"
        end
      when SetPowerExpr, SetVelocityExpr, StopExpr
        validate_motor!(program, expr.target)
      when SetPositionExpr
        validate_servo!(program, expr.target)
      end
    end
  end

  private def self.validate_motor!(program : Program, name : String)
    type = program.hardware[name]?
    unless type == "DcMotor" || type == "DcMotorEx"
      if type == "Servo"
        raise "[PARSER] '#{name}' is a servo — use set_position instead of motor methods"
      end
      raise "[PARSER] Unknown motor '#{name}' — declare it with dc \"#{name}\" in define"
    end
  end

  private def self.validate_servo!(program : Program, name : String)
    type = program.hardware[name]?
    unless type == "Servo"
      if type == "DcMotor" || type == "DcMotorEx"
        raise "[PARSER] '#{name}' is a motor — use set_power/set_velocity instead of set_position"
      end
      raise "[PARSER] Unknown servo '#{name}' — declare it with servo \"#{name}\" in define"
    end
  end
end
