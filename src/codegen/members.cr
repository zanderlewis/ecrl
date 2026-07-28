require "../parser/program"
require "./format/value"

module CodegenMembers
  def self.generate(io : IO, program : Program)
    program.vars.each do |var_name, variable|
      java_type = FormatValue.get_java_type(variable.value)
      io << "    private #{java_type} #{var_name};\n"
    end

    if !program.chassis.empty?
      io << "    private DcMotor leftFront, rightFront, leftBack, rightBack;\n"
    end

    program.hardware.each do |name, type|
      io << "    private #{type} #{FormatValue.hardware_field(name, type)};\n"
    end
  end
end
