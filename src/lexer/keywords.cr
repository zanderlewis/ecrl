require "./token"

module Keywords
  MAP = {
    "package"     => TokenType::Package,
    "module"      => TokenType::Module,
    "define"      => TokenType::Define,
    "drivetrain"  => TokenType::DriveTrain,
    "FORWARD"     => TokenType::Forward,
    "REVERSE"     => TokenType::Reverse,
    "dc"          => TokenType::Dc,
    "servo"       => TokenType::Servo,
    "var"         => TokenType::Var,
    "teleop"      => TokenType::TeleOp,
    "autonomous"  => TokenType::Autonomous,
    "group"       => TokenType::Group,
    "loop"        => TokenType::Loop,
    "if"          => TokenType::If,
    "else"        => TokenType::Else,
    "while"       => TokenType::While,
    "for"         => TokenType::For,
    "routine"     => TokenType::Routine,
  } of String => TokenType

  def self.lookup(word : String) : TokenType
    MAP[word]? || TokenType::Identifier
  end
end
