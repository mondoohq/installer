update: update-mql update-cnspec update-mondoo

update-mql:
	mkdir mql
	go run ./generator/main.go mql ./mql

update-cnspec:
	mkdir cnspec
	go run ./generator/main.go cnspec ./cnspec

update-mondoo:
	go run ./generator/main.go mondoo ./mondoo

clean:
	rm -rf mql/ cnspec/ mondoo/PKGBUILD mondoo/.SRCINFO
