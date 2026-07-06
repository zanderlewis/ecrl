require "../parser/ast"
require "../parser/types"
require "./formatter"
require "./ast_walker"
require "./subroutines"

class JavaCompiler
  LOOP_BODY_INDENT = "            "

  def initialize(@program : Program)
  end

  def compile : String
    String.build do |io|
      generate_package_and_imports(io)
      generate_class_header(io)
      generate_member_declarations(io)
      generate_run_op_mode_method(io)
      generate_subroutines(io)
      io << "}\n"
    end
  end

  private def generate_package_and_imports(io : IO)
    io << "package org.firstinspires.ftc.teamcode.teleop;\n\n"
    io << "import com.qualcomm.robotcore.eventloop.opmode.TeleOp;\n"
    io << "import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;\n"
    io << "import com.qualcomm.robotcore.hardware.DcMotor;\n"
    io << "import com.qualcomm.robotcore.hardware.DcMotorEx;\n\n"
  end

  private def generate_class_header(io : IO)
    io << "@TeleOp(name=\"#{@program.name}\", group=\"#{@program.group}\")\n"
    io << "public class #{@program.module_name} extends LinearOpMode {\n\n"
  end

  private def generate_member_declarations(io : IO)
    @program.vars.each do |var_name, variable|
      java_type = ValueFormatter.get_java_type(variable.value)
      io << "    private #{java_type} #{var_name};\n"
    end

    if !@program.chassis.empty?
      io << "    private DcMotor leftFront, rightFront, leftBack, rightBack;\n"
    end

    @program.hardware.each do |name, type|
      io << "    private #{type} #{ValueFormatter.motor_field(name)};\n"
    end
  end

  private def generate_run_op_mode_method(io : IO)
    io << "\n    @Override\n"
    io << "    public void runOpMode() {\n"

    generate_chassis_initialization(io) if !@program.chassis.empty?
    generate_hardware_initialization(io)
    generate_variable_initialization(io)

    io << "\n        waitForStart();\n\n"
    io << "        while (opModeIsActive()) {\n"

    @program.body.each do |expr|
      AstWalker.walk_ast(expr, io, LOOP_BODY_INDENT)
    end

    io << "        }\n"
    io << "    }\n\n"
  end

  private def generate_chassis_initialization(io : IO)
    fl = @program.chassis["fl"]
    fr = @program.chassis["fr"]
    bl = @program.chassis["bl"]
    br = @program.chassis["br"]

    io << "        leftFront  = hardwareMap.get(DcMotor.class, \"#{fl.not_nil!.name}\");\n"
    io << "        rightFront = hardwareMap.get(DcMotor.class, \"#{fr.not_nil!.name}\");\n"
    io << "        leftBack   = hardwareMap.get(DcMotor.class, \"#{bl.not_nil!.name}\");\n"
    io << "        rightBack  = hardwareMap.get(DcMotor.class, \"#{br.not_nil!.name}\");\n\n"

    io << "        leftFront.setDirection(DcMotor.Direction.#{fl.not_nil!.direction});\n"
    io << "        rightFront.setDirection(DcMotor.Direction.#{fr.not_nil!.direction});\n"
    io << "        leftBack.setDirection(DcMotor.Direction.#{bl.not_nil!.direction});\n"
    io << "        rightBack.setDirection(DcMotor.Direction.#{br.not_nil!.direction});\n\n"
  end

  private def generate_hardware_initialization(io : IO)
    @program.hardware.each do |name, type|
      field = ValueFormatter.motor_field(name)
      io << "        #{field} = hardwareMap.get(#{type}.class, \"#{name}\");\n"
      if type == "DcMotorEx"
        io << "        #{field}.setMode(DcMotor.RunMode.RUN_USING_ENCODER);\n"
      end
    end
  end

  private def generate_variable_initialization(io : IO)
    @program.vars.each do |var_name, variable|
      io << "        #{var_name} = #{ValueFormatter.format_value(variable.value)};\n"
    end
  end

  private def generate_subroutines(io : IO)
    MecanumSubroutine.generate(io)
  end
end
