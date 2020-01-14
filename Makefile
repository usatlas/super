# If any of the following environment variables is set when calling make,
# their values will be used to steer the Jekyll build command. If they are
# not set, the following default values will be used:
JEKYLL_SOURCE_DIR ?= .
JEKYLL_DESTINATION_DIR ?= _site
JEKYLL_BASEURL ?= 


# If $JEKYLL_BASEURL is set, add a --baseurl argument to the Jekyll build
# command, if not, leave $JEKYLL_BASEURL_ARG empty.
JEKYLL_BASEURL_ARG := $(if $(JEKYLL_BASEURL),--baseurl $(JEKYLL_BASEURL),)
LOCAL_JEKYLL_PORT ?= 4000
JEKYLL_DOCKER_IMG ?= jekyll/builder:3.8

all: serve

install:
	$(info Installing Jekyll gems...)
	gem install jekyll

serve:
	$(info Starting up Jekyll to serve page locally...)
	jekyll serve --port "$(LOCAL_JEKYLL_PORT)"

serve-docker:
	$(info Starting up Jekyll Docker image to serve page locally...)
	docker run -e JEKYLL_UID=$$(id -u) --volume $(CURDIR):/srv/jekyll --interactive --tty \
		--publish "$(LOCAL_JEKYLL_PORT)":4000 "$(JEKYLL_DOCKER_IMG)" jekyll serve

build:
	$(info Building Jekyll webpage...)
	jekyll build --source "$(JEKYLL_SOURCE_DIR)" --destination "$(JEKYLL_DESTINATION_DIR)" $(JEKYLL_BASEURL_ARG)

spellcheck:
	$(info Running spellcheck in docker image...)
	@docker run --volume $(CURDIR):/srv/jekyll --entrypoint "/bin/bash" "$(JEKYLL_DOCKER_IMG)" \
		-c "apk add --quiet --no-cache grep aspell aspell-en && /srv/jekyll/ci_scripts/check-spelling.sh"

htmlcheck:
	$(info Running htmlproofer in docker image...)
	@docker run --volume $(CURDIR):/srv/jekyll --entrypoint "/bin/bash" "$(JEKYLL_DOCKER_IMG)" \
		/srv/jekyll/ci_scripts/check-html.sh /srv/jekyll/_site

htmlvalidate:
	$(info Running html5validator in docker image...)
	@docker run --volume $(CURDIR):/srv/jekyll --entrypoint "/bin/bash" "stratdat/html5validator" \
		/srv/jekyll/ci_scripts/validate-html.sh /srv/jekyll/_site

test: spellcheck htmlcheck

.PHONY: install, serve, serve-docker, build, spellcheck, htmlcheck test
