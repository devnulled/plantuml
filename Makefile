#
#
# Simple Makefile to make it easier to build/debug/use
# Docker containers locally.
#
#


# If you see pwd_unknown showing up, this is why. Re-calibrate your system.
PWD ?= pwd_unknown

# PROJECT_NAME defaults to name of the current directory.
# should not to be changed if you follow GitOps operating procedures.
PROJECT_NAME = $(notdir $(PWD))

# Note. If you change this, you also need to update docker-compose.yml.
# only useful in a setting with multiple services/ makefiles.
SERVICE_TARGET := plantuml

THIS_FILE := $(lastword $(MAKEFILE_LIST))
CMD_ARGUMENTS ?= $(cmd)

# export such that its passed to shell functions for Docker to pick up.
export PROJECT_NAME

# all our targets are phony (no files to check).
.PHONY: shell help build rebuild service login test clean prune start debug stop

# suppress makes own output
#.SILENT:

# shell is the first target. So instead of: make shell cmd="whoami", we can type: make cmd="whoami".
# more examples: make shell cmd="whoami && env", make shell cmd="echo hello container space".
# leave the double quotes to prevent commands overflowing in makefile (things like && would break)
# special chars: '',"",|,&&,||,*,^,[], should all work. Except "$" and "`"
shell:
ifeq ($(CMD_ARGUMENTS),)
	# no command is given, default to shell
	docker-compose -p $(PROJECT_NAME) run --rm $(SERVICE_TARGET) sh
else
	# run the command
	docker-compose -p $(PROJECT_NAME) run --rm $(SERVICE_TARGET) sh -c "$(CMD_ARGUMENTS)"
endif

help:
	@echo ''
	@echo 'Usage: make [TARGET] [EXTRA_ARGUMENTS]'
	@echo 'Targets:'
	@echo '  build    	build docker --image-- '
	@echo '  rebuild  	rebuild docker --image-- '
	@echo '  test     	test docker --container-- '
	@echo '  service   	run as service --container-- '
	@echo '  start   	build and run as foreground app '
	@echo '  debug   	build run as foreground app with debug logging '
	@echo '  stop   	stop service '
	@echo '  login   	run as service and login --container-- '
	@echo '  clean    	remove docker --image-- '
	@echo '  dive    	use dive to inspect an image --image-- '
	@echo '  prune		shortcut for docker system prune -af. Cleanup inactive containers and cache.'
	@echo '  shell		run docker --container-- '
	@echo ''
	@echo 'Extra arguments:'
	@echo 'cmd=:	make cmd="whoami"'

rebuild:
	# force a rebuild by passing --no-cache
	docker-compose build --no-cache $(SERVICE_TARGET)

service:
	# run as a (background) service
	docker-compose -p $(PROJECT_NAME) up -d $(SERVICE_TARGET)

start:
	# build and run as a foreground app
	docker-compose up --build

debug:
	# build and run as a foreground service with debug logging
	docker-compose --log-level DEBUG up --build

stop:
	# stop service
	docker-compose down

dive:
	# Use the dive to inspect a Docker image
	# https://github.com/wagoodman/dive
	dive $(PROJECT_NAME)

login: service
	# run as a service and attach to it
	docker exec -it $(PROJECT_NAME) sh

build:
	# only build the container. Note, docker does this also if you apply other targets.
	docker-compose build $(SERVICE_TARGET)

clean:
	# remove created images
	@docker-compose -p $(PROJECT_NAME) down --remove-orphans --rmi all 2>/dev/null \
	&& echo 'Image(s) for "$(PROJECT_NAME)" removed.' \
	|| echo 'Image(s) for "$(PROJECT_NAME)" already removed.'

prune:
	# clean all that is not actively used
	docker system prune -af

test:
	# here it is useful to add your own customised tests
	docker-compose -p $(PROJECT_NAME) run --rm $(SERVICE_TARGET) sh -c '\
		echo "I am `whoami`. My uid is `id -u`." && echo "Docker runs!"' \
	&& echo success
