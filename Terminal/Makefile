CXX=g++
#uncomment below to debug (set the "-g" flag)
#DEBUG=-g

terminalLibTest: libTerminal.so terminalLibTest.o
	$(CXX) $(DEBUG) terminalLibTest.cpp -o terminalLibTest -L. -lTerminal

libTerminal.so: Terminal.cpp
	$(CXX) $(DEBUG) -fPIC -c Terminal.cpp -o Terminal.o
	$(CXX) $(DEBUG) -shared -Wl,-soname,libTerminal.so -o libTerminal.so Terminal.o

progress: libTerminal.so
	$(CXX) $(DEBUG) progress.cpp -o progress -L. -lTerminal

install:
	cp -v libTerminal.so /usr/lib/

clean:
	rm -fv *.o *.so
	rm -fv /usr/lib/libTerminal.so
