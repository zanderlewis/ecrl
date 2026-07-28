require "../lexer/token"
require "./ast/mod"
require "./program"
require "./token_stream"
require "./statement_parser"

module RoutineParser
  def self.parse(stream : TokenStream, variables : Hash(String, Variable), routines : Hash(String, Int32)) : RoutineDef
    stream.consume(TokenType::Routine)
    name = stream.consume(TokenType::Identifier).value

    stream.consume(TokenType::OpenParen)
    params = [] of String
    unless stream.peek.type == TokenType::CloseParen
      params << stream.consume(TokenType::Identifier).value
      while stream.peek.type == TokenType::Comma
        stream.consume(TokenType::Comma)
        params << stream.consume(TokenType::Identifier).value
      end
    end
    stream.consume(TokenType::CloseParen)

    if routines.has_key?(name)
      raise "[PARSER] Duplicate routine '#{name}'"
    end
    routines[name] = params.size

    # Params act as local variables for the routine body
    local_vars = variables.dup
    params.each do |param|
      local_vars[param] = Variable.new(id: param, value: 0.0)
    end

    stream.consume(TokenType::OpenBrace)
    stmt_parser = StatementParser.new(stream, local_vars, routines)
    body = stmt_parser.parse_block_statements
    stream.consume(TokenType::CloseBrace)

    RoutineDef.new(name: name, params: params, body: body)
  end
end
