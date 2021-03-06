# Automation boilerplate

SHELL := /bin/bash
SUDO := $(shell test $${EUID} -ne 0 && echo "sudo")
# https://stackoverflow.com/questions/41302443/in-makefile-know-if-gnu-make-is-in-dry-run
DRY_RUN := $(if $(findstring n,$(firstword -$(MAKEFLAGS))),--dry-run)
.EXPORT_ALL_VARIABLES:

PKGDEPS=sudo python3-netifaces

LOCAL=/usr/local
LOCAL_SCRIPTS=
LIBSYSTEMD=/lib/systemd/system
SERVICES=mavproxy.service
SYSCFG=/etc/systemd

.PHONY = clean dependencies git-cache install
.PHONY = provision show-config test uninstall

default:
	@echo "Please choose an action:"
	@echo ""
	@echo "  dependencies: ensure all needed software is installed (requires internet)"
	@echo "  install: update programs and system scripts"
	@echo "  provision: interactively define the needed configurations (all of them)"
	@echo ""
	@echo "The above are issued in the order shown above.  dependencies is only done once."
	@echo "Once the system is setup, you can use provision to change settings."
	@echo ""

$(SYSCFG)/%.conf:
	./provision.sh $@ $(DRY_RUN)

clean:
	/bin/true

dependencies:
	@if [ ! -z "$(PKGDEPS)" ] && [ -z "$(DRY_RUN)" ] ; then \
		$(SUDO) apt-get update ; \
		$(SUDO) apt-get install -y $(PKGDEPS) ; \
	fi
	@./ensure-gpsd.sh $(DRY_RUN)
	@./ensure-mavproxy.sh $(DRY_RUN)

git-cache:
	git config --global credential.helper "cache --timeout=5400"

install: git-cache
	@for s in $(LOCAL_SCRIPTS) ; do $(SUDO) install -Dm755 $${s} $(LOCAL)/bin/$${s} ; done
	@for c in stop disable ; do $(SUDO) systemctl $${c} $(SERVICES) ; done ; true
	@for s in $(SERVICES) ; do $(SUDO) install -Dm644 $${s%.*}.service $(LIBSYSTEMD)/$${s%.*}.service ; done
	@if [ ! -z "$(SERVICES)" ] ; then $(SUDO) systemctl daemon-reload ; fi
	@for s in $(SERVICES) ; do $(SUDO) systemctl enable $${s%.*} ; done

provision:
	# NB: order is important in generating these files
	$(MAKE) --no-print-directory -B $(SYSCFG)/network.conf $(DRY_RUN)
	$(MAKE) --no-print-directory -B $(SYSCFG)/gpsd.conf $(DRY_RUN)
	$(MAKE) --no-print-directory -B $(SYSCFG)/ntpd.conf $(DRY_RUN)
	@for s in $(SERVICES) ; do $(MAKE) --no-print-directory -B $(SYSCFG)/$${s%.*}.conf $(DRY_RUN) ; done
	$(SUDO) systemctl restart mavproxy

show-config:
	@for s in network.conf gpsd.conf ntpd.conf $(SERVICES) ; do echo "*** $${s%.*}.conf ***" && $(SUDO) cat $(SYSCFG)/$${s%.*}.conf ; done
	@$(SUDO) cat /etc/network/interfaces

test:
	@gpspipe -r -n 20 127.0.0.1 2947
	@ntpq -p
	@date

uninstall:
	@if [ ! -z "$(LOCAL_SCRIPTS)" ] ; then ( cd $(LOCAL)/bin && $(SUDO) rm $(LOCAL_SCRIPTS) ) ; fi
	@-for c in stop disable ; do $(SUDO) systemctl $${c} $(SERVICES) ; done
	@for s in $(SERVICES) ; do $(SUDO) rm $(LIBSYSTEMD)/$${s%.*}.service ; done
	@if [ ! -z "$(SERVICES)" ] ; then $(SUDO) systemctl daemon-reload ; fi

