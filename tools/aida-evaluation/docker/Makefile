ROOT=/absolute/path/to/aida/tools/aida-evaluation
RUNS=$(ROOT)/M18-data/runs
SCORES=$(ROOT)/M18-data/scores
RUNID=task1-team-alpha-run-5
HOST_INPUT_DIR=$(RUNS)/$(RUNID)
HOST_OUTPUT_DIR=$(SCORES)/$(RUNID)
GRAPHDB_VERSION=9.2.1
GRAPHDB_EDITION=free
HOST_GRAPHDB_PORT=7200
CONTAINER_GRAPHDB_PORT=7200


all:
	@echo "Usage: make [build|run]"	

build:
	docker build \
	       --build-arg version=$(GRAPHDB_VERSION) \
	       --build-arg edition=$(GRAPHDB_EDITION) \
	       -t aida-evaluation .

run:
	docker run \
		--env RUNID=$(RUNID) \
		-p $(HOST_GRAPHDB_PORT):$(CONTAINER_GRAPHDB_PORT) \
		-v $(HOST_INPUT_DIR):/evaluate:ro \
		-v $(HOST_OUTPUT_DIR):/score \
	-it aida-evaluation