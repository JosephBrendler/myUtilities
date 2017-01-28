CXX=g++
#uncomment below to debug (set the "-g" flag)
#DEBUG=-g

all: terminalLibTest libTerminal.so progress

terminalLibTest: libTerminal.so terminalLibTest.o
	$(CXX) $(DEBUG) terminalLibTest.cpp -o terminalLibTest -L. -lTerminal

libTerminal.so: Terminal.cpp
	$(CXX) $(DEBUG) -fPIC -c Terminal.cpp -o Terminal.o
	$(CXX) $(DEBUG) -shared -Wl,-soname,libTerminal.so -o libTerminal.so Terminal.o

progress: progress.cpp libTerminal.so
	$(CXX) $(DEBUG) progress.cpp -o progress -L. -lTerminal

install:
	cp -v libTerminal.so /usr/lib/

examples_install:
	cp -v terminalLibTest /usr/local/bin/
	cp -v progress /usr/local/bin/
	cp -v progress-example.sh /usr/local/bin/
	cp -v Terminal.h /usr/include/
	cp -v colorHeader.h /usr/include/

clean:
	rm -fv *.o *.so
	rm -fv terminalLibTest
	rm -fv progress
	rm -fv /usr/lib/libTerminal.so
	rm -fv /usr/local/bin/terminalLibTest
	rm -fv /usr/local/bin/progress*
