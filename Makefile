# Makefile

.PHONY: install quick run lint fix

install:
	bundle install

quick:
	bundle exec ruby main.rb --quick

run:
	bundle exec ruby main.rb

lint:
	bundle exec rubocop

fix:
	bundle exec rubocop -A
