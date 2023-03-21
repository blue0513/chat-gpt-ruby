# Makefile

.PHONY: install quick run lint fix

install:
	bundle install

quick:
	bundle exec ruby src/main.rb --quick

run:
	bundle exec ruby src/main.rb

lint:
	bundle exec rubocop

fix:
	bundle exec rubocop -A
