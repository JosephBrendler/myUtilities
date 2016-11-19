/***********************************************************************
 * KernelConfig.h
 * Joe Brendler
 * 28 January 2015
 * class definition --
 *     ingested linux kernel configuration file and associated utilities
 **********************************************************************/
#ifndef KernelConfig_h
#define KernelConfig_h

#include <ctime>        // time_t, time, ctime
#include <cstdio>       // printf, etc.
#include <unistd.h>     // POSIX - usleep
#include <iostream>     // cout << , etc.
#include <fstream>	// file operatons, e.g. myFile.close()
#include <string>	// string operations favored over char[]

#include <sys/ioctl.h>  // a linux header with io controls
#include <unistd.h>	// a POSIX header

#include "../colorHeader/colorHeader.h"
#include "../../Terminal/Terminal.h"

using namespace std;

class KernelConfig
{
  public:
    KernelConfig( char* name );
    int test();				// just a test function
    int load();				// load the parameter array
    int dump();				// dump the parameter array
    string parameter[6000];		// the name of a configuration parameter (e.g. "CONFIG_X86_64")
    string value[6000];			// the value of a configuration parameter (e.g. "y" or "is not set")
    int length;				// the number of lines in the configuration file
    int records;			// the number of configuration parameter records loaded
    int blanks;				// the number of blank lines (skipped)
    int comments;			// the number of comment lines (skipped)
    int set_params;			// the number of set parameters (set records loaded)
    int unset_params;			// the number of unset parameters (unset records loaded)
  private:
    bool _DEBUG;
    int _example;
    char* _filename;
    string _line;
    string _msg;
    Terminal _term;
};

#endif
