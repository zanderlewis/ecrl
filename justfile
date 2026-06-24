alias b := build
alias r := run

build:
	mkdir -p bin
	crystal build src/entry.cr -o ecrl
	mv ./ecrl bin/

run SOURCE: build
	./bin/ecrl -s {{SOURCE}} -o {{SOURCE}}.java
