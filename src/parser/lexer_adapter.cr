require "../lexer/token"

# Token stream navigation utilities
module TokenAdapter
  def peek(tokens : Array(Token), position : Int32) : Token
    tokens[position]
  end

  def consume(tokens : Array(Token), position : Int32, expected_type : TokenType) : Token
    token = peek(tokens, position)
    if token.type != expected_type
      raise "[PARSER] Expected token #{expected_type}, got #{token.type} ('#{token.value}') on line #{token.line}"
    end
    token
  end
end
