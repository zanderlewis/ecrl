require "../lexer/token"
require "./ast"
require "./types"

class StatementParser
  getter position : Int32

  def initialize(@tokens : Array(Token), @variables : Hash(String, Variable), @hardware_map : Hash(String, String))
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

  def parse_statement : Expression
    case peek.type
    when TokenType::Identifier
      id = consume(TokenType::Identifier).value

      if id == "drive"
        consume(TokenType::OpenParen)
        y = consume(TokenType::Identifier).value
        consume(TokenType::Comma) if peek.type == TokenType::Comma
        x = consume(TokenType::Identifier).value
        consume(TokenType::Comma) if peek.type == TokenType::Comma
        rx = consume(TokenType::Identifier).value
        consume(TokenType::CloseParen)
        return DriveMecanumExpr.new(y, x, rx)
      elsif @variables.has_key?(id) && peek.type == TokenType::Assignment
        consume(TokenType::Assignment)

        prefix = ""
        if peek.type == TokenType::Minus
          consume(TokenType::Minus)
          prefix = "-"
        end

        val = if peek.type == TokenType::NumberLiteral
                prefix + consume(TokenType::NumberLiteral).value
              elsif peek.type == TokenType::Identifier
                prefix + consume(TokenType::Identifier).value
              else
                raise "[PARSER] Expected NumberLiteral or Identifier for variable assignment on line #{peek.line}"
              end

        return VarReassignmentExpr.new(id, val)
      elsif id.starts_with?("robot.")
        return parse_robot_method(id)
      end

      raise "[PARSER] Unexpected identifier handle '#{id}' on line #{peek.line}"
    when TokenType::If
      return parse_if_statement
    else
      raise "[PARSER] Unexpected token state '#{peek.value}' on line #{peek.line}"
    end
  end

  private def parse_robot_method(id : String) : Expression
    parts = id.split(".")
    device_name = parts[1]?
    method_call = parts[2]?

    if device_name.nil?
      raise "[PARSER] Invalid robot method format: #{id}"
    end

    if device_name == "tel"
      if method_call == "show"
        return parse_telemetry_show
      elsif method_call == "update"
        consume(TokenType::OpenParen)
        consume(TokenType::CloseParen)
        return TelemetryUpdateExpr.new
      end
    elsif !method_call.nil? && (method_call == "set_power" || method_call == "set_velocity")
      return parse_motor_method(device_name, method_call)
    elsif !method_call.nil? && method_call == "stop"
      consume(TokenType::OpenParen)
      consume(TokenType::CloseParen)
      return StopExpr.new(device_name)
    end

    raise "[PARSER] Unknown robot method: #{id}"
  end

  private def parse_telemetry_show : TelemetryAddDataExpr
    consume(TokenType::OpenParen)

    # 1. FIRST ARGUMENT: MUST be a plain StringLiteral (the telemetry key/label)
    if peek.type != TokenType::StringLiteral
      raise "[PARSER] Telemetry label (first argument) must be a plain string, not an interpolated string, on line #{peek.line}"
    end
    label = consume(TokenType::StringLiteral).value
    args = [] of String

    # 2. SUBSEQUENT ARGUMENTS: Can be interpolated strings, plain strings, or variables
    while peek.type == TokenType::Comma
      consume(TokenType::Comma)

      arg = case peek.type
            when TokenType::InterpolatedString
              # Parse directly into Java string concatenation
              parse_interpolated_to_java(consume(TokenType::InterpolatedString).value)
            when TokenType::StringLiteral
              "\"" + consume(TokenType::StringLiteral).value + "\""
            when TokenType::Minus
              consume(TokenType::Minus)
              "-" + parse_value_arg
            else
              parse_value_arg
            end
      args << arg
    end

    consume(TokenType::CloseParen)
    TelemetryAddDataExpr.new(label, args)
  end

  private def parse_value_arg : String
    if peek.type == TokenType::NumberLiteral
      consume(TokenType::NumberLiteral).value
    elsif peek.type == TokenType::Identifier
      consume(TokenType::Identifier).value
    else
      raise "[PARSER] Expected NumberLiteral or Identifier for telemetry argument on line #{peek.line}"
    end
  end

  private def parse_interpolated_to_java(raw : String) : String
    # raw is formatted like: "literal\0expr\0literal"
    parts = raw.split('\0')
    java_parts = [] of String

    parts.each_with_index do |part, i|
      if i.even?
        # It's a literal string part. Wrap in quotes and escape for Java.
        escaped = part.gsub("\\", "\\\\").gsub("\"", "\\\"")
        java_parts << "\"#{escaped}\"" unless escaped.empty?
      else
        # It's an expression (variable/number). Leave as-is.
        java_parts << part.strip
      end
    end

    # Join with Java string concatenation operator
    if java_parts.empty?
      "\"\""
    else
      java_parts.join(" + ")
    end
  end

  private def parse_motor_method(device_name : String, method_call : String) : Expression
    consume(TokenType::OpenParen)

    prefix = ""
    if peek.type == TokenType::Minus
      consume(TokenType::Minus)
      prefix = "-"
    end

    val = if peek.type == TokenType::NumberLiteral
            prefix + consume(TokenType::NumberLiteral).value
          elsif peek.type == TokenType::Identifier
            prefix + consume(TokenType::Identifier).value
          else
            raise "[PARSER] Expected NumberLiteral or Identifier for method argument on line #{peek.line}"
          end

    ticks_per_rev = nil
    if method_call == "set_velocity" && peek.type == TokenType::Comma
      consume(TokenType::Comma)
      ticks_per_rev = if peek.type == TokenType::NumberLiteral
                        consume(TokenType::NumberLiteral).value
                      elsif peek.type == TokenType::Identifier
                        consume(TokenType::Identifier).value
                      else
                        raise "[PARSER] Expected NumberLiteral or Identifier for ticks_per_rev on line #{peek.line}"
                      end
    end

    consume(TokenType::CloseParen)

    if method_call == "set_power"
      SetPowerExpr.new(device_name, val)
    else
      @hardware_map[device_name] = "DcMotorEx"
      SetVelocityExpr.new(device_name, val, ticks_per_rev)
    end
  end

  def parse_if_statement : IfStatement
    consume(TokenType::If)

    cond_left = consume(TokenType::Identifier).value
    op : String? = nil
    cond_right : String? = nil

    if peek.type == TokenType::GreaterThan
      op = consume(TokenType::GreaterThan).value
      cond_right = consume(TokenType::NumberLiteral).value
    elsif peek.type == TokenType::LessThan
      op = consume(TokenType::LessThan).value
      cond_right = consume(TokenType::NumberLiteral).value
    end

    consume(TokenType::OpenBrace)
    if_node = IfStatement.new(cond_left, op, cond_right)
    if_node.then_branch = parse_block_statements
    consume(TokenType::CloseBrace)

    if peek.type == TokenType::Else
      consume(TokenType::Else)

      if peek.type == TokenType::If
        if_node.else_branch << parse_if_statement
      else
        consume(TokenType::OpenBrace)
        if_node.else_branch = parse_block_statements
        consume(TokenType::CloseBrace)
      end
    end

    if_node
  end

  def parse_block_statements : Array(Expression)
    statements = [] of Expression
    while peek.type != TokenType::CloseBrace && peek.type != TokenType::EOF
      statements << parse_statement
    end
    statements
  end
end
