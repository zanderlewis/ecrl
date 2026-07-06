require "../lexer/token"
require "./types"
require "./token_stream"

class DefinitionParser
  def initialize(@stream : TokenStream)
  end

  def parse_definitions : NamedTuple(hardware_map: Hash(String, String), chassis_map: Hash(String, ChassisWheel), variables: Hash(String, Variable))
    hardware_map = {} of String => String
    chassis_map = {} of String => ChassisWheel
    variables = {} of String => Variable

    @stream.consume(TokenType::OpenBrace)

    while @stream.peek.type != TokenType::CloseBrace
      case @stream.peek.type
      when TokenType::DriveTrain
        parse_drivetrain(chassis_map)
      when TokenType::Dc
        parse_dc_motor(hardware_map)
      when TokenType::Var
        parse_variable(variables)
      else
        @stream.skip_unexpected("define block")
      end
    end

    @stream.consume(TokenType::CloseBrace)

    {
      hardware_map: hardware_map,
      chassis_map:  chassis_map,
      variables:    variables,
    }
  end

  private def parse_drivetrain(chassis_map : Hash(String, ChassisWheel))
    @stream.consume(TokenType::DriveTrain)
    @stream.consume(TokenType::OpenBrace)

    while @stream.peek.type != TokenType::CloseBrace
      id = @stream.consume(TokenType::Identifier).value
      @stream.consume(TokenType::Colon)
      hw_str = @stream.consume(TokenType::StringLiteral).value

      direction = case @stream.peek.type
                  when TokenType::Forward
                    @stream.consume(TokenType::Forward)
                    "FORWARD"
                  when TokenType::Reverse
                    @stream.consume(TokenType::Reverse)
                    "REVERSE"
                  else
                    "FORWARD"
                  end

      chassis_map[id] = ChassisWheel.new(name: hw_str, direction: direction)
    end

    @stream.consume(TokenType::CloseBrace)
  end

  private def parse_dc_motor(hardware_map : Hash(String, String))
    @stream.consume(TokenType::Dc)
    hw_str = @stream.consume(TokenType::StringLiteral).value
    hardware_map[hw_str] = "DcMotor"
  end

  private def parse_variable(variables : Hash(String, Variable))
    @stream.consume(TokenType::Var)
    name = @stream.consume(TokenType::Identifier).value
    @stream.consume(TokenType::Assignment)

    value = case @stream.peek.type
            when TokenType::StringLiteral
              @stream.consume(TokenType::StringLiteral).value
            when TokenType::NumberLiteral
              infer_type(@stream.consume(TokenType::NumberLiteral).value)
            else
              raise "[PARSER] Expected string or number for variable value on line #{@stream.peek.line}"
            end

    variables[name] = Variable.new(id: name, value: value)
  end

  private def infer_type(value : String) : Int64 | Float64
    if value =~ /^\d+$/
      value.to_i64
    elsif value =~ /^\d+\.\d+$/
      value.to_f64
    else
      raise "[PARSER] Invalid number format: '#{value}'"
    end
  end
end
