require "../lexer/token"

# Shared token navigation for all parser components.
class TokenStream
  getter position : Int32

  def initialize(@tokens : Array(Token))
    @position = 0
  end

  def peek : Token
    @tokens[@position]
  end

  def consume(expected_type : TokenType) : Token
    token = peek
    if token.type != expected_type
      raise "[PARSER] Expected token #{expected_type}, got #{token.type} ('#{token.value}') on line #{token.line}"
    end
    @position += 1
    token
  end

  def skip_unexpected(context : String)
    token = peek
    raise "[PARSER] Unexpected token '#{token.value}' (#{token.type}) in #{context} on line #{token.line}"
  end
end
