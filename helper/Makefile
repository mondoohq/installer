# To run locally:
#   VERSION=9.0.0 make
# To run in Docker (works on macOS):
#   VERSION=13.0.0-rc4 make docker
#
all:
	./build_debs.sh
	./build_rpms.sh
#   ./build_tgzs.sh
#   ./build_zips.sh
	file packages/*

docker:
	rm -rf packages
	docker build --platform linux/amd64 --build-arg VERSION=$(VERSION) -t mondoo-pkgs-build .
	docker create --name mondoo-pkgs-tmp mondoo-pkgs-build
	docker cp mondoo-pkgs-tmp:/build/packages/. ./packages
	docker rm mondoo-pkgs-tmp
	docker rmi mondoo-pkgs-build

clean:
	rm -rf packages
	rm -f mondoo.deb
