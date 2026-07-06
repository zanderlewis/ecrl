require "./spec_helper"

def parse_ecr(source : String) : Program
  Parser.new(Lexer.new(source).tokenize).parse_program
end

describe Parser do
  it "parses module name and teleop metadata" do
    program = parse_ecr(<<-'ECR')
      module "MyRobot"
      define { }
      teleop "Drive Mode" group "Main" {
        loop { }
      }
    ECR

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
      define { dc "intake" }
      teleop "Test" {
        loop {
          drive(gpad.left_stick_y, gpad.left_stick_x, gpad.right_stick_x)
          robot.intake.set_power(1.0)
          robot.intake.stop()
        }
      }
    ECR

    body = program.body
    body.size.should eq(3)

    drive = body[0].as(DriveMecanumExpr)
    drive.y.should eq("gpad.left_stick_y")

    set_power = body[1].as(SetPowerExpr)
    set_power.target.should eq("intake")
    set_power.value.should eq("1.0")

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
end

describe TelemetryInterpolatedString do
  it "builds segments from lexer encoding" do
    interpolated = TelemetryInterpolatedString.from_lexer("prefix\0expr\0suffix")
    interpolated.segments.map(&.value).should eq(["prefix", "expr", "suffix"])
    interpolated.segments.map(&.literal).should eq([true, false, true])
  end
end
