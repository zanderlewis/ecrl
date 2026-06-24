require "./scanner"
require "./token"

class Lexer
  def initialize(@source : String)
  end

  def tokenize : Array(Token)
    scanner = LexerScanner.new(@source)
    scanner.scan_tokens
  end
end
