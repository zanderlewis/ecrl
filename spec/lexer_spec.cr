require "./spec_helper"

describe Lexer do
  it "tokenizes keywords and punctuation" do
    tokens = Lexer.new("module define teleop { }").tokenize
    types = tokens[..-2].map &.type

    types.should eq([
      TokenType::Module,
      TokenType::Define,
      TokenType::TeleOp,
      TokenType::OpenBrace,
      TokenType::CloseBrace,
    ])
  end

  it "skips line comments" do
    tokens = Lexer.new("! comment\nmodule \"Test\"").tokenize
    types = tokens[..-2].map &.type

    types.should eq([TokenType::Module, TokenType::StringLiteral])
    tokens[1].value.should eq("Test")
  end

  it "tokenizes dotted identifiers" do
    tokens = Lexer.new("gpad1.left_stick_y robot.intake.set_power").tokenize
    values = tokens[..-2].map &.value

    values.should eq(["gpad1.left_stick_y", "robot.intake.set_power"])
  end

  it "distinguishes plain and interpolated strings" do
    tokens = Lexer.new(%("plain" "val: \#{x}")).tokenize

    tokens[0].type.should eq(TokenType::StringLiteral)
    tokens[0].value.should eq("plain")

    tokens[1].type.should eq(TokenType::InterpolatedString)
    tokens[1].value.should eq("val: \0x\0")
  end

  it "raises on unexpected characters" do
    expect_raises(Exception, /\[LEXER\]/) do
      Lexer.new("@").tokenize
    end
  end
end
