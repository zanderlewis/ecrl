require "../lexer/token"
require "./ast/mod"
require "./program"
require "./validate"
require "./token_stream"
require "./definition_parser"
require "./routine_parser"
require "./opmode_parser"

class Parser
  def initialize(tokens : Array(Token))
    @stream = TokenStream.new(tokens)
  end

  def parse_program : Program
    module_name = "ECRLOpMode"
    opmode_name = "ECRLOpMode"
    group_name = "ECRL Teleop"
    package_name = DEFAULT_JAVA_PACKAGE
    execution_blocks = [] of Expression
    hardware_map = {} of String => String
    chassis_map = {} of String => ChassisWheel
    variables = {} of String => Variable
    routines = [] of RoutineDef
    routine_arities = {} of String => Int32
    kind = OpModeKind::TeleOp
    saw_opmode = false

    while @stream.peek.type != TokenType::EOF
      case @stream.peek.type
      when TokenType::Package
        @stream.consume(TokenType::Package)
        package_name = @stream.consume(TokenType::StringLiteral).value
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
      when TokenType::Routine
        routine = RoutineParser.parse(@stream, variables, routine_arities)
        routines << routine
      when TokenType::TeleOp
        raise "[PARSER] Only one OpMode (teleop or autonomous) is allowed per file" if saw_opmode
        @stream.consume(TokenType::TeleOp)
        opmode = OpmodeParser.parse_teleop(@stream, variables, routine_arities)
        opmode_name = opmode[:name]
        group_name = opmode[:group]
        execution_blocks = opmode[:body]
        kind = opmode[:kind]
        saw_opmode = true
      when TokenType::Autonomous
        raise "[PARSER] Only one OpMode (teleop or autonomous) is allowed per file" if saw_opmode
        @stream.consume(TokenType::Autonomous)
        opmode = OpmodeParser.parse_autonomous(@stream, variables, routine_arities)
        opmode_name = opmode[:name]
        group_name = opmode[:group]
        execution_blocks = opmode[:body]
        kind = opmode[:kind]
        saw_opmode = true
      else
        @stream.skip_unexpected("program")
      end
    end

    unless saw_opmode
      raise "[PARSER] Program must contain exactly one teleop or autonomous OpMode"
    end

    program = Program.new(
      module_name: module_name,
      hardware: hardware_map,
      chassis: chassis_map,
      vars: variables,
      routines: routines,
      kind: kind,
      name: opmode_name,
      group: group_name,
      body: execution_blocks,
      package: package_name,
    )
    ProgramValidator.validate!(program)
    program
  end
end
