CXX=g++
#uncomment below to debug (set the "-g" flag)
#DEBUG=-g

compareConfigs: libKernelConfig.so compareConfigs.o
	$(CXX) $(DEBUG) compareConfigs.cpp -o compareConfigs -L. -lKernelConfig -lTerminal


libKernelConfig.so: KernelConfig.cpp
	$(CXX) $(DEBUG) -fPIC -c KernelConfig.cpp -o KernelConfig.o
	$(CXX) $(DEBUG) -shared -Wl,-soname,libKernelConfig.so -o libKernelConfig.so KernelConfig.o

install:
	cp -v libKernelConfig.so /usr/lib/
	cp -v compareConfigs /root/bin/

clean:
	rm -fv *.o *.so
	rm -fv /usr/lib/libKernelConfig.so
	rm -fv /root/bin/compareConfigs
