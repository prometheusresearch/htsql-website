PACKAGE = ../dist/htsql*.deb
all:
	 reprepro remove htsql htsql
	 reprepro --ask-passphrase -Vb . includedeb htsql $(PACKAGE)
