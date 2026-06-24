alias b := build
alias r := run
alias br := buildrun

# build the ECRL compiler
build:
	mkdir -p bin
	crystal build src/entry.cr -o ecrl
	mv ./ecrl bin/

# compile an ECRL file
run SOURCE:
	./bin/ecrl -s {{SOURCE}} -o {{SOURCE}}.java

# build and run
buildrun SOURCE: build
	just run {{SOURCE}}
