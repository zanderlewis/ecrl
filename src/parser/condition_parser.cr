require "../lexer/token"
require "./ast/mod"
require "./token_stream"
require "./value_parser"

module ConditionParser
  COMPARISON_TOKENS = {
    TokenType::EqEq        => "==",
    TokenType::NotEq       => "!=",
    TokenType::GreaterThan => ">",
    TokenType::GreaterEq   => ">=",
    TokenType::LessThan    => "<",
    TokenType::LessEq      => "<=",
  }

  def self.parse(stream : TokenStream) : ConditionExpr
    parse_or(stream)
  end

  def self.parse_or(stream : TokenStream) : ConditionExpr
    left = parse_and(stream)
    while stream.peek.type == TokenType::OrOr
      stream.consume(TokenType::OrOr)
      right = parse_and(stream)
      left = OrCondition.new(left, right)
    end
    left
  end

  def self.parse_and(stream : TokenStream) : ConditionExpr
    left = parse_comparison(stream)
    while stream.peek.type == TokenType::AndAnd
      stream.consume(TokenType::AndAnd)
      right = parse_comparison(stream)
      left = AndCondition.new(left, right)
    end
    left
  end

  def self.parse_comparison(stream : TokenStream) : ConditionExpr
    left = ValueExprParser.parse(stream)

    if op = COMPARISON_TOKENS[stream.peek.type]?
      token_type = stream.peek.type
      stream.consume(token_type)
      right = ValueExprParser.parse(stream)
      ComparisonCondition.new(left, op, right)
    else
      ValueCondition.new(left)
    end
  end
end
