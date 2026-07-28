require "../parser/program"

module CodegenImports
  def self.generate(io : IO, package_name : String, program : Program)
    uses_servos = program.hardware.values.includes?("Servo")
    io << "package #{package_name};\n\n"
    case program.kind
    when OpModeKind::TeleOp
      io << "import com.qualcomm.robotcore.eventloop.opmode.TeleOp;\n"
    when OpModeKind::Autonomous
      io << "import com.qualcomm.robotcore.eventloop.opmode.Autonomous;\n"
    end
    io << "import com.qualcomm.robotcore.eventloop.opmode.LinearOpMode;\n"
    io << "import com.qualcomm.robotcore.hardware.DcMotor;\n"
    io << "import com.qualcomm.robotcore.hardware.DcMotorEx;\n"
    io << "import com.qualcomm.robotcore.hardware.Servo;\n" if uses_servos
    io << "\n"
  end

  def self.generate_class_header(io : IO, program : Program)
    case program.kind
    when OpModeKind::TeleOp
      io << "@TeleOp(name=\"#{program.name}\", group=\"#{program.group}\")\n"
    when OpModeKind::Autonomous
      io << "@Autonomous(name=\"#{program.name}\", group=\"#{program.group}\")\n"
    end
    io << "public class #{program.module_name} extends LinearOpMode {\n\n"
  end
end
