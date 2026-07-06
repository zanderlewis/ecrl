require "./ast"

record ChassisWheel,
  name : String,
  direction : String

record Variable,
  id : String,
  value : String | Int64 | Float64

record Program,
  module_name : String,
  hardware : Hash(String, String),
  chassis : Hash(String, ChassisWheel),
  vars : Hash(String, Variable),
  name : String,
  group : String,
  body : Array(Expression) do
  REQUIRED_CHASSIS_KEYS = ["fl", "fr", "bl", "br"]

  def validate!
    return if chassis.empty?

    missing = REQUIRED_CHASSIS_KEYS - chassis.keys.to_a
    unless missing.empty?
      raise "[PARSER] Drivetrain is missing required wheel keys: #{missing.join(", ")}"
    end
  end
end
