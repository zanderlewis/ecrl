require "../parser/ast"
require "./formatter"

class AstWalker
  def self.walk_ast(expr : Expression, io : IO, indent : String, inline : Bool = false)
    case expr
    when DriveMecanumExpr
      g_y = expr.y.gsub("gpad.", "gamepad1.")
      g_x = expr.x.gsub("gpad.", "gamepad1.")
      g_rx = expr.rx.gsub("gpad.", "gamepad1.")
      io << (inline ? "" : indent) << "driveMecanum(-#{g_y}, #{g_x}, #{g_rx});\n"
    when SetPowerExpr
      target_val = expr.value.gsub("gpad.", "gamepad1.")
      io << (inline ? "" : indent) << "#{expr.target}Motor.setPower(#{target_val});\n"
    when SetVelocityExpr
      target_val = expr.value.gsub("gpad.", "gamepad1.")
      if tpr = expr.ticks_per_rev
        io << (inline ? "" : indent) << "#{expr.target}Motor.setVelocity(((#{target_val}) * #{tpr}) / 60.0);\n"
      else
        io << (inline ? "" : indent) << "#{expr.target}Motor.setVelocity(((#{target_val}) * SHOOTER_TICKS_PER_REV) / 60.0);\n"
      end
    when StopExpr
      io << (inline ? "" : indent) << "#{expr.target}Motor.setPower(0.0);\n"
    when VarReassignmentExpr
      io << (inline ? "" : indent) << "#{expr.var_name} = #{expr.value};\n"
    when TelemetryAddDataExpr
      args_str = expr.args.join(", ")
      if args_str.empty?
        io << (inline ? "" : indent) << "telemetry.addData(\"#{expr.label}\", \"\");\n"
      else
        io << (inline ? "" : indent) << "telemetry.addData(\"#{expr.label}\", #{args_str});\n"
      end
    when TelemetryUpdateExpr
      io << (inline ? "" : indent) << "telemetry.update();\n"
    when IfStatement
      g_cond = expr.condition_left.gsub("gpad.", "gamepad1.")

      io << (inline ? "" : indent)
      if op = expr.operator
        io << "if (#{g_cond} #{op} #{expr.condition_right}) {\n"
      else
        io << "if (#{g_cond}) {\n"
      end

      expr.then_branch.each { |child| walk_ast(child, io, indent + "\t", inline: false) }

      if !expr.else_branch.empty?
        if expr.else_branch.size == 1 && expr.else_branch.first.is_a?(IfStatement)
          io << indent << "} else "
          walk_ast(expr.else_branch.first, io, indent, inline: true)
        else
          io << indent << "} else {\n"
          expr.else_branch.each { |child| walk_ast(child, io, indent + "\t", inline: false) }
          io << indent << "}\n"
        end
      else
        io << indent << "}\n"
      end
    end
  end
end
