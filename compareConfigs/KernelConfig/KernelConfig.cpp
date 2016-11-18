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
  int b = 0;  // blank line count
  int c = 0;  // comment line count
  int s = 0;  // set parameter count
  int u = 0;  // unset parameter count
  size_t idx;  // index for substring ops
  _msg.assign("");

  cout << "Loading " << _filename << "...";

  if (_myFile.is_open())
  {
    if ( _DEBUG) {_msg = _msg + "Your file [" + _filename + "] is open."; _term.message( _msg ); }
    while ( getline (_myFile,_line) )
    {
      // read the line and parse it according to the 4 cases I'm aware of:
      // (1) (comments, c) leading "#" but blank or otherwise does not contain a "CONFIG_" setting (ignore these)
      // (2) (unset_params, u) leading "#" and contains a "CONFIG_" that "is not set"
      // (3) (set_params, s) "CONFIG_" is set with "=" to one of [y|n|m] or another string value
      // (4) (blanks, b) evidently blank (ignore these, too)
//      this->parameter[i] = _line ;
      // if the 1st char is a "#", it's case (1) or (2)
      if ( _line.substr(0,1) == "#" )  //----------- (1) or (2) # line --------------------------
      {
        idx = _line.find("is not set");
        if ( idx != string::npos )  //-------------- (2) # ... is not set -----------------------
        {
//          cout << "is not set, found at [" << idx << "]." << endl;
//          this->parameter[i] = _line.substr(2,(idx-3));  // skip "# " and go up to *before* " is not"
//          this->value[i] = "is not set";
          this->parameter[r] = _line.substr(2,(idx-3));  // skip "# " and go up to *before* " is not"
          this->value[r] = "is not set";                 // note: set record number r, not i - which would leave blanks
          u++;
          r++;
        }
        else  //--------------(ignore the "else" case)--(1) # ... (ignore these; just count them)
        {
          c++;
        }
      }
      else  //---------------------------------------(3) no #, so CONFIG_ is set ----------------
      {
        idx = _line.find("=");
        if ( idx != string::npos )  // load all up to the "=" in parameter, and all after "=" in value
        {
//          this->parameter[i] = _line.substr(0,(idx));  // up to *prior* to the =
//          this->value[i] = _line.substr(idx+1);  // from *after* the =, to the end
          this->parameter[r] = _line.substr(0,(idx));  // up to *prior* to the =
          this->value[r] = _line.substr(idx+1);  // from *after* the =, to the end (again, set [r] not [i])
          s++;
          r++;
        }
        else  //-------------------------------------(4) blank -- (ignore; just count)  ------------------------
        {
//          _term.E_message ( "Error:  = sign not found when it should have been." );
//          cout << "_line: " << _line << endl;
          b++;
        }
      }
      i++;  // go to next line in the file
    }
    this->length = i;         // this should equal the sum of b + c + s + u
    this->records = r;        // this should equal the sum of s + u
    this->blanks = b;
    this->comments = c;
    this->set_params = s;
    this->unset_params = u;
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
  char str_int[10];  // generic integer to be displayed as part of a string
  while ( i < this->records )
  {
    sprintf(str_int, "%d", i);
    _msg.assign("");
     _msg = _msg + "parameter[" + str_int + "] = " + this->parameter[i] + "     value[" + str_int + "] = " +this->value[i];
     _term.message( _msg );
      i++;
  }
  return i;
}
