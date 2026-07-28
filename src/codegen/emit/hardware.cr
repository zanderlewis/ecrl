require "../../parser/ast/mod"
require "../format/value"

module EmitHardware
  def self.emit(expr : Expression, io : IO, indent : String, hardware : Hash(String, String), inline : Bool)
    case expr
    when DriveMecanumExpr
      g_y = FormatValue.format_value_expr(expr.y)
      g_x = FormatValue.format_value_expr(expr.x)
      g_rx = FormatValue.format_value_expr(expr.rx)
      io << (inline ? "" : indent) << "driveMecanum(-#{g_y}, #{g_x}, #{g_rx});\n"
    when SetPowerExpr
      field = FormatValue.hardware_field(expr.target, hardware[expr.target].not_nil!)
      target_val = FormatValue.format_value_expr(expr.value)
      io << (inline ? "" : indent) << "#{field}.setPower(#{target_val});\n"
    when SetVelocityExpr
      field = FormatValue.hardware_field(expr.target, hardware[expr.target].not_nil!)
      target_val = FormatValue.format_value_expr(expr.value)
      ticks = expr.ticks_per_rev
      if ticks.nil?
        raise "[CODEGEN] set_velocity requires a ticks-per-revolution argument for '#{expr.target}'"
      end
      ticks_val = FormatValue.format_value_expr(ticks)
      io << (inline ? "" : indent) << "#{field}.setVelocity(((#{target_val}) * #{ticks_val}) / 60.0);\n"
    when StopExpr
      field = FormatValue.hardware_field(expr.target, hardware[expr.target].not_nil!)
      if hardware[expr.target] == "DcMotorEx"
        io << (inline ? "" : indent) << "#{field}.setVelocity(0);\n"
      else
        io << (inline ? "" : indent) << "#{field}.setPower(0.0);\n"
      end
    when SetPositionExpr
      field = FormatValue.hardware_field(expr.target, "Servo")
      position = FormatValue.format_value_expr(expr.value)
      io << (inline ? "" : indent) << "#{field}.setPosition(#{position});\n"
    else
      raise "[CODEGEN] Not a hardware expression: #{expr.class}"
    end
  end
end
