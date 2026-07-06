require "../lexer/token"
require "./ast"
require "./types"
require "./token_stream"

module ValueExprParser
  def self.parse(stream : TokenStream) : ValueExpr
    if stream.peek.type == TokenType::Minus
      stream.consume(TokenType::Minus)
      return NegatedValueExpr.new(parse(stream))
    end

    case stream.peek.type
    when TokenType::NumberLiteral
      NumberValueExpr.new(stream.consume(TokenType::NumberLiteral).value)
    when TokenType::Identifier
      IdentifierValueExpr.new(stream.consume(TokenType::Identifier).value)
    else
      raise "[PARSER] Expected number or identifier on line #{stream.peek.line}"
    end
  end

  def self.parse_identifier(stream : TokenStream) : IdentifierValueExpr
    unless stream.peek.type == TokenType::Identifier
      raise "[PARSER] Expected identifier on line #{stream.peek.line}"
    end
    IdentifierValueExpr.new(stream.consume(TokenType::Identifier).value)
  end
end

class StatementParser
  def initialize(@stream : TokenStream, @variables : Hash(String, Variable))
  end

  def parse_statement : Expression
    case @stream.peek.type
    when TokenType::Identifier
      id = @stream.consume(TokenType::Identifier).value

      if id == "drive"
        return parse_drive_call
      elsif @variables.has_key?(id) && @stream.peek.type == TokenType::Assignment
        @stream.consume(TokenType::Assignment)
        return VarReassignmentExpr.new(id, ValueExprParser.parse(@stream))
      elsif id.starts_with?("robot.")
        return parse_robot_method(id)
      end

      raise "[PARSER] Unexpected identifier '#{id}' on line #{@stream.peek.line}"
    when TokenType::If
      return parse_if_statement
    else
      raise "[PARSER] Unexpected token '#{@stream.peek.value}' on line #{@stream.peek.line}"
    end
  end

  private def parse_drive_call : DriveMecanumExpr
    @stream.consume(TokenType::OpenParen)
    y = ValueExprParser.parse_identifier(@stream)
    @stream.consume(TokenType::Comma) if @stream.peek.type == TokenType::Comma
    x = ValueExprParser.parse_identifier(@stream)
    @stream.consume(TokenType::Comma) if @stream.peek.type == TokenType::Comma
    rx = ValueExprParser.parse_identifier(@stream)
    @stream.consume(TokenType::CloseParen)
    DriveMecanumExpr.new(y, x, rx)
  end

  private def parse_robot_method(id : String) : Expression
    parts = id.split(".")
    device_name = parts[1]?
    method_call = parts[2]?

    if device_name.nil?
      raise "[PARSER] Invalid robot method format: #{id}"
    end

    if device_name == "tel"
      case method_call
      when "show"  then return parse_telemetry_show
      when "update"
        @stream.consume(TokenType::OpenParen)
        @stream.consume(TokenType::CloseParen)
        return TelemetryUpdateExpr.new
      end
    elsif !method_call.nil? && (method_call == "set_power" || method_call == "set_velocity")
      return parse_motor_method(device_name, method_call)
    elsif !method_call.nil? && method_call == "stop"
      @stream.consume(TokenType::OpenParen)
      @stream.consume(TokenType::CloseParen)
      return StopExpr.new(device_name)
    end

    raise "[PARSER] Unknown robot method: #{id}"
  end

  private def parse_telemetry_show : TelemetryAddDataExpr
    @stream.consume(TokenType::OpenParen)

    if @stream.peek.type != TokenType::StringLiteral
      raise "[PARSER] Telemetry label must be a plain string on line #{@stream.peek.line}"
    end
    label = @stream.consume(TokenType::StringLiteral).value
    args = [] of TelemetryValue

    while @stream.peek.type == TokenType::Comma
      @stream.consume(TokenType::Comma)
      args << parse_telemetry_arg
    end

    @stream.consume(TokenType::CloseParen)
    TelemetryAddDataExpr.new(label, args)
  end

  private def parse_telemetry_arg : TelemetryValue
    case @stream.peek.type
    when TokenType::InterpolatedString
      TelemetryInterpolatedString.from_lexer(@stream.consume(TokenType::InterpolatedString).value)
    when TokenType::StringLiteral
      TelemetryStringLiteral.new(@stream.consume(TokenType::StringLiteral).value)
    else
      TelemetryRawExpr.new(ValueExprParser.parse(@stream))
    end
  end

  private def parse_motor_method(device_name : String, method_call : String) : Expression
    @stream.consume(TokenType::OpenParen)
    val = ValueExprParser.parse(@stream)

    ticks_per_rev = nil
    if method_call == "set_velocity" && @stream.peek.type == TokenType::Comma
      @stream.consume(TokenType::Comma)
      ticks_per_rev = ValueExprParser.parse(@stream)
    end

    @stream.consume(TokenType::CloseParen)

    if method_call == "set_power"
      SetPowerExpr.new(device_name, val)
    else
      SetVelocityExpr.new(device_name, val, ticks_per_rev)
    end
  end

  def parse_if_statement : IfStatement
    @stream.consume(TokenType::If)

    cond_left = ValueExprParser.parse_identifier(@stream)
    op : String? = nil
    cond_right : ValueExpr? = nil

    if @stream.peek.type == TokenType::GreaterThan
      op = @stream.consume(TokenType::GreaterThan).value
      cond_right = ValueExprParser.parse(@stream)
    elsif @stream.peek.type == TokenType::LessThan
      op = @stream.consume(TokenType::LessThan).value
      cond_right = ValueExprParser.parse(@stream)
    end

    @stream.consume(TokenType::OpenBrace)
    if_node = IfStatement.new(cond_left, op, cond_right)
    if_node.then_branch = parse_block_statements
    @stream.consume(TokenType::CloseBrace)

    if @stream.peek.type == TokenType::Else
      @stream.consume(TokenType::Else)

      if @stream.peek.type == TokenType::If
        if_node.else_branch << parse_if_statement
      else
        @stream.consume(TokenType::OpenBrace)
        if_node.else_branch = parse_block_statements
        @stream.consume(TokenType::CloseBrace)
      end
    end

    if_node
  end

  def parse_block_statements : Array(Expression)
    statements = [] of Expression
    while @stream.peek.type != TokenType::CloseBrace && @stream.peek.type != TokenType::EOF
      statements << parse_statement
    end
    statements
  end
end
