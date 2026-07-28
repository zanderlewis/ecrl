require "../../parser/ast/mod"
require "../../parser/program"

module FormatValue
  def self.get_java_type(value : String | Int64 | Float64) : String
    case value
    when String  then "String"
    when Int64   then "int"
    when Float64 then "double"
    else            raise "[CODEGEN] Unsupported variable type: #{value.class}"
    end
  end

  def self.format_value(value : String | Int64 | Float64) : String
    case value
    when String then "\"#{value}\""
    else             value.to_s
    end
  end

  def self.hardware_field(name : String, type : String) : String
    suffix = type == "Servo" ? "Servo" : "Motor"
    "ecrl__#{name}#{suffix}"
  end

  def self.motor_field(name : String) : String
    hardware_field(name, "DcMotor")
  end

  def self.translate_gamepad(expr : String) : String
    expr.gsub("gpad2.", "gamepad2.").gsub("gpad1.", "gamepad1.")
  end

  def self.format_value_expr(expr : ValueExpr) : String
    case expr
    when NumberValueExpr
      expr.value
    when IdentifierValueExpr
      translate_gamepad(expr.name)
    when NegatedValueExpr
      "-#{format_value_expr(expr.inner)}"
    when BinaryValueExpr
      "(#{format_value_expr(expr.left)} #{expr.operator} #{format_value_expr(expr.right)})"
    when DeadzoneValueExpr
      "deadzone(#{format_value_expr(expr.value)}, #{format_value_expr(expr.threshold)})"
    else
      raise "[CODEGEN] Unsupported value expression type: #{expr.class}"
    end
  end

  def self.java_type_for_init(expr : ValueExpr) : String
    case expr
    when NumberValueExpr
      expr.value.includes?('.') ? "double" : "int"
    else
      "double"
    end
  end
end
