/*
 * kernelConfigLibTest.cpp
 * Joe Brendler
 * 28 January 2015
 * example program for running my kernel configuration file library
 */

#include "KernelConfig.h"
#include "colorHeader.h"
#include "Terminal.h"

#include <fstream>      // file operatons, e.g. myFile.close()
#include <sys/ioctl.h>  // a linux header with io controls
#include <unistd.h>     // a POSIX header
#include <cstdlib>      // itoa(), etc
#include <stdlib.h>
#include <string>
#include <iostream>
#include <cstdio>

using namespace std;

int main ( int argc, char* argv[] )
{
//  bool DEBUGME = true;
  bool DEBUGME = false;

  bool include_same = false;  // set to true if you also want to see which settings
                              //   are the same in both configurations
  Terminal term;

  int i, j, x, k;
  int totalsum;

  char* filename1 = argv[1];
  char* filename[10];
  string tmp("");
  char str_int[10];          // generic integer to be output as part of a string
  char str_blanks[10];
  char str_comments[10];
  char str_set_params[10];
  char str_unset_params[10];
  char str_totalsum[10];
  char* outfilename = (char*)tmp.c_str();;

  string argstr("");
  int filecount = 0;
  string msg("compareConfig");

  term.separator( msg );

  // print debug messages if requested --------------------------------------------------
  msg.assign("");
  if ( DEBUGME )
  {
    msg = msg + BR_ON + "DEBUGME" + B_OFF + " is set to " + BG_ON + "true" + B_OFF ;
    term.message( msg );
  }
  // process command line arguments -----------------------------------------------------
  // if no arguments are given, explain usage
  if (argc <= 1)
  {
    // error - there is no input filename
    msg.assign("Error: you must specify an input config file name") ;
    term.message( msg ) ;
    exit(EXIT_FAILURE);
  }
  for (x=1; x<argc; x++ )  // start with one to skip argv[0] which is the command name
  {
    if ( DEBUGME ) { cout << "argv[" << x << "] = " << argv[x] << endl; }
    argstr.assign( argv[x] );
    if ( argstr.substr(0,2) == "-o" )  // then this is an option to output to a file
    {
      if ( argstr.length() > 2 )  // then the output filename is concantenated with the -o
      { //outfilename = argstr.substr(2); }   // grab the rest of the string as the output filename
        outfilename = argv[x];
        k = 2;
        while ( outfilename[k] ) { outfilename[k-2] = outfilename[k]; k++; }      // "shift string left"
        outfilename[k-2] = outfilename[k];  // one more time to get the string terminator
      }
      else  // the output file name is separated from the -o by whitespace
      { outfilename = argv[++x]; }          // grab the next arg as the output filename
    }
    else { filecount++; filename[filecount] = argv[x]; }  // otherwise, it's a config filename
  }

  // explain understanding of command line arguments -------------------------------------
//  if ( outfilename[0] ) { cout << "per command line option, will output to file: " << outfilename << endl; }
//  else { cout << "per command line, will output to screen." << endl; }

//  cout << "per command line, will read and compare the following config files:" << endl;
  if ( outfilename[0] )
  {
    msg.assign("");
    msg = msg +"per command line option, will output to file: " + outfilename;
    term.message( msg );
  }
  else { term.message( "per command line, will output to screen." ); }

  term.message( "per command line, will read and handle the following config file(s):" );
  for (x=1; x<=filecount; x++)
  {
    string front("");
    if ( x <= 1 ) { front = front + BG_ON + "   * " + B_OFF; } else { front = front + BR_ON + "   x " + B_OFF; }
    sprintf(str_int, "%d", x);
    msg.assign(""); msg = msg + front + "[" + str_int + "] " + filename[x]; term.message( msg );
  }
  msg.assign(""); msg = msg + BG_ON + " *" + B_OFF + " = files to be handled.   " + BR_ON + "x" + B_OFF + " = these arguments ignored."; term.message( msg );

  if ( DEBUGME )
  {
    x = 0;
    term.message( "Debug: outfilename one char at a time." );
    while ( outfilename[x] ) { cout << outfilename[x++] << endl; }
   }

  KernelConfig myConfig1 ( filename[1] );

  // test open/close the file for output
  if ( outfilename[0] )  // first element of character array is not null
  {
    ofstream _myoutFile;
    _myoutFile.open( outfilename );
    if (_myoutFile.is_open())
    {
      msg.assign(""); msg = msg + "Your file [" + outfilename + "] is open.";
      term.message( msg );
      _myoutFile.close();
      msg.assign(""); msg = msg + "Your file [" + outfilename + "] is closed.";
      term.message( msg );
    }
    else
    {
      msg = msg + "Your file [" + outfilename + "] failed to open.";
      term.E_message( msg );
      return 0;
    }
  }

  // load a config file -------------------------------------------------------------
  term.right_status(myConfig1.load());

  sprintf(str_totalsum, "%d", myConfig1.length);
  sprintf(str_int, "%d", myConfig1.records);
  msg.assign(""); msg = msg + "myConfig1 was [ " + str_totalsum + " ] lines, [ " + str_int + " ] records."; term.message( msg );

  // perform integrity check
  msg.assign(""); msg = msg + BM_ON + "Perform integrity check..." + B_OFF; term.message( msg );
  sprintf(str_blanks, "%d", myConfig1.blanks);
  sprintf(str_comments, "%d", myConfig1.comments);
  sprintf(str_set_params, "%d", myConfig1.set_params);
  sprintf(str_unset_params, "%d", myConfig1.unset_params);
  msg.assign("Number of blank lines..........: "); msg.append( str_blanks); term.message( msg );
  msg.assign(""); msg = msg + "Number of comment lines........: " + str_comments; term.message( msg );
  msg.assign(""); msg = msg + "Number of set parameter lines..: " + str_set_params; term.message( msg );
  msg.assign(""); msg = msg + "Number of unset parameter lines: " + str_unset_params; term.message( msg );
  totalsum = myConfig1.blanks + myConfig1.comments + myConfig1.set_params + myConfig1.unset_params;
  sprintf(str_totalsum, "%d", totalsum);
  msg.assign(""); msg = msg + "Total (blank, comment, set, unset) = " + str_totalsum + " (should equal # lines above)"; term.message( msg );
  totalsum = myConfig1.set_params + myConfig1.unset_params;
  sprintf(str_totalsum, "%d", totalsum);
  msg.assign(""); msg = msg + "Total (set, unset) = " + str_totalsum + " (should equal # records above)"; term.message( msg );
  term.message ( "" );  // echo a blank line
  // dump the config ----------------------------------------------------------------
  term.message( "Dumping config..." );
  myConfig1.dump();
  term.message ( "" );

  if ( DEBUGME )
  {
    msg.assign("");
    msg = msg + BM_ON + "About to provide output either to screen or file, based on outfilename[0] which evaluates to [" + B_OFF + outfilename[0] + BM_ON + "]" + B_OFF;
    term.message( msg );
  }
  // output the headings
  if ( ! outfilename[0] )  // output to screen
  {
    term.message( "Sending output to screen." );
    cout << BW_ON << "#   " << "Parameter" << B_OFF;
    cout << "\r";  term.CUF(40);
    cout << BR_ON << filename1 << B_OFF << endl;
  }
  else   // output to file
  {
    msg.assign(""); msg = msg + "Sending output to file: " + outfilename; term.message( msg );
    ofstream _myoutFile;
    _myoutFile.open( outfilename, ios::app );
    if (_myoutFile.is_open())
    {
      _myoutFile << "#  " << "Parameter, " << filename1 << endl;
      _myoutFile.close();
    }
    else
    {
      msg = msg + "Your file [" + outfilename + "] failed to open.";
      term.E_message( msg );
      return 0;
    }
  }
  // output each record
  
//  for ( i=0; i<myConfig1.length; i++ )
  for ( i=0; i<myConfig1.records; i++ )
  {
            if ( ! outfilename[0] )  // output to screen
            {
              if ( (i % 2) == 0 )
              {
                cout << W_ON << i << "  " << myConfig1.parameter[i] ;
                cout << "\r";  term.CUF(40);
                cout << R_ON << myConfig1.value[i] << B_OFF << endl;
              }
              else
              {
                cout << BW_ON << i << "  " << myConfig1.parameter[i] ;
                cout << "\r";  term.CUF(40);
                cout << BR_ON << myConfig1.value[i] << B_OFF << endl;
              }
            }
            else    // output to a fle
            {
              ofstream _myoutFile;
              _myoutFile.open( outfilename, ios::app );
              if (_myoutFile.is_open())
              {
                _myoutFile << myConfig1.parameter[i] << "," << myConfig1.value[i] << endl;
                _myoutFile.close();
              }
              else
              {
                msg = msg + "Your file [" + outfilename + "] failed to open.";
                term.E_message( msg );
                return 0;
              }
            }  // end if - output to screen or file
  }  // outer for loop - iterate through all records in myConfig1
}
