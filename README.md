# Enka-Candler Robotics Language

The Enka-Candler Robotics Language (ECRL, pronounced `eck-ruhl`) is a language that compiles to Java and the FTC SDK. Because it compiles to the FTC SDK, this language is meant for FTC teams.

## Official Locations

These are official locations of ECRL. It is recommended to only get ECRL from these locations.

- [Codeberg](https://codeberg.org/zanderlewis/ecrl) - Main Repository
- [Github](https://github.com/zanderlewis/ecrl) - Mirror Repository

## Getting Started

### Prerequisites

- [Crystal](https://crystal-lang.org/) 1.0 or newer
- [just](https://github.com/casey/just) (optional, but recommended)

### Build the compiler

```bash
just build
```

This produces the `ecrl` binary at `bin/ecrl`.

### Compile an ECRL program

```bash
just run path/to/program.ecr
```

This writes Java output to `path/to/program.ecr.java`. You can also invoke the compiler directly:

```bash
./bin/ecrl -s path/to/program.ecr -o path/to/output.java
./bin/ecrl -s path/to/program.ecr -o path/to/output.java -p com.myteam.teleop
```

The `-p` / `--package` flag overrides any `package` directive in the source file.

### Run tests

```bash
just test
```

## Language Overview

An ECRL program has a `define` block, optional `routine`s, and **exactly one** OpMode (`teleop` or `autonomous`):

```ecr
package "org.firstinspires.ftc.teamcode.teleop"
module "MyRobot"

define {
    drivetrain {
        fl: "leftFront"  FORWARD
        fr: "rightFront" REVERSE
        bl: "leftBack"   FORWARD
        br: "rightBack"  FORWARD
    }

    var speed = 1.0
    dc "intake"
    servo "wrist"
}

routine pulse_intake(power) {
    robot.intake.set_power(power)
    wait(0.5)
    robot.intake.stop()
}

teleop "Drive Mode" group "Main" {
    loop {
        drive(
            deadzone(gpad1.left_stick_y, 0.05),
            deadzone(gpad1.left_stick_x, 0.05),
            deadzone(gpad1.right_stick_x, 0.05)
        )

        if gpad1.square && gpad2.triangle {
            robot.intake.set_power(speed * 0.5)
        } else if gpad1.right_trigger >= 0.5 {
            robot.intake.stop()
        }

        while gpad1.dpad_up {
            pulse_intake(1.0)
        }

        robot.wrist.set_position(0.5)
        robot.tel.show("Speed", "Target: #{speed}")
        robot.tel.update()
    }
}
```

Autonomous programs use a sequential body (no outer `loop`):

```ecr
package "org.firstinspires.ftc.teamcode.auto"
module "RedAuto"

define {
    drivetrain {
        fl: "lf" FORWARD
        fr: "rf" REVERSE
        bl: "lb" FORWARD
        br: "rb" FORWARD
    }
    dc "intake"
}

autonomous "Red Auto" group "Auto" {
    drive(0.5, 0.0, 0.0)
    wait(1.5)
    drive(0.0, 0.0, 0.0)

    for i = 0; i < 3; i = i + 1 {
        wait(0.25)
    }
}
```

### Features

- `!` starts a line comment
- `package` sets the generated Java package (default: `org.firstinspires.ftc.teamcode.teleop`)
- `module` sets the generated Java class name
- `define` declares hardware, variables, and the mecanum drivetrain
- `teleop` / `autonomous` — exactly one OpMode per file (`@TeleOp` or `@Autonomous`)
- `routine name(params) { ... }` — reusable void helpers; call with `name(args)`
- `gpad1.*` maps to `gamepad1.*`; `gpad2.*` maps to `gamepad2.*`
- Arithmetic in values: `+`, `-`, `*`, `/`, parentheses, unary `-`
- `while cond { }` and `for i = init; cond; i = step { }`
- `wait(seconds)` — interruptible delay (`waitSeconds` helper)
- `deadzone(value, threshold)` — builtin stick deadzone helper
- `dc` / `servo` declare motors and servos
- `if` supports comparisons (`>`, `<`, `>=`, `<=`, `==`, `!=`), `&&`, and `||`
- `robot.<device>.set_power/set_velocity/stop` controls motors; `set_position` controls servos
- `robot.tel.show/update` handles telemetry

## Examples

- [Limelight Robotics #23574 2025-2026 TeamCode re-creation](examples/limelightrobotics_2025remake.ecr) — full competition-style teleop with multiple motors
- [Dual driver arm](examples/dual_driver_arm.ecr) — two-gamepad setup with servos, deadzone, and compound conditions
- [Simple auto](examples/simple_auto.ecr) — autonomous with routines, `wait`, and `for`

Compile an example with:

```bash
just buildrun examples/dual_driver_arm.ecr
```

Or the autonomous example:

```bash
just buildrun examples/simple_auto.ecr
```

## Contributing

ECRL is open to contributions! To contribute, follow these steps:

1. Fork the repository here: [https://codeberg.org/zanderlewis/ecrl](https://codeberg.org/zanderlewis/ecrl)
2. Create a new branch: `git switch -c my-awesome-new-feature`
3. Make your changes and run `just test`
4. Commit and submit a pull request describing your changes
