require "./token"
require "./keywords"

class LexerScanner
  def initialize(@source : String)
    @position = 0
    @line = 1
  end

  def scan_tokens : Array(Token)
    tokens = [] of Token

    while @position < @source.size
      current_char = @source[@position]

      if current_char == '\n'
        @line += 1
        @position += 1
        next
      elsif current_char.whitespace?
        @position += 1
        next
      elsif current_char == '!'
        if peek_next == '='
          tokens << Token.new(TokenType::NotEq, "!=", @line)
          @position += 2
          next
        else
          skip_comment
          next
        end
      end

      case current_char
      when '{' then tokens << Token.new(TokenType::OpenBrace, "{", @line); @position += 1; next
      when '}' then tokens << Token.new(TokenType::CloseBrace, "}", @line); @position += 1; next
      when ':' then tokens << Token.new(TokenType::Colon, ":", @line); @position += 1; next
      when ',' then tokens << Token.new(TokenType::Comma, ",", @line); @position += 1; next
      when ';' then tokens << Token.new(TokenType::Semicolon, ";", @line); @position += 1; next
      when '+' then tokens << Token.new(TokenType::Plus, "+", @line); @position += 1; next
      when '-' then tokens << Token.new(TokenType::Minus, "-", @line); @position += 1; next
      when '*' then tokens << Token.new(TokenType::Star, "*", @line); @position += 1; next
      when '/' then tokens << Token.new(TokenType::Slash, "/", @line); @position += 1; next
      when '(' then tokens << Token.new(TokenType::OpenParen, "(", @line); @position += 1; next
      when ')' then tokens << Token.new(TokenType::CloseParen, ")", @line); @position += 1; next
      when '>'
        if peek_next == '='
          tokens << Token.new(TokenType::GreaterEq, ">=", @line)
          @position += 2
        else
          tokens << Token.new(TokenType::GreaterThan, ">", @line)
          @position += 1
        end
        next
      when '<'
        if peek_next == '='
          tokens << Token.new(TokenType::LessEq, "<=", @line)
          @position += 2
        else
          tokens << Token.new(TokenType::LessThan, "<", @line)
          @position += 1
        end
        next
      when '='
        if peek_next == '='
          tokens << Token.new(TokenType::EqEq, "==", @line)
          @position += 2
        else
          tokens << Token.new(TokenType::Assignment, "=", @line)
          @position += 1
        end
        next
      when '&'
        if peek_next == '&'
          tokens << Token.new(TokenType::AndAnd, "&&", @line)
          @position += 2
        else
          raise "[LEXER] Unexpected character '&' at line #{@line}"
        end
        next
      when '|'
        if peek_next == '|'
          tokens << Token.new(TokenType::OrOr, "||", @line)
          @position += 2
        else
          raise "[LEXER] Unexpected character '|' at line #{@line}"
        end
        next
      end

      if current_char == '"'
        tokens << scan_string
        next
      end

      if current_char.ascii_number?
        tokens << scan_number
        next
      end

      if current_char.ascii_letter? || current_char == '_' || current_char == '.'
        tokens << scan_identifier_or_keyword
        next
      end

      raise "[LEXER] Unexpected character '#{current_char}' at line #{@line}"
    end

    tokens << Token.new(TokenType::EOF, "", @line)
    tokens
  end

  private def skip_comment
    while @position < @source.size && @source[@position] != '\n'
      @position += 1
    end
  end

  private def peek_next : Char?
    @position + 1 < @source.size ? @source[@position + 1] : nil
  end

  private def scan_string : Token
    @position += 1 # Skip opening quote

    has_interpolation = false
    parts = [] of String
    current = ""

    while @position < @source.size && @source[@position] != '"'
      if @source[@position] == '#' && peek_next == '{'
        parts << current
        current = ""
        @position += 2 # Skip #{

        # Collect expression until matching }
        expr = ""
        depth = 1
        while @position < @source.size && depth > 0
          if @source[@position] == '{'
            depth += 1
            expr += @source[@position]
          elsif @source[@position] == '}'
            depth -= 1
            expr += @source[@position] if depth > 0
          else
            if @source[@position] == '\n'
              @line += 1
            end
            expr += @source[@position]
          end
          @position += 1
        end

        parts << expr
        has_interpolation = true
      else
        if @source[@position] == '\n'
          @line += 1
        end
        current += @source[@position]
        @position += 1
      end
    end

    parts << current
    @position += 1 # Skip closing quote

    if has_interpolation
      # Encode as: "literal\0expr\0literal"
      Token.new(TokenType::InterpolatedString, parts.join("\0"), @line)
    else
      Token.new(TokenType::StringLiteral, current, @line)
    end
  end

  private def scan_number : Token
    start = @position
    while @position < @source.size && (@source[@position].ascii_number? || @source[@position] == '.')
      @position += 1
    end
    Token.new(TokenType::NumberLiteral, @source[start...@position], @line)
  end

  private def scan_identifier_or_keyword : Token
    start = @position
    while @position < @source.size && (@source[@position].ascii_alphanumeric? || @source[@position] == '_' || @source[@position] == '.')
      @position += 1
    end
    word = @source[start...@position]

    Token.new(Keywords.lookup(word), word, @line)
  end
end
