require "../../lexer/token"
require "../ast/mod"
require "../program"
require "../token_stream"
require "../condition_parser"

module IfParser
  def self.parse(stream : TokenStream, variables : Hash(String, Variable), &parse_block : -> Array(Expression)) : IfStatement
    stream.consume(TokenType::If)
    condition = ConditionParser.parse(stream)

    stream.consume(TokenType::OpenBrace)
    if_node = IfStatement.new(condition)
    if_node.then_branch = parse_block.call
    stream.consume(TokenType::CloseBrace)

    if stream.peek.type == TokenType::Else
      stream.consume(TokenType::Else)

      if stream.peek.type == TokenType::If
        if_node.else_branch << parse(stream, variables, &parse_block)
      else
        stream.consume(TokenType::OpenBrace)
        if_node.else_branch = parse_block.call
        stream.consume(TokenType::CloseBrace)
      end
    end

    if_node
  end
end
