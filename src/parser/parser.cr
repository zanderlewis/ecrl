require "../lexer/token"
require "./ast"
require "./types"
require "./token_stream"
require "./definition_parser"
require "./statement_parser"

class Parser
  def initialize(tokens : Array(Token))
    @stream = TokenStream.new(tokens)
  end

  def parse_program : Program
    module_name = "ECRLOpMode"
    teleop_name = "ECRLOpMode"
    group_name = "ECRL Teleop"
    execution_blocks = [] of Expression
    hardware_map = {} of String => String
    chassis_map = {} of String => ChassisWheel
    variables = {} of String => Variable

    while @stream.peek.type != TokenType::EOF
      case @stream.peek.type
      when TokenType::Module
        @stream.consume(TokenType::Module)
        module_name = @stream.consume(TokenType::StringLiteral).value
      when TokenType::Define
        @stream.consume(TokenType::Define)
        def_parser = DefinitionParser.new(@stream)
        defs = def_parser.parse_definitions
        hardware_map = defs[:hardware_map]
        chassis_map = defs[:chassis_map]
        variables = defs[:variables]
      when TokenType::TeleOp
        @stream.consume(TokenType::TeleOp)
        teleop_name = @stream.consume(TokenType::StringLiteral).value

        if @stream.peek.type == TokenType::Group
          @stream.consume(TokenType::Group)
          group_name = @stream.consume(TokenType::StringLiteral).value
        end

        @stream.consume(TokenType::OpenBrace)
        @stream.consume(TokenType::Loop)
        @stream.consume(TokenType::OpenBrace)

        stmt_parser = StatementParser.new(@stream, variables)
        execution_blocks = stmt_parser.parse_block_statements

        @stream.consume(TokenType::CloseBrace)
        @stream.consume(TokenType::CloseBrace)
      else
        @stream.skip_unexpected("program")
      end
    end

    program = Program.new(
      module_name: module_name,
      hardware: hardware_map,
      chassis: chassis_map,
      vars: variables,
      name: teleop_name,
      group: group_name,
      body: execution_blocks,
    )
    program.validate!
    program
  end
end
