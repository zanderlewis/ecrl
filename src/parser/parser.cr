require "../lexer/token"
require "./ast"
require "./types"
require "./definition_parser"
require "./statement_parser"

class Parser
  def initialize(@tokens : Array(Token))
    @position = 0
  end

  private def peek : Token
    @tokens[@position]
  end

  private def consume(expected_type : TokenType) : Token
    token = peek
    if token.type != expected_type
      raise "[PARSER] Expected token #{expected_type}, got #{token.type} ('#{token.value}') on line #{token.line}"
    end
    @position += 1
    token
  end

  def parse_program
    module_name = "ECRLOpMode"
    teleop_name = "ECRLOpMode"
    group_name = "ECRL Teleop"
    execution_blocks = [] of Expression
    hardware_map = {} of String => String
    chassis_map = {} of String => ChassisWheel
    variables = {} of String => Variable

    while peek.type != TokenType::EOF
      case peek.type
      when TokenType::Module
        consume(TokenType::Module)
        module_name = consume(TokenType::StringLiteral).value
      when TokenType::Define
        consume(TokenType::Define)
        def_parser = DefinitionParser.new(@tokens[@position...])
        defs = def_parser.parse_definitions
        hardware_map = defs[:hardware_map]
        chassis_map = defs[:chassis_map]
        variables = defs[:variables]

        # Advance by however many tokens DefinitionParser consumed
        @position += def_parser.position
      when TokenType::TeleOp
        consume(TokenType::TeleOp)
        teleop_name = consume(TokenType::StringLiteral).value

        if peek.type == TokenType::Group
          consume(TokenType::Group)
          group_name = consume(TokenType::StringLiteral).value
        end

        consume(TokenType::OpenBrace)
        consume(TokenType::Loop)
        consume(TokenType::OpenBrace)

        stmt_parser = StatementParser.new(@tokens[@position...], variables, hardware_map)
        execution_blocks = stmt_parser.parse_block_statements

        # Advance by however many tokens StatementParser consumed
        @position += stmt_parser.position

        # Consume the two closing braces (loop and teleop)
        consume(TokenType::CloseBrace)
        consume(TokenType::CloseBrace)
      else
        @position += 1
      end
    end

    {
      module_name: module_name,
      hardware:    hardware_map,
      chassis:     chassis_map,
      vars:        variables,
      name:        teleop_name,
      group:       group_name,
      body:        execution_blocks,
    }
  end
end
