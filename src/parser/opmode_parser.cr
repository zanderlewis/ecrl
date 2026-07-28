require "../lexer/token"
require "./ast/mod"
require "./program"
require "./token_stream"
require "./statement_parser"

module OpmodeParser
  def self.parse_teleop(stream : TokenStream, variables : Hash(String, Variable), routines : Hash(String, Int32)) : NamedTuple(name: String, group: String, body: Array(Expression), kind: OpModeKind)
    name = stream.consume(TokenType::StringLiteral).value
    group = "ECRL Teleop"

    if stream.peek.type == TokenType::Group
      stream.consume(TokenType::Group)
      group = stream.consume(TokenType::StringLiteral).value
    end

    stream.consume(TokenType::OpenBrace)
    stream.consume(TokenType::Loop)
    stream.consume(TokenType::OpenBrace)

    stmt_parser = StatementParser.new(stream, variables, routines)
    body = stmt_parser.parse_block_statements

    stream.consume(TokenType::CloseBrace)
    stream.consume(TokenType::CloseBrace)

    {name: name, group: group, body: body, kind: OpModeKind::TeleOp}
  end

  def self.parse_autonomous(stream : TokenStream, variables : Hash(String, Variable), routines : Hash(String, Int32)) : NamedTuple(name: String, group: String, body: Array(Expression), kind: OpModeKind)
    name = stream.consume(TokenType::StringLiteral).value
    group = "ECRL Auto"

    if stream.peek.type == TokenType::Group
      stream.consume(TokenType::Group)
      group = stream.consume(TokenType::StringLiteral).value
    end

    stream.consume(TokenType::OpenBrace)

    stmt_parser = StatementParser.new(stream, variables, routines)
    body = stmt_parser.parse_block_statements

    stream.consume(TokenType::CloseBrace)

    {name: name, group: group, body: body, kind: OpModeKind::Autonomous}
  end
end
