require "./spec_helper"

def compile_ecr(source : String) : String
  program = Parser.new(Lexer.new(source).tokenize).parse_program
  JavaCompiler.new(program).compile
end

describe ValueFormatter do
  it "formats telemetry string literals" do
    value = TelemetryStringLiteral.new("hello")
    ValueFormatter.format_telemetry_value(value).should eq("\"hello\"")
  end

  it "formats interpolated strings as Java concatenation" do
    segments = [
      InterpolatedSegment.new(literal: true, value: "Intake: "),
      InterpolatedSegment.new(literal: false, value: "intake_power"),
    ]
    value = TelemetryInterpolatedString.new(segments)
    ValueFormatter.format_telemetry_value(value).should eq("\"Intake: \" + intake_power")
  end

  it "uses consistent motor field names" do
    ValueFormatter.motor_field("intake").should eq("ecrl__intakeMotor")
  end

  it "translates gamepad references" do
    ValueFormatter.translate_gamepad("gpad.square").should eq("gamepad1.square")
  end
end

describe JavaCompiler do
  it "generates matching motor declarations and usage" do
    output = compile_ecr(<<-'ECR')
      define { dc "intake" }
      teleop "Test" {
        loop {
          robot.intake.set_power(1.0)
        }
      }
    ECR

    output.should contain("private DcMotor ecrl__intakeMotor")
    output.should contain("ecrl__intakeMotor.setPower(1.0)")
  end

  it "generates interpolated telemetry via codegen" do
    output = compile_ecr(<<-'ECR')
      define { var intake_power = 1.0 }
      teleop "Test" {
        loop {
          robot.tel.show("Status", "Intake: #{intake_power}")
        }
      }
    ECR

    output.should contain("telemetry.addData(\"Status\", \"Intake: \" + intake_power)")
  end

  it "compiles the example program end-to-end" do
    example = File.read("examples/limelightrobotics_2025remake.ecr")
    output = compile_ecr(example)

    output.should contain("public class ManualDrive extends LinearOpMode")
    output.should contain("ecrl__shooterMotor.setVelocity(((target_velocity) * shooter_ticks) / 60.0)")
    output.should contain("driveMecanum(-gamepad1.left_stick_y, gamepad1.left_stick_x, gamepad1.right_stick_x)")
  end

  it "requires ticks_per_rev for set_velocity" do
    expect_raises(Exception, /ticks-per-revolution/) do
      compile_ecr(<<-'ECR')
        define { dc "shooter" }
        teleop "Test" {
          loop {
            robot.shooter.set_velocity(6000.0)
          }
        }
      ECR
    end
  end
end
