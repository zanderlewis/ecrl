require "../lexer/token"
require "./ast/mod"
require "./token_stream"

module ValueExprParser
  def self.parse(stream : TokenStream) : ValueExpr
    parse_additive(stream)
  end

  def self.parse_identifier(stream : TokenStream) : IdentifierValueExpr
    unless stream.peek.type == TokenType::Identifier
      raise "[PARSER] Expected identifier on line #{stream.peek.line}"
    end
    IdentifierValueExpr.new(stream.consume(TokenType::Identifier).value)
  end

  private def self.parse_additive(stream : TokenStream) : ValueExpr
    left = parse_multiplicative(stream)
    while stream.peek.type == TokenType::Plus || stream.peek.type == TokenType::Minus
      op = stream.peek.type == TokenType::Plus ? "+" : "-"
      stream.consume(stream.peek.type)
      right = parse_multiplicative(stream)
      left = BinaryValueExpr.new(left, op, right)
    end
    left
  end

  private def self.parse_multiplicative(stream : TokenStream) : ValueExpr
    left = parse_unary(stream)
    while stream.peek.type == TokenType::Star || stream.peek.type == TokenType::Slash
      op = stream.peek.type == TokenType::Star ? "*" : "/"
      stream.consume(stream.peek.type)
      right = parse_unary(stream)
      left = BinaryValueExpr.new(left, op, right)
    end
    left
  end

  private def self.parse_unary(stream : TokenStream) : ValueExpr
    if stream.peek.type == TokenType::Minus
      stream.consume(TokenType::Minus)
      NegatedValueExpr.new(parse_unary(stream))
    else
      parse_primary(stream)
    end
  end

  private def self.parse_primary(stream : TokenStream) : ValueExpr
    case stream.peek.type
    when TokenType::NumberLiteral
      NumberValueExpr.new(stream.consume(TokenType::NumberLiteral).value)
    when TokenType::Identifier
      name = stream.consume(TokenType::Identifier).value
      if name == "deadzone" && stream.peek.type == TokenType::OpenParen
        parse_deadzone(stream)
      else
        IdentifierValueExpr.new(name)
      end
    when TokenType::OpenParen
      stream.consume(TokenType::OpenParen)
      expr = parse(stream)
      stream.consume(TokenType::CloseParen)
      expr
    else
      raise "[PARSER] Expected number or identifier on line #{stream.peek.line}"
    end
  end

  private def self.parse_deadzone(stream : TokenStream) : DeadzoneValueExpr
    stream.consume(TokenType::OpenParen)
    value = parse(stream)
    stream.consume(TokenType::Comma) if stream.peek.type == TokenType::Comma
    threshold = parse(stream)
    stream.consume(TokenType::CloseParen)
    DeadzoneValueExpr.new(value, threshold)
  end
end
