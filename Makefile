all:
	@echo Try \'make install\'

install:
	sudo install --mode=555 --owner=root --group=root moodbar-updater.pl /usr/local/bin
	sudo install --mode=555 --owner=root --group=root moodbar-updater-cron.sh /etc/cron.weekly
