CXX=g++
#uncomment below to debug (set the "-g" flag)
#DEBUG=-g

all: libKernelConfig.so compareConfigs.o kernelConfigLibTest.o

compareConfigs: libKernelConfig.so compareConfigs.o compareConfigs.cpp
	$(CXX) $(DEBUG) compareConfigs.cpp -o compareConfigs -L. -lKernelConfig -L ../../Terminal -lTerminal

kernelConfigLibTest: libKernelConfig.so kernelConfigLibTest.o kernelConfigLibTest.cpp
	$(CXX) $(DEBUG) kernelConfigLibTest.cpp -o kernelConfigLibTest -L. -lKernelConfig -L ../../Terminal -lTerminal

libKernelConfig.so: KernelConfig.cpp
	$(CXX) $(DEBUG) -fPIC -c KernelConfig.cpp -o KernelConfig.o
	$(CXX) $(DEBUG) -shared -Wl,-soname,libKernelConfig.so -o libKernelConfig.so KernelConfig.o

install:
	sudo cp -v libKernelConfig.so /usr/lib/
	sudo cp -v compareConfigs /root/bin/

clean:
	rm -fv *.o *.so
	sudo rm -fv /usr/lib/libKernelConfig.so
	sudo rm -fv /root/bin/compareConfigs
	rm -fv compareConfigs
	rm -fv kernelConfigLibTest
