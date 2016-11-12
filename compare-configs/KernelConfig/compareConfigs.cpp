/*
 * kernelConfigLibTest.cpp
 * Joe Brendler
 * 28 January 2015
 * example program for running my kernel configuration file library
 */
#include "KernelConfig.h"
#include "../colorHeader/colorHeader.h"
#include "../Terminal/Terminal.h"

#include <fstream>      // file operatons, e.g. myFile.close()
#include <sys/ioctl.h>  // a linux header with io controls
#include <unistd.h>     // a POSIX header
#include <cstdlib>      // itoa(), etc

#include "../colorHeader/colorHeader.h"
#include "../Terminal/Terminal.h"

using namespace std;

int main ( int argc, char* argv[] )
{
//  bool DEBUGME = true;
  bool DEBUGME = false;

  bool include_same = false;  // set to true if you also want to see which settings are the same
  Terminal term;

  int i, j, d;
  bool found;

  char* filename1 = argv[1];
  char* filename2 = argv[2];
  char* filename[10];
  string tmp("");
  char* outfilename = (char*)tmp.c_str();;

  string argstr("");
  int filecount = 0;
  string msg("compareConfig");

  term.separator( msg );

  // print debug messages if requested --------------------------------------------------
  msg.assign("");
  if ( DEBUGME )
  {
    msg = msg + BR_ON + "DEBUGME" + B_OFF + " is set to " + BG_ON + "true" + B_OFF;
    term.message( msg );
  }
  // process command line arguments -----------------------------------------------------
  for (int x=1; x<argc; x++ )  // start with one to skip argv[0] which is the command name
  {
    if ( DEBUGME ) { cout << "argv[" << x << "] = " << argv[x] << endl; }
    argstr.assign( argv[x] );
    if ( argstr.substr(0,2) == "-o" )  // then this is an option to output to a file
    {
      if ( argstr.length() > 2 )  // then the output filename is concantenated with the -o
      { //outfilename = argstr.substr(2); }   // gram the rest of the string as the output filename
        outfilename = argv[x];
        int k = 2;
        while ( outfilename[k] ) { outfilename[k-2] = outfilename[k]; k++; }      // "shift string left"
        outfilename[k-2] = outfilename[k];  // one more time to get the string terminator
      }
      else  // the output file name is separated from the -o by whitespace
      { outfilename = argv[++x]; }          // grab the next arg as the output filename
    }
    else { filecount++; filename[filecount] = argv[x]; }  // otherwise, it's a config filename
  }

  // explain understanding of command line arguments -------------------------------------
  if ( outfilename[0] ) { cout << "per command line option, will output to file: " << outfilename << endl; }
  else { cout << "per command line, will output to screen." << endl; }
  cout << "per command line, will read and compare the following config files:" << endl;
  int f = 0;
  for (int x=1; x<=filecount; x++)
  {
    string front("");
    if ( x <= 2 ) { front = front + BG_ON + "   * " + B_OFF; } else { front = front + BR_ON + "   x " + B_OFF; }
    cout << front << "[" << x << "] " << filename[x] << endl;
  }
  string front("");
  cout << front + BG_ON + " *" + B_OFF + " = files to be compared.   " + BR_ON + "x" + B_OFF + " = these arguments ignored." << endl;
  int x = 0;
  if ( DEBUGME ) { while ( outfilename[x] ) { cout << outfilename[x++] << endl; } }

  KernelConfig myConfig1 ( filename[1] );
  KernelConfig myConfig2 ( filename[2] );

  // test open/close the file for output
  if ( outfilename[0] )
  {
    ofstream _myoutFile;
    _myoutFile.open( outfilename );
    if (_myoutFile.is_open())
    {
      msg = msg + "Your file [" + outfilename + "] is open.";
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

  // load the config files -------------------------------------------------------------
  term.right_status(myConfig1.load());
  term.right_status(myConfig2.load());

  cout << front << BG_ON << "* " << B_OFF << "myConfig1 was [ " << myConfig1.length << " ] lines, [ " <<myConfig1.records << " ] records.\n";
  cout << front << BG_ON << "* " << B_OFF << "myConfig2 was [ " << myConfig2.length << " ] lines, [ " <<myConfig2.records << " ] records.\n";

  // compare the two configs -----------------------------------------------------------
  if ( ! outfilename[0] )  // output to screen
  {
    cout << BW_ON << "Parameter" << B_OFF;
    cout << "\r";  term.CUF(40);
    cout << BR_ON << filename1 << B_OFF;
    cout << "\r";  term.CUF(75);
    cout << LB_ON << filename2 << B_OFF << endl;
  }
  else   // output to file
  {
    ofstream _myoutFile;
    _myoutFile.open( outfilename, ios::app );
    if (_myoutFile.is_open())
    {
      _myoutFile << d << " " << "Parameter, " << filename1 << ", " << filename2 << endl;
      _myoutFile.close();
    }
    else
    {
      msg = msg + "Your file [" + outfilename + "] failed to open.";
      term.E_message( msg );
      return 0;
    }
  }
  d = 1;  // count of parameters with differing setttings
  for ( i=0; i<myConfig1.records; i++ )
  {
    found = false;
    j = 0;
    while ( ( ! found ) && ( j < myConfig2.records ) )
    {
      if ( myConfig2.parameter[j] == myConfig1.parameter[i] )  //--- we found the record from 1 in 2
      {
        found = true;
        if ( myConfig2.value[j] == myConfig1.value[i] )        //--- same config setting (ignore?)
        {
          if ( include_same )
          {
            if ( ! outfilename[0] )  // output to screen
            {
              if ( (d % 2) == 0 )
              {
                cout << d << " " << W_ON << myConfig1.parameter[i] ;
                cout << "\r";  term.CUF(40);
                cout << R_ON << myConfig1.value[i] ;
                cout << "\r";  term.CUF(75);
                cout << L_ON << myConfig2.value[j] << B_OFF << endl;
              }
              else
              {
                cout << BW_ON << d << " " << myConfig1.parameter[i] ;
                cout << "\r";  term.CUF(40);
                cout << BR_ON << myConfig1.value[i] ;
                cout << "\r";  term.CUF(75);
                cout << LB_ON << myConfig2.value[j] << B_OFF << endl;
              }
            }
            else    // output to a fle
            {
              ofstream _myoutFile;
              _myoutFile.open( outfilename, ios::app );
              if (_myoutFile.is_open())
              {
                _myoutFile << d << "," << myConfig1.parameter[i] << "," << myConfig1.value[i] << "," << myConfig2.value[j] << endl;
                _myoutFile.close();
              }
              else
              {
                msg = msg + "Your file [" + outfilename + "] failed to open.";
                term.E_message( msg );
                return 0;
              }
            }  // output to screen or file
          }  // include same
        }
        else  //----------------- right record, different settings, print for comparison -------------
        {
          if ( ! outfilename[0] )  // output to screen
          {
            if ( (d % 2) == 0 )
            {
              cout << d << " " << W_ON << myConfig1.parameter[i] ;
              cout << "\r";  term.CUF(40);
              cout << R_ON << myConfig1.value[i] ;
              cout << "\r";  term.CUF(75);
              cout << L_ON << myConfig2.value[j] << B_OFF << endl;
            }
            else
            {
              cout << BW_ON << d << " " << myConfig1.parameter[i] ;
              cout << "\r";  term.CUF(40);
              cout << BR_ON << myConfig1.value[i] ;
              cout << "\r";  term.CUF(75);
              cout << LB_ON << myConfig2.value[j] << B_OFF << endl;
            }
          }
          else    // output to a file
          {
            ofstream _myoutFile;
            _myoutFile.open( outfilename, ios::app );
            if (_myoutFile.is_open())
            {
              _myoutFile << d << "," << myConfig1.parameter[i] << "," << myConfig1.value[i] << "," << myConfig2.value[j] << endl;
              _myoutFile.close();
            }
            else
            {
              msg = msg + "Your file [" + outfilename + "] failed to open.";
              term.E_message( msg );
              return 0;
            }
          }
          d++;
        }  // if-else (values are the same)
      }  // parameters are the same
      j++;
    }  // inner while loop
    if ( ! found )
    {
      if ( ! outfilename[0] )  // output to screen
      {
        if ( (d % 2) == 0 )
        {
          cout << d << " " << W_ON << myConfig1.parameter[i] ;
          cout << "\r";  term.CUF(40);
          cout << R_ON << myConfig1.value[i] ;
          cout << "\r";  term.CUF(75);
          cout << L_ON << "[ not found ]" << B_OFF << endl;
        }
        else
        {
          cout << BW_ON << d << " " << myConfig1.parameter[i] ;
          cout << "\r";  term.CUF(40);
          cout << BR_ON << myConfig1.value[i] ;
          cout << "\r";  term.CUF(75);
          cout << LB_ON << "[ not found ]" << B_OFF << endl;
        }
      }
      else    // output to a file
      {
        ofstream _myoutFile;
        _myoutFile.open( outfilename, ios::app );
        if (_myoutFile.is_open())
        {
          _myoutFile << d << "," << myConfig1.parameter[i] << "," << myConfig1.value[i] << ",[ not found ]" << endl;
          _myoutFile.close();
        }
        else
        {
          msg = msg + "Your file [" + outfilename + "] failed to open.";
          term.E_message( msg );
          return 0;
        }
      }
      d++;
    }  // not found
  }  // outer for loop
  cout << BM_ON << "-------------------------[ half-time answer: " << B_OFF << (d-1) << BM_ON << " records differ ]------------------------" << B_OFF << endl;

  // now find each record in file2 -- if not in file1, output comparison; ignore otherwise
  for ( i=0; i<myConfig2.records; i++ )
  {
    found = false;
    j = 0;
    while ( ( ! found ) && ( j < myConfig1.records ) )
    {
      if ( myConfig1.parameter[j] == myConfig2.parameter[i] )  //--- we found the record from 1 in 2
      { found = true; }
      j++;
    }  // inner while loop
    if ( ! found )
    {
      if ( ! outfilename[0] )  // output to screen
      {
        if ( (d % 2) == 0 )
        {
          cout << d << " " << W_ON << myConfig2.parameter[i] ;
          cout << "\r";  term.CUF(40);
          cout << R_ON << "[ not found ]" << B_OFF;
          cout << "\r";  term.CUF(75);
          cout << L_ON << myConfig2.value[i] << B_OFF << endl;
        }
        else
        {
          cout << BW_ON << d << " " << myConfig2.parameter[i] ;
          cout << "\r";  term.CUF(40);
          cout << BR_ON << "[ not found ]" << B_OFF;
          cout << "\r";  term.CUF(75);
          cout << LB_ON << myConfig2.value[i] << B_OFF << endl;
        }
      }
      else    // output to a file
      {
        ofstream _myoutFile;
        _myoutFile.open( outfilename, ios::app );
        if (_myoutFile.is_open())
        {
          _myoutFile << d << "," << myConfig2.parameter[i] << ",[ not found ]," << myConfig2.value[i] << endl;
          _myoutFile.close();
        }
        else
        {
          msg = msg + "Your file [" + outfilename + "] failed to open.";
          term.E_message( msg );
          return 0;
        }
      }
      d++;
    }  // not found
  }  // outer for loop
  d -= 1;
  if ( d > 0 ) { cout << "\nDone.  Found " << d << " records differring.\n\n"; }
}
