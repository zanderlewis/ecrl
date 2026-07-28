require "../parser/program"
require "./format/value"

module HardwareInit
  def self.generate_chassis(io : IO, program : Program)
    fl = program.chassis["fl"]
    fr = program.chassis["fr"]
    bl = program.chassis["bl"]
    br = program.chassis["br"]

    io << "        leftFront  = hardwareMap.get(DcMotor.class, \"#{fl.not_nil!.name}\");\n"
    io << "        rightFront = hardwareMap.get(DcMotor.class, \"#{fr.not_nil!.name}\");\n"
    io << "        leftBack   = hardwareMap.get(DcMotor.class, \"#{bl.not_nil!.name}\");\n"
    io << "        rightBack  = hardwareMap.get(DcMotor.class, \"#{br.not_nil!.name}\");\n\n"

    io << "        leftFront.setDirection(DcMotor.Direction.#{fl.not_nil!.direction});\n"
    io << "        rightFront.setDirection(DcMotor.Direction.#{fr.not_nil!.direction});\n"
    io << "        leftBack.setDirection(DcMotor.Direction.#{bl.not_nil!.direction});\n"
    io << "        rightBack.setDirection(DcMotor.Direction.#{br.not_nil!.direction});\n\n"
  end

  def self.generate_hardware(io : IO, program : Program)
    program.hardware.each do |name, type|
      field = FormatValue.hardware_field(name, type)
      io << "        #{field} = hardwareMap.get(#{type}.class, \"#{name}\");\n"
      if type == "DcMotorEx"
        io << "        #{field}.setMode(DcMotor.RunMode.RUN_USING_ENCODER);\n"
      end
    end
  end

  def self.generate_variables(io : IO, program : Program)
    program.vars.each do |var_name, variable|
      io << "        #{var_name} = #{FormatValue.format_value(variable.value)};\n"
    end
  end
end
