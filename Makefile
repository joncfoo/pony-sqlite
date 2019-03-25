.PHONY: test build example sqlite docs watch clean

RUNNER=docker run \
			--rm \
			-u $(shell id -u):$(shell id -g) \
			-v $(shell pwd):/src/main \
			ponylang/ponyc:0.28.0

test: build
	@./bin/sqlite --noprog

build:
	$(RUNNER) ponyc --pic -o ./bin -d $(DOC_ARGS) -p sqlite ./sqlite

sqlite:
	$(RUNNER) ./scripts/compile-sqlite.sh

example:
	$(RUNNER) ponyc --pic -o ./bin -d -p sqlite ./example

docs: DOC_ARGS=--docs-public
docs: build
	$(shell cd bin/sqlite-docs; mkdocs build)
	rm -rf docs
	mv bin/sqlite-docs/site docs

watch:
	@./scripts/watch.sh

clean:
	rm -rf bin
