/***************************************************************
 * Terminal.cpp
 * Joe Brendler
 * 28 January 2015
 * easy (linux) terminal functions for my c++ programs
 **************************************************************/

#include "Terminal.h"

using namespace std;

//constructor
Terminal::Terminal()
{
  #ifdef TIOCGSIZE
    ioctl(STDIN_FILENO, TIOCGSIZE, &_ts);
    _cols = _ts.ts_cols;
    _lines = _ts.ts_lines;
  #elif defined(TIOCGWINSZ)
    ioctl(STDIN_FILENO, TIOCGWINSZ, &_ts);
    _cols = _ts.ws_col;
    _lines = _ts.ws_row;
  #endif /* TIOCGSIZE */

}

//public member function(s)
int Terminal::width()
{
  return _cols;
}

int Terminal::height()
{
  return _lines;
}

//---[ Basic Utilities ]-------------------------------------------

//*************** repeat ************************//
string Terminal::repeat( char *ch, int limit )  // output a repeated string of character (arg $1) of length (arg $2)
{
  string out_str;
  for ( int i=0; i<limit; i++ ) { out_str += ch; }
  return out_str;
}

//*************** message ************************//
void Terminal::message ( string msg )  // print out message after a green asterisk
{ cout << BG_ON << "* " << B_OFF << msg << endl; }

//*************** E_message ************************//
void Terminal::E_message ( string msg )  // print out error message after a red asterisk
{ cout << BR_ON << "* " << B_OFF << msg << endl; }

//*************** separator ************************//
void Terminal::separator( string title )     // draw a horizontal line with a simple title
{
  char _dash[2] = {'-','\0'};
  string msg( "" );  int msg_len;
  msg = msg + BY_ON + "---[ " + LB_ON + title + BY_ON + " ]";
  msg_len = msg.length() - (3*7);   // 3 x color-on (all 7)
  cout << msg << this->repeat(_dash, (this->width() - msg_len)) << B_OFF << endl;
}

//*************** countdown ************************//
bool Terminal::countdown( int duration )
{
  int i = 1;
  cout << "\n";
  while ( i <= duration )
  {
    sleep( 1 );  // seconds <unistd.h>
//    cout << "\r";
    cout << BG_ON << "*" << B_OFF << " Pausing. [ " << BG_ON << (duration - i) << B_OFF << " ] seconds remaining..." << endl;
    i++;
    this->CUU(1);
  }
  cout << "\n";
  return true;
}

//*************** right_status ************************//
void Terminal::right_status( int status )  // output a boolean status (arg) at the right margin
{
  char _space[2] = {' ','\0'};
  int lpad, rpad, msg_len;
  string msg( "" );
  string out_msg( "" );
  if ( status > 0 ) { msg = msg + BG_ON + "Ok" + B_OFF; lpad=2; rpad= 2; }
  else { msg = msg + BR_ON + "Fail" + B_OFF; lpad=1; rpad=1; }
  out_msg = out_msg + BB_ON + "[" + B_OFF + repeat(_space, lpad) + msg + repeat(_space, rpad) + BB_ON + "]" + B_OFF;
  msg_len= out_msg.length() - ((3*7) + (3*5));  // 3 x color-on and 3 x color-off
  // up one (because of \n in last output); go left margin; right to status position
  this->CUU(1); cout << "\r";  this->CUF( this->width() - msg_len -1 );
  cout << out_msg << endl;
}

//*************** progress ***************************//
void Terminal::progress( int step, int num_steps )     // display an arrow depicting progress (visualize arg[1] of arg[2] steps complete
{
   //global variables
  char _marker[2] = {'-','\0'};
  char _dash[2] = {'-','\0'};
  char _bracket[2] = {'|','\0'};
  char _arrowhead[2] = {'>','\0'};
  char _space[2] = {' ','\0'};
  // Configurable variables                            //
  int margin = 15; int i=0;
  std::string line = ""; std::string percentcolor = "";
  // Analytically determined variables
  int termwidth = this->width();    int percentstart = termwidth - 9;
  int range = (termwidth -3 -(margin * 2));           // -3 accounts for the two margin _marker _brackets "|" and the _arrowhead ">"
  int myprogress = (int)( ( range * step ) / num_steps );   // how many _marker to draw to represent a single step of progress
  int start = ( margin + 1 );    int end = ( termwidth - margin - 1 );  // this is where the _brackets go
  int myrow = this->height();    int startofline = ( start + 1 );
  int endofline = startofline + myprogress;
  if ( endofline >= (end-2) ) { endofline = ( end - 2 ); }  int lengthofline = ( endofline - startofline +1 );
  int percent = ( (100 *  step) / num_steps );
  if ( percent < 70 ) { percentcolor = BR_ON; } else if ( percent >= 90 ) { percentcolor = BG_ON; } else { percentcolor = BY_ON; }
  // action: start with null string, and append all necessary parts
  for ( i=0; i<margin; i++ ) { line.append(_space); }
  line.append(_bracket);
  for ( i=startofline; i <= endofline; i++) { line.append(_marker); }
  line.append(_arrowhead);
  for ( i=endofline+1; i<end; i++ ) { line.append(_space); }
  line.append(_bracket);
  for ( i=end; i<termwidth-1; i++) { line.append(_space); }
  this->CUP( myrow, 1 );
  this->SCP();
//  this->HCU();
  std::cout << line;
  this->CUP( myrow, percentstart );
  cout << "( " << percentcolor << percent << "%" << B_OFF << " )";
  this->RCP();
//  this->SCU();
}

