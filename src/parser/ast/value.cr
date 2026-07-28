abstract class ValueExpr; end

class NumberValueExpr < ValueExpr
  property value : String

  def initialize(@value); end
end

class IdentifierValueExpr < ValueExpr
  property name : String

  def initialize(@name); end
end

class NegatedValueExpr < ValueExpr
  property inner : ValueExpr

  def initialize(@inner); end
end

class BinaryValueExpr < ValueExpr
  property left : ValueExpr
  property operator : String
  property right : ValueExpr

  def initialize(@left, @operator, @right); end
end

class DeadzoneValueExpr < ValueExpr
  property value : ValueExpr
  property threshold : ValueExpr

  def initialize(@value, @threshold); end
end
