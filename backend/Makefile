# detect operating system
UNAME_S := $(shell uname -s)

# Load .env as makefile vars
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# Generate openapi documentation
docs:
	redoc-cli build openapi.yml --options.theme.colors.primary.main=green -o src/docs.html

docs-open:
	redoc-cli build openapi.yml --options.theme.colors.primary.main=green -o src/docs.html
ifeq ($(UNAME_S),Darwin)
	open src/docs.html
else
	xdg-open src/docs.html
endif


# reset the database
# All DB users must be disconnected for this to succeed. Try exiting rust-analyzer if this fails.
reset:
	# shutdown services that access the DB
	# docker kill backend-adminer-1
	docker compose --profile db up --detach
	sqlx db reset -y

# Start only the database services
db:
	docker compose --profile db up

# Start the backend, database, and web on the local machine
local:
	BACKEND_ENDPOINT="http://localhost:8080" docker compose --profile db up --force-recreate --wait
	sleep 1 
ifeq ($(UNAME_S),Darwin)
	open http://localhost:3000
	open "http://localhost:7000/?pgsql=db&username=dbmasteruser&db=myace&ns=public"
else
	xdg-open http://localhost:3000
	xdg-open "http://localhost:7000/?pgsql=db&username=dbmasteruser&db=myace&ns=public"
endif
	cargo watch --exec run

# Just the web frontend pointing at the production server
prod:
ifeq ($(UNAME_S),Darwin)
	sleep 3 && open http://localhost:3000 &
else
	sleep 3 && xdg-open http://localhost:3000 &
endif
	BACKEND_ENDPOINT="dev.myace.ai" docker compose up

deployment:
	echo "AWS profile (empty will use default):" $(MYACE_AWS_PROFILE)
	make docs
	cargo sqlx prepare -- --lib # DB must be up for this to generate sqlx-data.json
	docker build -t myace-deployment . # builds with offline DB
	python deploy.py myace-deployment $(MYACE_AWS_PROFILE)
