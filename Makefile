# This makefile is mostly just a wrapper around Dist::Zilla.

all: build

build: .build-timestamp

FIND_NON_HIDDEN_CMD := find $(1) -iname [^.#]*
FIND_NON_HIDDEN := $(shell $(FIND_NON_HIDDEN_CMD))

# It's not possible to know in advance the name of the tarball created
# by `dzil build`, so we can't rely on its timestamp. This is a
# workaround, which creates a file of known path and uses its
# timestamp to decide whether the build is outdated.
.build-timestamp: $(call FIND_NON_HIDDEN,lib) $(call FIND_NON_HIDDEN,t) dist.ini weaver.ini
	dzil clean && \
	dzil build && \
	date > .build-timestamp

test:
	dzil test

clean:
	rm -f .build-timestamp && \
	dzil clean

.PHONY: all clean build test
