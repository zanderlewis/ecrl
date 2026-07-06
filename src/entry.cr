require "option_parser"
require "./ecrl"

source_file = ""
output_file = ""
package_name = nil

OptionParser.parse do |opts|
  opts.banner = "Usage: ./ecrl [options]"
  opts.on("-s FILE", "--source FILE", "Path to ECRL source script file") { |f| source_file = f }
  opts.on("-o FILE", "--output FILE", "Path to target output Java file") { |f| output_file = f }
  opts.on("-p PACKAGE", "--package PACKAGE", "Java package for generated output (overrides source)") { |p| package_name = p }
  opts.on("-h", "--help", "Show the options text") { puts "Enka-Candler Robotics Language v#{VERSION}\n\n#{opts}"; exit }
end

if source_file.empty? || output_file.empty?
  puts "Error: Missing pipeline target specifications. Run 'ecrl --help' for details."
  exit 1
end

lexer = Lexer.new(File.read(source_file))
tokens = lexer.tokenize

parser = Parser.new(tokens)
program_ast = parser.parse_program

resolved_package = package_name.nil? ? program_ast.package : package_name.not_nil!
compiler = JavaCompiler.new(program_ast, resolved_package)
File.write(output_file, compiler.compile)

puts "Successfully compiled #{source_file} -> #{output_file}"
