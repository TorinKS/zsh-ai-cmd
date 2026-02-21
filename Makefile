NAME=zsh-ai-cmd

INSTALL?=install -c
PREFIX?=/usr/local
SHARE_DIR?=$(DESTDIR)$(PREFIX)/share/$(NAME)
DOC_DIR?=$(DESTDIR)$(PREFIX)/share/doc/$(NAME)
ZSH?=zsh

install:
	$(INSTALL) -d $(SHARE_DIR)
	$(INSTALL) -d $(SHARE_DIR)/functions
	$(INSTALL) -d $(SHARE_DIR)/providers
	$(INSTALL) -d $(DOC_DIR)
	cp ai-cmd.plugin.zsh $(SHARE_DIR)
	cp functions/_ai-cmd-* $(SHARE_DIR)/functions
	cp providers/*.zsh $(SHARE_DIR)/providers
	cp -R docs/* $(DOC_DIR)
	if [ x"true" = x"`git rev-parse --is-inside-work-tree 2>/dev/null`" ]; then \
		git rev-parse HEAD; \
	else \
		cat .revision-hash; \
	fi > $(SHARE_DIR)/.revision-hash

test:
	@$(ZSH) -fc 'echo ZSH_PATCHLEVEL=$$ZSH_PATCHLEVEL'
	@$(ZSH) tests/run.zsh

clean:

.PHONY: install test clean
