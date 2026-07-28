require "../lexer/token"
require "./ast/mod"
require "./program"
require "./token_stream"
require "./value_parser"
require "./statements/robot_parser"
require "./statements/if_parser"
require "./statements/loop_parser"

class StatementParser
  def initialize(
    @stream : TokenStream,
    @variables : Hash(String, Variable),
    @routines : Hash(String, Int32) = {} of String => Int32,
  )
  end

  def parse_statement : Expression
    case @stream.peek.type
    when TokenType::Identifier
      id = @stream.consume(TokenType::Identifier).value

      if id == "drive"
        return RobotParser.parse_drive_call(@stream)
      elsif id == "wait"
        return RobotParser.parse_wait_call(@stream)
      elsif @variables.has_key?(id) && @stream.peek.type == TokenType::Assignment
        @stream.consume(TokenType::Assignment)
        return VarReassignmentExpr.new(id, ValueExprParser.parse(@stream))
      elsif id.starts_with?("robot.")
        return RobotParser.parse_robot_method(@stream, id)
      elsif @routines.has_key?(id) && @stream.peek.type == TokenType::OpenParen
        return RobotParser.parse_call(@stream, id)
      elsif @stream.peek.type == TokenType::OpenParen
        # Allow forward references — validated later
        return RobotParser.parse_call(@stream, id)
      end

      raise "[PARSER] Unexpected identifier '#{id}' on line #{@stream.peek.line}"
    when TokenType::If
      return IfParser.parse(@stream, @variables) { parse_block_statements }
    when TokenType::While
      return LoopParser.parse_while(@stream) { parse_block_statements }
    when TokenType::For
      return LoopParser.parse_for(@stream) { parse_block_statements }
    else
      raise "[PARSER] Unexpected token '#{@stream.peek.value}' on line #{@stream.peek.line}"
    end
  end

  def parse_block_statements : Array(Expression)
    statements = [] of Expression
    while @stream.peek.type != TokenType::CloseBrace && @stream.peek.type != TokenType::EOF
      statements << parse_statement
    end
    statements
  end
end
