require "./spec_helper"

def parse_ecr(source : String) : Program
  Parser.new(Lexer.new(source).tokenize).parse_program
end

describe Parser do
  it "parses module name and teleop metadata" do
    program = parse_ecr(<<-'ECR')
      package "com.myteam.teleop"
      module "MyRobot"
      define { }
      teleop "Drive Mode" group "Main" {
        loop { }
      }
    ECR

    program.package.should eq("com.myteam.teleop")
    program.module_name.should eq("MyRobot")
    program.name.should eq("Drive Mode")
    program.group.should eq("Main")
  end

  it "parses define block hardware and variables" do
    program = parse_ecr(<<-'ECR')
      define {
        drivetrain {
          fl: "leftFront"  FORWARD
          fr: "rightFront" REVERSE
          bl: "leftBack"   FORWARD
          br: "rightBack"  FORWARD
        }
        var speed = 1.0
        dc "intake"
      }
      teleop "Test" {
        loop { }
      }
    ECR

    program.chassis["fl"].not_nil!.name.should eq("leftFront")
    program.chassis["fr"].not_nil!.direction.should eq("REVERSE")
    program.vars["speed"].not_nil!.value.should eq(1.0)
    program.hardware["intake"].should eq("DcMotor")
  end

  it "parses drive and motor statements" do
    program = parse_ecr(<<-'ECR')
      define {
        drivetrain {
          fl: "leftFront"  FORWARD
          fr: "rightFront" REVERSE
          bl: "leftBack"   FORWARD
          br: "rightBack"  FORWARD
        }
        dc "intake"
      }
      teleop "Test" {
        loop {
          drive(gpad1.left_stick_y, gpad1.left_stick_x, gpad1.right_stick_x)
          robot.intake.set_power(1.0)
          robot.intake.stop()
        }
      }
    ECR

    body = program.body
    body.size.should eq(3)

    drive = body[0].as(DriveMecanumExpr)
    drive.y.as(IdentifierValueExpr).name.should eq("gpad1.left_stick_y")

    set_power = body[1].as(SetPowerExpr)
    set_power.target.should eq("intake")
    set_power.value.as(NumberValueExpr).value.should eq("1.0")

    body[2].should be_a(StopExpr)
  end

  it "parses interpolated telemetry into AST values" do
    program = parse_ecr(<<-'ECR')
      define { var intake_power = 1.0 }
      teleop "Test" {
        loop {
          robot.tel.show("Status", "Intake: #{intake_power}")
        }
      }
    ECR

    telemetry = program.body[0].as(TelemetryAddDataExpr)
    telemetry.label.should eq("Status")
    telemetry.args.size.should eq(1)

    interpolated = telemetry.args[0].as(TelemetryInterpolatedString)
    interpolated.segments.size.should eq(2)
    interpolated.segments[0].literal.should be_true
    interpolated.segments[0].value.should eq("Intake: ")
    interpolated.segments[1].literal.should be_false
    interpolated.segments[1].value.should eq("intake_power")
  end

  it "rejects incomplete drivetrain configuration" do
    expect_raises(Exception, /missing required wheel keys/) do
      parse_ecr(<<-'ECR')
        define {
          drivetrain {
            fl: "leftFront" FORWARD
          }
        }
        teleop "Test" {
          loop { }
        }
      ECR
    end
  end

  it "rejects unexpected tokens at program level" do
    expect_raises(Exception, /Unexpected token/) do
      parse_ecr("typo")
    end
  end

  it "rejects undeclared motor devices" do
    expect_raises(Exception, /Unknown motor 'intake'/) do
      parse_ecr(<<-'ECR')
        define { }
        teleop "Test" {
          loop {
            robot.intake.set_power(1.0)
          }
        }
      ECR
    end
  end

  it "rejects drive without a drivetrain" do
    expect_raises(Exception, /drive\(\) requires a drivetrain/) do
      parse_ecr(<<-'ECR')
        define { }
        teleop "Test" {
          loop {
            drive(gpad1.left_stick_y, gpad1.left_stick_x, gpad1.right_stick_x)
          }
        }
      ECR
    end
  end

  it "rejects duplicate dc motor declarations" do
    expect_raises(Exception, /Duplicate dc motor/) do
      parse_ecr(<<-'ECR')
        define {
          dc "intake"
          dc "intake"
        }
        teleop "Test" {
          loop { }
        }
      ECR
    end
  end

  it "rejects invalid package names" do
    expect_raises(Exception, /Invalid Java package name/) do
      parse_ecr(<<-'ECR')
        package "not a valid package"
        teleop "Test" {
          loop { }
        }
      ECR
    end
  end

  it "upgrades motors to DcMotorEx when set_velocity is used" do
    program = parse_ecr(<<-'ECR')
      define { dc "shooter" }
      teleop "Test" {
        loop {
          robot.shooter.set_velocity(6000.0, 28.0)
        }
      }
    ECR

    program.hardware["shooter"].should eq("DcMotorEx")
  end

  it "parses compound if conditions" do
    program = parse_ecr(<<-'ECR')
      define { var threshold = 0.5 }
      teleop "Test" {
        loop {
          if gpad1.right_trigger > threshold && gpad2.square {
            robot.tel.update()
          }
        }
      }
    ECR

    if_stmt = program.body[0].as(IfStatement)
    and_cond = if_stmt.condition.as(AndCondition)
    comparison = and_cond.left.as(ComparisonCondition)
    comparison.operator.should eq(">")
    comparison.right.as(IdentifierValueExpr).name.should eq("threshold")
    and_cond.right.as(ValueCondition).value.as(IdentifierValueExpr).name.should eq("gpad2.square")
  end

  it "parses servo declarations and set_position" do
    program = parse_ecr(<<-'ECR')
      define { servo "wrist" }
      teleop "Test" {
        loop {
          robot.wrist.set_position(0.5)
        }
      }
    ECR

    program.hardware["wrist"].should eq("Servo")
    set_pos = program.body[0].as(SetPositionExpr)
    set_pos.target.should eq("wrist")
    set_pos.value.as(NumberValueExpr).value.should eq("0.5")
  end

  it "rejects motor methods on servos" do
    expect_raises(Exception, /is a servo/) do
      parse_ecr(<<-'ECR')
        define { servo "wrist" }
        teleop "Test" {
          loop {
            robot.wrist.set_power(1.0)
          }
        }
      ECR
    end
  end
end

describe TelemetryInterpolatedString do
  it "builds segments from lexer encoding" do
    interpolated = TelemetryInterpolatedString.from_lexer("prefix\0expr\0suffix")
    interpolated.segments.map(&.value).should eq(["prefix", "expr", "suffix"])
    interpolated.segments.map(&.literal).should eq([true, false, true])
  end
end
