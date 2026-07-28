require "./value"

abstract class ConditionExpr; end

class ValueCondition < ConditionExpr
  property value : ValueExpr

  def initialize(@value); end
end

class ComparisonCondition < ConditionExpr
  property left : ValueExpr
  property operator : String
  property right : ValueExpr

  def initialize(@left, @operator, @right); end
end

class AndCondition < ConditionExpr
  property left : ConditionExpr
  property right : ConditionExpr

  def initialize(@left, @right); end
end

class OrCondition < ConditionExpr
  property left : ConditionExpr
  property right : ConditionExpr

  def initialize(@left, @right); end
end
