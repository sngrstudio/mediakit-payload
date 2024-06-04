# Makefile for running PostgreSQL service

.PHONY: run-app run-db run-all stop remove

run-app:
	docker compose up payload

run-db:
	docker compose up -d postgres

run-all:
	docker compose up

stop:
	docker compose down

remove:
	docker compose down --volumes