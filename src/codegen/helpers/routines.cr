require "../../parser/program"
require "../../parser/ast/mod"
require "../emit/emitter"

module RoutineEmitter
  def self.generate(io : IO, program : Program)
    program.routines.each do |routine|
      params = routine.params.map { |p| "double #{p}" }.join(", ")
      io << "\n    private void #{routine.name}(#{params}) {\n"
      routine.body.each do |expr|
        Emitter.emit(expr, io, "        ", program.hardware)
      end
      io << "    }\n"
    end
  end
end
