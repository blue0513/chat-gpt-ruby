# Makefile

.PHONY: install quick quitck-lite
.PHONY: run lint fix test ci

install:
	bundle install

quick:
	bundle exec ruby src/cli.rb --quick

quick-lite:
	bundle exec ruby src/cli.rb --quick --model gpt-3.5-turbo

run:
	bundle exec ruby src/cli.rb

lint:
	bundle exec rubocop

fix:
	bundle exec rubocop -A

test:
	bundle exec rspec

ci: lint test
