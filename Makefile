-include config.mk

PYTHON ?= python2.6
VERSION ?= undefined
CLEAN ?= yes

CONFIGURE_ERROR=

export PYTHONPATH := $(PYTHONPATH):$(PWD)/src:$(PWD)/test

python_version_full := $(wordlist 2,4,$(subst ., ,$(shell $(PYTHON) --version 2>&1)))
python_version_major := $(word 1,${python_version_full})
python_version_minor := $(word 2,${python_version_full})
python_version_patch := $(word 3,${python_version_full})

all: build.py
	@-mkdir -p test_results
	$(PYTHON) setup.py generate_main
ifneq ($(python_version_major),3)
	$(PYTHON) setup.py build_codes --inplace
else
	$(error you cannot build the codes in the source directories for Python 3, please run 'make build3')
endif

framework: build.py
	@-mkdir -p test_results
	$(PYTHON) setup.py generate_main
ifneq ($(python_version_major),3)
	$(PYTHON) setup.py build_libraries --inplace
else
	$(error you cannot build the codes in the source directories for Python 3, please run 'make build3')
endif

build.py:
	$(error the code is not configured, please run configure first)

allinbuild:
	$(PYTHON) setup.py build

support3/setup_codes.py:support/setup_codes.py
	2to3 -n -w -W support -o support3
	
build3:support3/setup_codes.py
	$(PYTHON) setup.py build

install3:support3/gen_codes.py
	$(PYTHON) setup.py install

docclean:
	make -C doc clean

clean:
	$(PYTHON) setup.py clean
	$(PYTHON) setup.py clean_codes --inplace

oclean:
	$(PYTHON) setup.py clean
	$(PYTHON) setup.py clean_codes --inplace --codes-dir=src/omuse/community

distclean:
	-rm -f config.mk
	-rm -f support/config.py
	-rm -f support/config.pyc
	-rm -f src/amuse/config.py
	-rm -f src/amuse/config.pyc
	-rm -f amuse.sh
	-rm -f iamuse.sh
	-rm -f ibis-deploy.sh
	-rm -f build.py
	
	-rm -f test/*.000 test/fort.* test/perr test/pout test/test.h5 test/*.log
	-rm -f test/codes_tests/perr test/codes_tests/pout
	-rm -f test/core_tests/plummer_back_100.ini
	-rm -f test/test_python_implementation test/twobody
	
	$(PYTHON) setup.py clean
	$(PYTHON) setup.py dist_clean
	$(PYTHON) setup.py dist_clean --inplace
	$(PYTHON) setup.py clean_codes --inplace --codes-dir=src/omuse/community
	
	make -C doc clean
	-find src -name "*.pyc" -exec rm \{} \;
	-find src -type d -name "__pycache__" -exec rm -Rf \{} \;
	-find src -type d -name "ccache" -exec rm -Rf \{} \;
	-rm -Rf build

tests:
	$(PYTHON) setup.py tests
	

doc:
	$(PYTHON) setup.py -q build_latex

html:
	make -C doc html

latexpdf:
	make -C doc latexpdf

ctags:
	find src -name "*.py" | xargs ctags
	find src -name "*.cc" | xargs ctags -a
	find src -name "*.[cCfFhH]" | xargs ctags -a
	find src -name "*.cpp" | xargs ctags -a

release: distclean
	sed 's/version = .*/version = "$(VERSION)",/' < setup.py > releasesetup.py
	cp setup.py setup.py.bck
	mv releasesetup.py setup.py 
	make -C doc release
	python setup.py  -q sdist
	cp setup.py.bck setup.py

nightly:
	make -C doc release
	sed 's/version = .*/version = "$(VERSION)",/' < setup.py > nightlysetup.py
	cp setup.py setup.py.bck
	mv nightlysetup.py setup.py 
	python setup.py sdist
	cp setup.py.bck setup.py
	
debian:
	$(PYTHON) ./support/debian.py


%.code:
ifneq (,$(findstring s,$(MAKEFLAGS)))
	$(PYTHON) setup.py build_code --inplace --clean=$(CLEAN) --code-name=$*
else
	$(PYTHON) setup.py -v build_code --inplace --clean=$(CLEAN) --code-name=$*
endif

%.ocode: | src/omuse
ifneq (,$(findstring s,$(MAKEFLAGS)))
	$(PYTHON) setup.py build_code --inplace --clean=$(CLEAN) --code-name=$* --codes-dir=src/omuse/community
else
	$(PYTHON) setup.py -v build_code --inplace --clean=$(CLEAN) --code-name=$* --codes-dir=src/omuse/community
endif

omuse: build.py  | src/omuse
	@-mkdir -p test_results
	$(PYTHON) setup.py generate_main
ifneq ($(python_version_major),3)
	$(PYTHON) setup.py build_codes --inplace --codes-dir=src/omuse/community
else
	$(error you cannot build the omuse codes in the source directories with Python 3 yet)
endif

src/omuse:
	@echo "src/omuse not present"
	@false

help:
	@echo "brief overview of most important make options:"
	@echo "make              - build all AMUSE libraries and community codes "
	@echo "make <name>.code  - clean & build the community code <name> (or matching name*)"
	@echo "make clean        - clean codes and libraries"
	@echo "make distclean    - clean codes and libraries and all configuration files"
ifeq (src/omuse ,$(wildcard src/omuse))
	@echo "make omuse        - build OMUSE community codes"
	@echo "make oclean       - clean OMUSE community codes"
	@echo "make <name>.ocode - build OMUSE community code <name>"
endif
