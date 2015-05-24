PREFIX = /usr/local
SOURCE = lj.sh
NAME = lj

install:
	@echo installing executable file to ${PREFIX}/bin
	@mkdir -p ${PREFIX}/bin
	@cp -f ${SOURCE} ${PREFIX}/bin/${NAME}
	@chmod 755 ${PREFIX}/bin/${NAME}

uninstall:
	@echo removing executable file from ${PREFIX}/bin
	@rm -f ${PREFIX}/bin/${NAME}
