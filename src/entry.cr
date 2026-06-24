require "option_parser"
require "./ecrl"

source_file = ""
output_file = ""

OptionParser.parse do |opts|
  opts.banner = "Usage: ./ecrl [options]"
  opts.on("-s FILE", "--source FILE", "Path to ECRL source script file") { |f| source_file = f }
  opts.on("-o FILE", "--output FILE", "Path to target output Java file") { |f| output_file = f }
  opts.on("-h", "--help", "Show the options text") { puts "Enka-Candler Robotics Language v#{VERSION}\n\n#{opts}"; exit }
end

if source_file.empty? || output_file.empty?
  puts "Error: Missing pipeline target specifications. Run 'ecrl --help' for details."
  exit 1
end

# Execution Stream Chain
lexer = Lexer.new(File.read(source_file))
tokens = lexer.tokenize

parser = Parser.new(tokens)
program_ast = parser.parse_program

compiler = JavaCompiler.new(program_ast)
File.write(output_file, compiler.compile)

puts "Successfully compiled #{source_file} -> #{output_file}"
