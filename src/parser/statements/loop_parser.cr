require "../../lexer/token"
require "../ast/mod"
require "../program"
require "../token_stream"
require "../value_parser"
require "../condition_parser"

module LoopParser
  def self.parse_while(stream : TokenStream, &parse_block : -> Array(Expression)) : WhileStatement
    stream.consume(TokenType::While)
    condition = ConditionParser.parse(stream)
    stream.consume(TokenType::OpenBrace)
    node = WhileStatement.new(condition)
    node.body = parse_block.call
    stream.consume(TokenType::CloseBrace)
    node
  end

  def self.parse_for(stream : TokenStream, &parse_block : -> Array(Expression)) : ForStatement
    stream.consume(TokenType::For)
    var_name = stream.consume(TokenType::Identifier).value
    stream.consume(TokenType::Assignment)
    init = ValueExprParser.parse(stream)
    stream.consume(TokenType::Semicolon)
    condition = ConditionParser.parse(stream)
    stream.consume(TokenType::Semicolon)
    step_name = stream.consume(TokenType::Identifier).value
    unless step_name == var_name
      raise "[PARSER] For-loop step must assign to '#{var_name}' on line #{stream.peek.line}"
    end
    stream.consume(TokenType::Assignment)
    step_value = ValueExprParser.parse(stream)
    stream.consume(TokenType::OpenBrace)
    node = ForStatement.new(var_name, init, condition, step_value)
    node.body = parse_block.call
    stream.consume(TokenType::CloseBrace)
    node
  end
end
