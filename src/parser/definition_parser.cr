require "../lexer/token"
require "./types"

class DefinitionParser
  getter position : Int32

  def initialize(@tokens : Array(Token))
    @position = 0
  end

  private def peek : Token
    @tokens[@position]
  end

  private def consume(expected_type : TokenType) : Token
    token = peek
    if token.type != expected_type
      raise "[PARSER] Expected token #{expected_type}, got #{token.type} ('#{token.value}') on line #{token.line}"
    end
    @position += 1
    token
  end

  def parse_definitions : {hardware_map: Hash(String, String), chassis_map: Hash(String, ChassisWheel), variables: Hash(String, Variable)}
    hardware_map = {} of String => String
    chassis_map = {} of String => ChassisWheel
    variables = {} of String => Variable

    consume(TokenType::OpenBrace)

    while peek.type != TokenType::CloseBrace
      if peek.type == TokenType::DriveTrain
        consume(TokenType::DriveTrain)
        consume(TokenType::OpenBrace)

        while peek.type != TokenType::CloseBrace
          id = consume(TokenType::Identifier).value
          consume(TokenType::Colon)

          hw_str = consume(TokenType::StringLiteral).value

          direction = if peek.type == TokenType::Forward
                        consume(TokenType::Forward)
                        "FORWARD"
                      elsif peek.type == TokenType::Reverse
                        consume(TokenType::Reverse)
                        "REVERSE"
                      else
                        "FORWARD"
                      end

          chassis_map[id] = ChassisWheel.new(name: hw_str, direction: direction)
        end

        consume(TokenType::CloseBrace)
      elsif peek.type == TokenType::Dc
        consume(TokenType::Dc)
        hw_str = consume(TokenType::StringLiteral).value
        hardware_map[hw_str] = "DcMotor"
      elsif peek.type == TokenType::Var
        consume(TokenType::Var)
        name = consume(TokenType::Identifier).value
        consume(TokenType::Assignment)

        itype = if peek.type == TokenType::StringLiteral
                  val_str = consume(TokenType::StringLiteral).value
                  val_str
                elsif peek.type == TokenType::NumberLiteral
                  val_str = consume(TokenType::NumberLiteral).value
                  infer_type(val_str)
                else
                  raise "[PARSER] Expected StringLiteral or NumberLiteral for variable value on line #{peek.line}"
                end

        variables[name] = Variable.new(id: name, value: itype)
      else
        @position += 1
      end
    end

    consume(TokenType::CloseBrace)

    {
      hardware_map: hardware_map,
      chassis_map:  chassis_map,
      variables:    variables,
    }
  end

  private def infer_type(value : String) : Int64 | Float64
    if value =~ /^\d+$/
      return value.to_i64
    elsif value =~ /^\d+\.\d+$/
      return value.to_f64
    else
      raise "[PARSER] Invalid number format: '#{value}'"
    end
  end
end
