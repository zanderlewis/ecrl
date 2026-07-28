require "../parser/program"
require "./imports"
require "./members"
require "./hardware_init"
require "./emit/emitter"
require "./helpers/mecanum"
require "./helpers/deadzone"
require "./helpers/wait"
require "./helpers/routines"

class JavaCompiler
  LOOP_BODY_INDENT = "            "
  AUTO_BODY_INDENT = "        "

  def initialize(@program : Program, @package_name : String = @program.package)
  end

  def compile : String
    String.build do |io|
      CodegenImports.generate(io, @package_name, @program)
      CodegenImports.generate_class_header(io, @program)
      CodegenMembers.generate(io, @program)
      generate_run_op_mode_method(io)
      generate_helpers(io)
      io << "}\n"
    end
  end

  private def generate_run_op_mode_method(io : IO)
    io << "\n    @Override\n"
    io << "    public void runOpMode() {\n"

    HardwareInit.generate_chassis(io, @program) if !@program.chassis.empty?
    HardwareInit.generate_hardware(io, @program)
    HardwareInit.generate_variables(io, @program)

    io << "\n        waitForStart();\n\n"

    case @program.kind
    when OpModeKind::TeleOp
      io << "        while (opModeIsActive()) {\n"
      @program.body.each do |expr|
        Emitter.emit(expr, io, LOOP_BODY_INDENT, @program.hardware)
      end
      io << "        }\n"
    when OpModeKind::Autonomous
      @program.body.each do |expr|
        Emitter.emit(expr, io, AUTO_BODY_INDENT, @program.hardware)
      end
    end

    io << "    }\n"
  end

  private def generate_helpers(io : IO)
    needs_helpers = @program.uses_drive? || @program.uses_deadzone? || @program.uses_wait? || !@program.routines.empty?
    io << "\n" if needs_helpers

    MecanumSubroutine.generate(io) if @program.uses_drive?
    if @program.uses_deadzone?
      io << "\n" if @program.uses_drive?
      DeadzoneHelper.generate(io)
    end
    if @program.uses_wait?
      io << "\n" if @program.uses_drive? || @program.uses_deadzone?
      WaitHelper.generate(io)
    end
    RoutineEmitter.generate(io, @program)
  end
end
