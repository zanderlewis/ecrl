require "./value"

abstract class TelemetryValue; end

class TelemetryStringLiteral < TelemetryValue
  property value : String

  def initialize(@value); end
end

class TelemetryInterpolatedString < TelemetryValue
  property segments : Array(InterpolatedSegment)

  def initialize(@segments); end

  def self.from_lexer(raw : String) : TelemetryInterpolatedString
    segments = [] of InterpolatedSegment
    raw.split('\0').each_with_index do |part, i|
      next if part.empty? && i.even?
      segments << InterpolatedSegment.new(literal: i.even?, value: part)
    end
    new(segments)
  end
end

record InterpolatedSegment,
  literal : Bool,
  value : String

class TelemetryRawExpr < TelemetryValue
  property expr : ValueExpr

  def initialize(@expr); end
end
