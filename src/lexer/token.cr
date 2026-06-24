enum TokenType
  Module
  Define
  DriveTrain
  Forward
  Reverse
  Dc
  Var
  TeleOp
  Group
  Loop
  If
  Else
  Identifier
  StringLiteral
  InterpolatedString
  NumberLiteral
  OpenBrace
  CloseBrace
  Colon
  Comma
  Minus
  OpenParen
  CloseParen
  GreaterThan
  LessThan
  Assignment
  Dot
  EOF
end

struct Token
  property type : TokenType
  property value : String
  property line : Int32

  def initialize(@type, @value, @line)
  end
end