//*************** summarize_me ***********************//
bool Terminal::summarize_me()   // summarize what the utilities in this library do
{
  string msg("");
  this->separator( "Terminal.h c++ screen utility library | content summary" );
  msg = msg + "This script header defines some " + BY_ON + "common variables" + B_OFF + " for";
  this->message( msg ); msg.assign("");
  msg = msg + "  use in various programs, it provides pre-formatted " + BY_ON + "easy-to-use" + B_OFF;
  this->message( msg ); msg.assign("");
  msg = msg + "  " + BY_ON + "ANSI Escape sequences" + B_OFF + " to facilitate the use of " + BM_ON + "color" + B_OFF + " and";
  this->message( msg ); msg.assign("");
  msg = msg + "  " + BY_ON + "cursor" + B_OFF + " movement in my programs, and it provides a number of";
  this->message( msg ); msg.assign("");
  msg = msg + "  useful " + BG_ON + "functions" + B_OFF + ", for some routine tasks, as described below\n";
  this->message( msg );

  cout << "    " << BG_ON << "int width();                          " << BB_ON << "return terminal width (# columns)" << B_OFF << "\n";
  cout << "    " << BG_ON << "int height();                         " << BB_ON << "return terminal height (# rows)" << B_OFF << "\n";
  cout << "    " << BG_ON << "string repeat( char ch, int limit );  " << BB_ON << "return a string of #limit chars (ch)" << B_OFF << "\n";
  cout << "    " << BG_ON << "void separator( string title );       " << BB_ON << "draw a horizontal line with a simple title" << B_OFF << "\n";
  cout << "    " << BG_ON << "bool countdown( int duration );       " << BB_ON << "count down #duration seconds" << B_OFF << "\n";
  cout << "    " << BG_ON << "void right_status( int status );      " << BB_ON << "output a boolean status (arg) at the right margin" << B_OFF << "\n";
  cout << "    " << BG_ON << "void message ( string msg );          " << BB_ON << "print message after a green asterisk" << B_OFF << "\n";
  cout << "    " << BG_ON << "void E_message ( string msg );        " << BB_ON << "print out error message after a red asterisk" << B_OFF << "\n";
  cout << "    " << BG_ON << "void CLR();                           " << BB_ON << "clear the screen" << B_OFF << "\n";
  cout << "    " << BG_ON << "void SCP();                           " << BB_ON << "save the current cursor position" << B_OFF << "\n";
  cout << "    " << BG_ON << "void RCP();                           " << BB_ON << "restore the cursor to the saved position" << B_OFF << "\n";
  cout << "    " << BG_ON << "void HCU();                           " << BB_ON << "hide the cursor" << B_OFF << "\n";
  cout << "    " << BG_ON << "void SCU();                           " << BB_ON << "show the cursor" << B_OFF << "\n";
  cout << "    " << BG_ON << "void HVP( int row, int col );         " << BB_ON << "move cursor to position row, col" << B_OFF << "\n";
  cout << "    " << BG_ON << "void CUP( int row, int col );         " << BB_ON << "move cursor to position row, col" << B_OFF << "\n";
  cout << "    " << BG_ON << "void CUU( int reps );                 " << BB_ON << "move the cursor up ( #reps cells )" << B_OFF << "\n";
  cout << "    " << BG_ON << "void CUD( int reps );                 " << BB_ON << "move the cursor down ( #reps cells )" << B_OFF << "\n";
  cout << "    " << BG_ON << "void CUF( int reps );                 " << BB_ON << "move the cursor forward ( #reps cells )" << B_OFF << "\n";
  cout << "    " << BG_ON << "void CUB( int reps );                 " << BB_ON << "move the cursor backward ( #reps cells )" << B_OFF << "\n\n";
  cout << "    " << BG_ON << "bool summarize_me();                  " << BB_ON << "print a summary of the functions in this library" << B_OFF << "\n";
  this->right_status( printf("Finishing with status of summarization --->\n") );   // "\n" replicates normal output of generalized call
  this->right_status(this->countdown(4));
  return true;
}

//---[ Cursor Movement Commands ]-----------------------------------
void Terminal::CLR()  // save the current cursor position
{ cout << CSI << "2J"; }

void Terminal::SCP()  // restore the cursor to the saved position
{ cout << CSI << "s"; }

void Terminal::RCP()  // restore the cursor to the saved position
{ cout << CSI << "u"; }

void Terminal::HCU()  // Hide the cursor (Note: the trailing character is lowercase L)
{ cout << CSI << "?25l"; }

void Terminal::SCU()  // Show the cursor
{ cout << CSI << "?25h"; }

void Terminal::HVP( int row, int col )  // move cursor to position row=$1, col=$2 (both default to 1 if omitted)
{
  if ( row <= 0 ) { row = 1; }
  if ( col <= 0 ) { col = 1; }
  cout << CSI << row << ";" << col << "f";
}

void Terminal::CUP( int row, int col )  // move cursor to position row=$1, col=$2 (both default to 1 if omitted)
{
  if ( row <= 0 ) { row = 1; }
  if ( col <= 0 ) { col = 1; }
  cout << CSI << row << ";" << col << "H";
}

void Terminal::CUU( int reps )  // Move the cursor up ( #reps cells )
{ if ( reps > 0 ) { cout << CSI << ( reps ) << "A"; } }

void Terminal::CUD( int reps )  // Move the cursor up ( #reps cells )
{ if ( reps > 0 ) { cout << CSI << ( reps - 1 ) << "B"; } }

void Terminal::CUF( int reps )  // Move the cursor up ( #reps cells )
{ if ( reps > 0 ) { cout << CSI << ( reps ) << "C"; } }

void Terminal::CUB( int reps )  // Move the cursor up ( #reps cells )
{ if ( reps > 0 ) { cout << CSI << ( reps ) << "D"; } }

