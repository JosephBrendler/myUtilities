CXX=g++
#uncomment below to debug (set the "-g" flag)
#DEBUG=-g

all: libKernelConfig.so compareConfigs kernelConfigLibTest

compareConfigs: libKernelConfig.so compareConfigs.o compareConfigs.cpp
	$(CXX) $(DEBUG) compareConfigs.cpp -o compareConfigs -L. -lKernelConfig -L /usr/lib/ -lTerminal

kernelConfigLibTest: libKernelConfig.so kernelConfigLibTest.o kernelConfigLibTest.cpp
	$(CXX) $(DEBUG) kernelConfigLibTest.cpp -o kernelConfigLibTest -L. -lKernelConfig -L /usr/lib/ -lTerminal

libKernelConfig.so: KernelConfig.cpp
	$(CXX) $(DEBUG) -fPIC -c KernelConfig.cpp -o KernelConfig.o
	$(CXX) $(DEBUG) -shared -Wl,-soname,libKernelConfig.so -o libKernelConfig.so KernelConfig.o

install:
	cp -v libKernelConfig.so /usr/lib/
	cp -v compareConfigs /usr/bin/
	cp -v kernelConfigLibTest /usr/bin/
	cp -v comparam.sh /usr/bin/
	cp -v compare-configs.sh /usr/bin/
	cp -v KernelConfig.h /usr/include/

clean:
	rm -fv /usr/lib/libKernelConfig.so
	rm -fv /usr/bin/compareConfigs
	rm -fv /usr/bin/kernelConfigLibTest
	rm -fv /usr/bin/comparam.sh
	rm -fv /usr/bin/compare-configs.sh
	rm -fv /usr/include/KernelConfig.h
	rm -fv compareConfigs
	rm -fv kernelConfigLibTest
	rm -fv *.o *.so
