.PHONY: build build-inplace serve

include Makefile.env

build: htsql htraf
	rm -rf ${BUILD_DIR}
	mkdir ${BUILD_DIR}
	cd htsql; hg pull -u
	cd htraf; hg pull -u; PYTHONPATH=../htsql/src ${MAKE} build
	rsync -aC static/* ${BUILD_DIR}
	rsync -aC htraf/build/htraf ${BUILD_DIR}
	PYTHONPATH=htsql/src:htsql/doc:htraf/doc/extensions:sphinx/extensions \
	sphinx-build -a -b html -c sphinx tree ${BUILD_DIR}
	-mv ${OUTPUT_DIR} ${OLD_OUTPUT_DIR}
	mv ${BUILD_DIR} ${OUTPUT_DIR}
	rm -rf ${OLD_OUTPUT_DIR}

test:
	PYTHONPATH=htsql/src:htsql/doc:htraf/doc/extensions:sphinx/extensions \
	sphinx-build -a -b html -c sphinx tree ${OUTPUT_DIR}
	python serve.py "${OUTPUT_DIR}" "${HTTP_HOST}" "${HTTP_PORT}"

htsql:
	hg clone https://bitbucket.org/prometheus/htsql

htraf:
	hg clone https://bitbucket.org/prometheus/htraf

serve:
	python serve.py "${OUTPUT_DIR}" "${HTTP_HOST}" "${HTTP_PORT}"

