require "../parser/ast"
require "./formatter"

class AstWalker
  def self.walk_ast(
    expr : Expression,
    io : IO,
    indent : String,
    hardware : Hash(String, String),
    inline : Bool = false,
  )
    case expr
    when DriveMecanumExpr
      g_y = ValueFormatter.format_value_expr(expr.y)
      g_x = ValueFormatter.format_value_expr(expr.x)
      g_rx = ValueFormatter.format_value_expr(expr.rx)
      io << (inline ? "" : indent) << "driveMecanum(-#{g_y}, #{g_x}, #{g_rx});\n"
    when SetPowerExpr
      field = ValueFormatter.hardware_field(expr.target, hardware[expr.target].not_nil!)
      target_val = ValueFormatter.format_value_expr(expr.value)
      io << (inline ? "" : indent) << "#{field}.setPower(#{target_val});\n"
    when SetVelocityExpr
      field = ValueFormatter.hardware_field(expr.target, hardware[expr.target].not_nil!)
      target_val = ValueFormatter.format_value_expr(expr.value)
      ticks = expr.ticks_per_rev
      if ticks.nil?
        raise "[CODEGEN] set_velocity requires a ticks-per-revolution argument for '#{expr.target}'"
      end
      ticks_val = ValueFormatter.format_value_expr(ticks)
      io << (inline ? "" : indent) << "#{field}.setVelocity(((#{target_val}) * #{ticks_val}) / 60.0);\n"
    when StopExpr
      field = ValueFormatter.hardware_field(expr.target, hardware[expr.target].not_nil!)
      if hardware[expr.target] == "DcMotorEx"
        io << (inline ? "" : indent) << "#{field}.setVelocity(0);\n"
      else
        io << (inline ? "" : indent) << "#{field}.setPower(0.0);\n"
      end
    when SetPositionExpr
      field = ValueFormatter.hardware_field(expr.target, "Servo")
      position = ValueFormatter.format_value_expr(expr.value)
      io << (inline ? "" : indent) << "#{field}.setPosition(#{position});\n"
    when VarReassignmentExpr
      value = ValueFormatter.format_value_expr(expr.value)
      io << (inline ? "" : indent) << "#{expr.var_name} = #{value};\n"
    when TelemetryAddDataExpr
      args_str = expr.args.map { |arg| ValueFormatter.format_telemetry_value(arg) }.join(", ")
      if args_str.empty?
        io << (inline ? "" : indent) << "telemetry.addData(\"#{expr.label}\", \"\");\n"
      else
        io << (inline ? "" : indent) << "telemetry.addData(\"#{expr.label}\", #{args_str});\n"
      end
    when TelemetryUpdateExpr
      io << (inline ? "" : indent) << "telemetry.update();\n"
    when IfStatement
      cond = ValueFormatter.format_condition(expr.condition)

      io << (inline ? "" : indent) << "if (#{cond}) {\n"

      expr.then_branch.each { |child| walk_ast(child, io, indent + "    ", hardware, inline: false) }

      if !expr.else_branch.empty?
        if expr.else_branch.size == 1 && expr.else_branch.first.is_a?(IfStatement)
          io << indent << "} else "
          walk_ast(expr.else_branch.first, io, indent, hardware, inline: true)
        else
          io << indent << "} else {\n"
          expr.else_branch.each { |child| walk_ast(child, io, indent + "    ", hardware, inline: false) }
          io << indent << "}\n"
        end
      else
        io << indent << "}\n"
      end
    else
      raise "[CODEGEN] Unsupported expression type: #{expr.class}"
    end
  end
end
