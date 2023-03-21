# Makefile

.PHONY: install quick run lint fix test ci

install:
	bundle install

quick:
	bundle exec ruby src/cli.rb --quick

run:
	bundle exec ruby src/cli.rb

lint:
	bundle exec rubocop

fix:
	bundle exec rubocop -A

test:
	bundle exec rspec

ci: lint test
