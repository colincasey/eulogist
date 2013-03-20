TESTS = test/*.coffee

build:
	coffee -o lib/ -cw src/

test:
	@NODE_ENV=test ./node_modules/.bin/mocha \
			--require should \
			--reporter list \
			--slow 20 \
			--compilers coffee:coffee-script \
			--growl \
			--watch \
			$(TESTS)

.PHONY: test
