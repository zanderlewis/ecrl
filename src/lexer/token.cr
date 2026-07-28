enum TokenType
  Package
  Module
  Define
  DriveTrain
  Forward
  Reverse
  Dc
  Servo
  Var
  TeleOp
  Autonomous
  Group
  Loop
  If
  Else
  While
  For
  Routine
  Identifier
  StringLiteral
  InterpolatedString
  NumberLiteral
  OpenBrace
  CloseBrace
  Colon
  Comma
  Semicolon
  Plus
  Minus
  Star
  Slash
  OpenParen
  CloseParen
  GreaterThan
  GreaterEq
  LessThan
  LessEq
  EqEq
  NotEq
  AndAnd
  OrOr
  Assignment
  Dot # reserved
  EOF
end

struct Token
  property type : TokenType
  property value : String
  property line : Int32

  def initialize(@type, @value, @line)
  end
end
