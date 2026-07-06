require "../parser/ast"
require "./formatter"

class AstWalker
  def self.walk_ast(expr : Expression, io : IO, indent : String, inline : Bool = false)
    case expr
    when DriveMecanumExpr
      g_y = ValueFormatter.translate_gamepad(expr.y)
      g_x = ValueFormatter.translate_gamepad(expr.x)
      g_rx = ValueFormatter.translate_gamepad(expr.rx)
      io << (inline ? "" : indent) << "driveMecanum(-#{g_y}, #{g_x}, #{g_rx});\n"
    when SetPowerExpr
      field = ValueFormatter.motor_field(expr.target)
      target_val = ValueFormatter.translate_gamepad(expr.value)
      io << (inline ? "" : indent) << "#{field}.setPower(#{target_val});\n"
    when SetVelocityExpr
      field = ValueFormatter.motor_field(expr.target)
      target_val = ValueFormatter.translate_gamepad(expr.value)
      ticks = expr.ticks_per_rev
      if ticks.nil?
        raise "[CODEGEN] set_velocity requires a ticks-per-revolution argument for '#{expr.target}'"
      end
      io << (inline ? "" : indent) << "#{field}.setVelocity(((#{target_val}) * #{ticks}) / 60.0);\n"
    when StopExpr
      field = ValueFormatter.motor_field(expr.target)
      io << (inline ? "" : indent) << "#{field}.setPower(0.0);\n"
    when VarReassignmentExpr
      io << (inline ? "" : indent) << "#{expr.var_name} = #{expr.value};\n"
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
      g_cond = ValueFormatter.translate_gamepad(expr.condition_left)

      io << (inline ? "" : indent)
      if op = expr.operator
        io << "if (#{g_cond} #{op} #{expr.condition_right}) {\n"
      else
        io << "if (#{g_cond}) {\n"
      end

      expr.then_branch.each { |child| walk_ast(child, io, indent + "    ", inline: false) }

      if !expr.else_branch.empty?
        if expr.else_branch.size == 1 && expr.else_branch.first.is_a?(IfStatement)
          io << indent << "} else "
          walk_ast(expr.else_branch.first, io, indent, inline: true)
        else
          io << indent << "} else {\n"
          expr.else_branch.each { |child| walk_ast(child, io, indent + "    ", inline: false) }
          io << indent << "}\n"
        end
      else
        io << indent << "}\n"
      end
    end
  end
end
