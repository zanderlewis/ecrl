require "./spec_helper"

def compile_ecr(source : String, package : String? = nil) : String
  program = Parser.new(Lexer.new(source).tokenize).parse_program
  JavaCompiler.new(program, package || program.package).compile
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
    ValueFormatter.translate_gamepad("gpad2.square").should eq("gamepad2.square")
  end

  it "formats compound conditions" do
    cond = AndCondition.new(
      ComparisonCondition.new(
        IdentifierValueExpr.new("gpad.right_trigger"),
        ">",
        NumberValueExpr.new("0.5"),
      ),
      ValueCondition.new(IdentifierValueExpr.new("gpad.square")),
    )
    ValueFormatter.format_condition(cond).should eq("(gamepad1.right_trigger > 0.5 && gamepad1.square)")
  end

  it "formats value expressions" do
    ValueFormatter.format_value_expr(IdentifierValueExpr.new("gpad.square")).should eq("gamepad1.square")
    ValueFormatter.format_value_expr(NumberValueExpr.new("1.0")).should eq("1.0")
    ValueFormatter.format_value_expr(
      NegatedValueExpr.new(IdentifierValueExpr.new("intake_power"))
    ).should eq("-intake_power")
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

  it "uses the default Java package" do
    output = compile_ecr(<<-'ECR')
      define { dc "intake" }
      teleop "Test" {
        loop {
          robot.intake.set_power(1.0)
        }
      }
    ECR

    output.should contain("package org.firstinspires.ftc.teamcode.teleop;")
  end

  it "uses a custom package from source" do
    output = compile_ecr(<<-'ECR')
      package "com.myteam.teleop"
      define { dc "intake" }
      teleop "Test" {
        loop {
          robot.intake.set_power(1.0)
        }
      }
    ECR

    output.should contain("package com.myteam.teleop;")
  end

  it "allows the compiler package to override the source package" do
    source = <<-ECR
      package "com.myteam.teleop"
      define { dc "intake" }
      teleop "Test" {
        loop {
          robot.intake.set_power(1.0)
        }
      }
    ECR
    output = compile_ecr(source, "com.override.teleop")

    output.should contain("package com.override.teleop;")
  end

  it "omits driveMecanum when drive is not used" do
    output = compile_ecr(<<-'ECR')
      define { dc "intake" }
      teleop "Test" {
        loop {
          robot.intake.set_power(1.0)
        }
      }
    ECR

    output.should_not contain("private void driveMecanum")
  end

  it "includes driveMecanum when drive is used" do
    output = compile_ecr(<<-'ECR')
      define {
        drivetrain {
          fl: "leftFront"  FORWARD
          fr: "rightFront" REVERSE
          bl: "leftBack"   FORWARD
          br: "rightBack"  FORWARD
        }
      }
      teleop "Test" {
        loop {
          drive(gpad.left_stick_y, gpad.left_stick_x, gpad.right_stick_x)
        }
      }
    ECR

    output.should contain("private void driveMecanum")
  end

  it "uses setVelocity(0) to stop encoder motors" do
    output = compile_ecr(<<-'ECR')
      define { dc "shooter" }
      teleop "Test" {
        loop {
          robot.shooter.set_velocity(6000.0, 28.0)
          robot.shooter.stop()
        }
      }
    ECR

    output.should contain("ecrl__shooterMotor.setVelocity(0);")
    output.should_not contain("ecrl__shooterMotor.setPower(0.0);")
  end

  it "uses setPower(0) to stop regular motors" do
    output = compile_ecr(<<-'ECR')
      define { dc "intake" }
      teleop "Test" {
        loop {
          robot.intake.stop()
        }
      }
    ECR

    output.should contain("ecrl__intakeMotor.setPower(0.0);")
  end

  it "generates servo declarations and setPosition calls" do
    output = compile_ecr(<<-'ECR')
      define { servo "wrist" }
      teleop "Test" {
        loop {
          robot.wrist.set_position(0.75)
        }
      }
    ECR

    output.should contain("import com.qualcomm.robotcore.hardware.Servo;")
    output.should contain("private Servo ecrl__wristServo;")
    output.should contain("ecrl__wristServo.setPosition(0.75);")
  end

  it "generates compound if conditions" do
    output = compile_ecr(<<-'ECR')
      define { }
      teleop "Test" {
        loop {
          if gpad.a && gpad.b || gpad.c > 0.5 {
            robot.tel.update()
          }
        }
      }
    ECR

    output.should contain("if (((gamepad1.a && gamepad1.b) || gamepad1.c > 0.5)) {")
  end
end
