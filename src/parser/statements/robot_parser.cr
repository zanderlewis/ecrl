require "../../lexer/token"
require "../ast/mod"
require "../token_stream"
require "../value_parser"

module RobotParser
  def self.parse_drive_call(stream : TokenStream) : DriveMecanumExpr
    stream.consume(TokenType::OpenParen)
    y = ValueExprParser.parse(stream)
    stream.consume(TokenType::Comma) if stream.peek.type == TokenType::Comma
    x = ValueExprParser.parse(stream)
    stream.consume(TokenType::Comma) if stream.peek.type == TokenType::Comma
    rx = ValueExprParser.parse(stream)
    stream.consume(TokenType::CloseParen)
    DriveMecanumExpr.new(y, x, rx)
  end

  def self.parse_wait_call(stream : TokenStream) : WaitExpr
    stream.consume(TokenType::OpenParen)
    seconds = ValueExprParser.parse(stream)
    stream.consume(TokenType::CloseParen)
    WaitExpr.new(seconds)
  end

  def self.parse_call(stream : TokenStream, name : String) : CallExpr
    stream.consume(TokenType::OpenParen)
    args = [] of ValueExpr
    unless stream.peek.type == TokenType::CloseParen
      args << ValueExprParser.parse(stream)
      while stream.peek.type == TokenType::Comma
        stream.consume(TokenType::Comma)
        args << ValueExprParser.parse(stream)
      end
    end
    stream.consume(TokenType::CloseParen)
    CallExpr.new(name, args)
  end

  def self.parse_robot_method(stream : TokenStream, id : String) : Expression
    parts = id.split(".")
    device_name = parts[1]?
    method_call = parts[2]?

    if device_name.nil?
      raise "[PARSER] Invalid robot method format: #{id}"
    end

    if device_name == "tel"
      case method_call
      when "show" then return parse_telemetry_show(stream)
      when "update"
        stream.consume(TokenType::OpenParen)
        stream.consume(TokenType::CloseParen)
        return TelemetryUpdateExpr.new
      end
    elsif !method_call.nil? && (method_call == "set_power" || method_call == "set_velocity")
      return parse_motor_method(stream, device_name, method_call)
    elsif !method_call.nil? && method_call == "set_position"
      return parse_servo_method(stream, device_name)
    elsif !method_call.nil? && method_call == "stop"
      stream.consume(TokenType::OpenParen)
      stream.consume(TokenType::CloseParen)
      return StopExpr.new(device_name)
    end

    raise "[PARSER] Unknown robot method: #{id}"
  end

  private def self.parse_telemetry_show(stream : TokenStream) : TelemetryAddDataExpr
    stream.consume(TokenType::OpenParen)

    if stream.peek.type != TokenType::StringLiteral
      raise "[PARSER] Telemetry label must be a plain string on line #{stream.peek.line}"
    end
    label = stream.consume(TokenType::StringLiteral).value
    args = [] of TelemetryValue

    while stream.peek.type == TokenType::Comma
      stream.consume(TokenType::Comma)
      args << parse_telemetry_arg(stream)
    end

    stream.consume(TokenType::CloseParen)
    TelemetryAddDataExpr.new(label, args)
  end

  private def self.parse_telemetry_arg(stream : TokenStream) : TelemetryValue
    case stream.peek.type
    when TokenType::InterpolatedString
      TelemetryInterpolatedString.from_lexer(stream.consume(TokenType::InterpolatedString).value)
    when TokenType::StringLiteral
      TelemetryStringLiteral.new(stream.consume(TokenType::StringLiteral).value)
    else
      TelemetryRawExpr.new(ValueExprParser.parse(stream))
    end
  end

  private def self.parse_motor_method(stream : TokenStream, device_name : String, method_call : String) : Expression
    stream.consume(TokenType::OpenParen)
    val = ValueExprParser.parse(stream)

    ticks_per_rev = nil
    if method_call == "set_velocity" && stream.peek.type == TokenType::Comma
      stream.consume(TokenType::Comma)
      ticks_per_rev = ValueExprParser.parse(stream)
    end

    stream.consume(TokenType::CloseParen)

    if method_call == "set_power"
      SetPowerExpr.new(device_name, val)
    else
      SetVelocityExpr.new(device_name, val, ticks_per_rev)
    end
  end

  private def self.parse_servo_method(stream : TokenStream, device_name : String) : SetPositionExpr
    stream.consume(TokenType::OpenParen)
    val = ValueExprParser.parse(stream)
    stream.consume(TokenType::CloseParen)
    SetPositionExpr.new(device_name, val)
  end
end
