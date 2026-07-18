SHELL := /bin/bash

ALL_TESTS := t/0{1..6}*
LIVE_TESTS := t/0{5..6}*
SAFE_LIVE_TESTS := t/05*
UNIT_TESTS := t/0{1..4}*
UNSAFE_LIVE_TESTS := t/06*

help:
	@echo USAGE
	@echo "  make [help]      Show this help"
	@echo "  make alltest     Run all, including unsafe tests"
	@echo "  make config      Update config files"
	@echo "  make dbupgrade   Upgrade all datasets"
	@echo "  make livetest    Run safe and unsafe live tests"
	@echo "  make safetest    Run safe live tests"
	@echo "  make unittest    Run unit tests"
	@echo "  make unsafetest  Run unsafe live tests"

alltest:
	@SL_LIVETEST=1 prove -r $(ALL_TESTS)

.PHONY: config
config:
	@util/update-config.pl

dbupgrade:
	@util/upgrade-datasets.pl

livetest:
	@SL_LIVETEST=1 prove -r $(LIVE_TESTS)

safetest:
	@SL_LIVETEST=1 prove -r $(SAFE_LIVE_TESTS)

unittest:
	@prove -r $(UNIT_TESTS)

unsafetest:
	@SL_LIVETEST=1 prove -r $(UNSAFE_LIVE_TESTS)
