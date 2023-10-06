# To run locally: 
#   VERSION=9.0.0 make
#   
all:
	./build_debs.sh
	./build_rpms.sh
#   ./build_tgzs.sh
#   ./build_zips.sh
	file packages/*

clean:
	rm -rf packages
	rm -f mondoo.deb
