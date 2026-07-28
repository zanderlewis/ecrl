require "../../parser/ast/mod"
require "./hardware"
require "./control"
require "./telemetry"
require "./vars"
require "./misc"

module Emitter
  def self.emit(
    expr : Expression,
    io : IO,
    indent : String,
    hardware : Hash(String, String),
    inline : Bool = false,
  )
    case expr
    when DriveMecanumExpr, SetPowerExpr, SetVelocityExpr, StopExpr, SetPositionExpr
      EmitHardware.emit(expr, io, indent, hardware, inline)
    when IfStatement
      emit_if(expr, io, indent, hardware, inline)
    when WhileStatement
      emit_while(expr, io, indent, hardware)
    when ForStatement
      emit_for(expr, io, indent, hardware)
    when WaitExpr
      EmitMisc.emit_wait(expr, io, indent, inline)
    when CallExpr
      EmitMisc.emit_call(expr, io, indent, inline)
    when TelemetryAddDataExpr, TelemetryUpdateExpr
      EmitTelemetry.emit(expr, io, indent, inline)
    when VarReassignmentExpr
      EmitVars.emit(expr, io, indent, inline)
    else
      raise "[CODEGEN] Unsupported expression type: #{expr.class}"
    end
  end

  private def self.emit_if(expr : IfStatement, io : IO, indent : String, hardware : Hash(String, String), inline : Bool)
    EmitControl.emit_if_header(expr, io, indent, inline)

    expr.then_branch.each { |child| emit(child, io, indent + "    ", hardware, inline: false) }

    if !expr.else_branch.empty?
      if expr.else_branch.size == 1 && expr.else_branch.first.is_a?(IfStatement)
        io << indent << "} else "
        emit(expr.else_branch.first, io, indent, hardware, inline: true)
      else
        io << indent << "} else {\n"
        expr.else_branch.each { |child| emit(child, io, indent + "    ", hardware, inline: false) }
        io << indent << "}\n"
      end
    else
      io << indent << "}\n"
    end
  end

  private def self.emit_while(expr : WhileStatement, io : IO, indent : String, hardware : Hash(String, String))
    EmitControl.emit_while_header(expr, io, indent)
    expr.body.each { |child| emit(child, io, indent + "    ", hardware, inline: false) }
    io << indent << "}\n"
  end

  private def self.emit_for(expr : ForStatement, io : IO, indent : String, hardware : Hash(String, String))
    EmitControl.emit_for_header(expr, io, indent)
    expr.body.each { |child| emit(child, io, indent + "    ", hardware, inline: false) }
    io << indent << "}\n"
  end
end

class AstWalker
  def self.walk_ast(
    expr : Expression,
    io : IO,
    indent : String,
    hardware : Hash(String, String),
    inline : Bool = false,
  )
    Emitter.emit(expr, io, indent, hardware, inline)
  end
end
