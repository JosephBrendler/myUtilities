/********************************************************************
 * KernelConfig.cpp
 * Joe Brendler
 * 28 January 2015
 * ingested linux kernel configuration file and associated utilities
 ********************************************************************/

using namespace std;

#include "KernelConfig.h"

//constructor
KernelConfig::KernelConfig( char* name )
{
   _DEBUG = false ;
   _filename = name ;
   _line = "";
}


//public member function(s)
int KernelConfig::test()
{
  ifstream _myFile ( _filename );
  _msg.assign("");
  // print debug messages if requested
  if ( _DEBUG ) { cout << "Proof of life " << BG_ON << "test," << B_OFF << " now complete.\n"; }
  if ( _DEBUG ) { printf ( "DEBUG is set to true [%d]\n", _DEBUG ); }
  if (_myFile.is_open())
  {
    _msg = _msg + "Your file [" + _filename + "] is open.";
    _term.message( _msg );
    _myFile.close();
    _msg.assign(""); _msg = _msg + "Your file [" + _filename + "] is closed.";
    _term.message( _msg );
  }
  else
  {
    _msg = _msg + "Your file [" + _filename + "] failed to open.";
    _term.E_message( _msg );
  }
  return 1;
}

//****************** load ******************************
int KernelConfig::load()
{

  // if already loaded, ask confirm reload?
  ifstream _myFile ( _filename );
  int i = 0;   // line count
  int r = 0;   // record count
  size_t idx;  // index for substring ops
  _msg.assign("");

  cout << "Loading " << _filename << "...";

  if (_myFile.is_open())
  {
    if ( _DEBUG) {_msg = _msg + "Your file [" + _filename + "] is open."; _term.message( _msg ); }
    while ( getline (_myFile,_line) )
    {
      // read the line and parse it according to the 4 cases I'm aware of:
      // (1) leading "#" but blank or otherwise does not contain a "CONFIG_" setting (ignore these)
      // (2) leading "#" and contains a "CONFIG_" that "is not set"
      // (3) "CONFIG_" is set with "=" to one of [y|n|m] or another string value
      // (4) evidently blank (ignore these, too)
//      this->parameter[i] = _line ;
      // if the 1st char is a "#", it's case (1) or (2)
      if ( _line.substr(0,1) == "#" )  //----------- (1) or (2) # line --------------------------
      {
        idx = _line.find("is not set");
        if ( idx != string::npos )  //-------------- (2) # ... is not set -----------------------
        {
//          cout << "is not set, found at [" << idx << "]." << endl;
          this->parameter[i] = _line.substr(2,(idx-3));  // skip "# " and go up to *before* " is not"
          this->value[i] = "is not set";
          r++;
        }  //--------------(ignore the "else" case)--(1) # ... (ignore these)
      }
      else  //---------------------------------------(3) no #, so CONFIG_ is set ----------------
      {
        idx = _line.find("=");
        if ( idx != string::npos )  // load all up to the "=" in parameter, and all after "=" in value
        {
          this->parameter[i] = _line.substr(0,(idx));  // up to *prior* to the =
          this->value[i] = _line.substr(idx+1);  // from *after* the =, to the end
          r++;
        }
        else  //-------------------------------------(4) blank -- (ignore)  ------------------------
        {
//          _term.E_message ( "Error:  = sign not found when it should have been." );
//          cout << "_line: " << _line << endl;
        }
      }
      i++;
    }
    this->records = r;
    this->length = i;
    _myFile.close();
  }
  else
  {
    _msg = _msg + "Your file [" + _filename + "] failed to open.";
    _term.E_message( _msg );
    i = 0;
  }
  cout << " done." << endl;
  return i;
}

//****************** dump ******************************
int KernelConfig::dump()
{
  //to do: check if it's loaded first
  int i = 0;
  _msg.assign("");
  while ( i < this->length )
  {
      cout << "parameter[" << i << "] = " << this->parameter[i] << endl;
      cout << "value[" << i << "] = " << this->value[i] << endl;
      i++;
  }
  return i;
}
