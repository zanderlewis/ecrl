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

An ECRL program has three main sections:

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

teleop "Drive Mode" group "Main" {
    loop {
        drive(gpad1.left_stick_y, gpad1.left_stick_x, gpad1.right_stick_x)

        if gpad1.square && gpad2.triangle {
            robot.intake.set_power(speed)
        } else if gpad1.right_trigger >= 0.5 {
            robot.intake.stop()
        }

        robot.wrist.set_position(0.5)
        robot.tel.show("Speed", "Target: #{speed}")
        robot.tel.update()
    }
}
```

- `!` starts a line comment
- `package` sets the generated Java package (default: `org.firstinspires.ftc.teamcode.teleop`)
- `module` sets the generated Java class name
- `define` declares hardware, variables, and the mecanum drivetrain
- `teleop` defines the FTC `@TeleOp` name, group, and main loop
- `gpad1.*` maps to `gamepad1.*`; `gpad2.*` maps to `gamepad2.*`
- `dc` declares motors; `servo` declares servos
- `if` supports comparisons (`>`, `<`, `>=`, `<=`, `==`, `!=`), `&&`, and `||`
- `robot.<device>.set_power/set_velocity/stop` controls motors; `set_position` controls servos
- `robot.tel.show/update` handles telemetry

## Examples

- [Limelight Robotics #23574 2025-2026 TeamCode re-creation](examples/limelightrobotics_2025remake.ecr) — full competition-style teleop with multiple motors
- [Dual driver arm](examples/dual_driver_arm.ecr) — two-gamepad setup with servos, compound conditions, and runtime variable changes

Compile an example with:

```bash
just buildrun examples/dual_driver_arm.ecr
```

Or the Limelight example:

```bash
just buildrun examples/limelightrobotics_2025remake.ecr
```

## Contributing

ECRL is open to contributions! To contribute, follow these steps:

1. Fork the repository here: [https://codeberg.org/zanderlewis/ecrl](https://codeberg.org/zanderlewis/ecrl)
2. Create a new branch: `git switch -c my-awesome-new-feature`
3. Make your changes and run `just test`
4. Commit and submit a pull request describing your changes
