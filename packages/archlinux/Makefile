update: update-cnquery update-cnspec update-mondoo

update-cnquery:
	mkdir cnquery
	go run ./generator/main.go cnquery ./cnquery

update-cnspec:
	mkdir cnspec
	go run ./generator/main.go cnspec ./cnspec

update-mondoo:
	go run ./generator/main.go mondoo ./mondoo

clean:
	rm -rf cnquery/ cnspec/ mondoo/PKGBUILD mondoo/.SRCINFO
