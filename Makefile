# Makefile

.PHONY: install quick run

install:
	bundle install

quick:
	bundle exec ruby main.rb --quick

run:
	bundle exec ruby main.rb
