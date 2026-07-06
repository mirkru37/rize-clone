.PHONY: docs-build docs-serve

DOCS_VENV ?= .venv-docs

$(DOCS_VENV)/bin/mkdocs: requirements-docs.txt
	python3 -m venv $(DOCS_VENV)
	$(DOCS_VENV)/bin/pip install --quiet -r requirements-docs.txt

docs-build: $(DOCS_VENV)/bin/mkdocs
	$(DOCS_VENV)/bin/mkdocs build

docs-serve: $(DOCS_VENV)/bin/mkdocs
	$(DOCS_VENV)/bin/mkdocs serve
