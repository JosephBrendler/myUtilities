/*
 * terminalLibTest.cpp
 * Joe Brendler
 * 28 January 2015
 * example program for running my terminal library
 */
#include "Terminal.h"
#include "colorHeader.h"
#include <unistd.h>

bool DEBUG = true;
bool EXTRA_DEBUG = false;
bool VERBOSE = true;
bool EXTRA_VERBOSE = false;

using namespace std;

bool done = false;

unsigned int microseconds;

Terminal term;

int main ()
{
  term.CLR(); term.CUP(1,1);
  printf("Terminal is %s%d %sx %s%d%s\n", BR_ON, term.width(), B_OFF, LB_ON, term.height(), B_OFF );
/*  term.CUU(5); cout << BY_ON << "Here I am (up)!!!" << B_OFF << endl;
  term.CUF(25); cout << BY_ON << "Here I am (fwd)!!!" << B_OFF << endl;
  term.CUD(10); cout << BY_ON << "Here I am (down)!!!" << B_OFF << endl;
  term.CUB(15); cout << BY_ON << "Here I am (back)!!!" << B_OFF << endl;

  term.CLR();
  term.CUP(5,5); cout << BY_ON << "(5,5)" << B_OFF << endl;
  term.CUP(45,5); cout << BY_ON << "(45,5)" << B_OFF << endl;
  term.CUP(5,45); cout << BY_ON << "(5,45)" << B_OFF << endl;
  term.CUP(45,45); cout << BY_ON << "(45,45)" << B_OFF << endl;
*/
/*  term.CLR();
  term.CUP(5,5);
  string s, str;
  s.assign("hello");
  cout << s;
  s = term.repeat( '*', 25);
  cout << " " << BG_ON << s << B_OFF << endl;
*/

/*  s = "Now is the time to ";
  s.append( BG_ON );
  s.append( "print green" );
  s.append( B_OFF );
  s += " Joe";
  s = s + " Brendler." + BY_ON + " But I am not done." + B_OFF;
*/
/*  s.assign( "Now" );
  s = s+ " is the " + BG_ON + "time" + B_OFF;
  term.E_message ( s );

  str.assign( BG_ON );
  cout << "lenght of BG_ON: " << str.length() << endl;
  cout << "\n\n\n";
  string sBGon( BG_ON );
  string sBYon( BY_ON );
  string sBRon( BR_ON );
  string sBBon( BB_ON );
  string sLBon( LB_ON );
  string sBoff( B_OFF );

  cout << BG_ON << "BG: " << B_OFF << sBGon.length() << endl;
  cout << BY_ON << "BY: " << B_OFF << sBYon.length() << endl;
  cout << BR_ON << "BR: " << B_OFF << sBRon.length() << endl;
  cout << BB_ON << "BB: " << B_OFF << sBBon.length() << endl;
  cout << LB_ON << "LB: " << B_OFF << sLBon.length() << endl;
  cout << "Boff: " << sBoff.length() << endl;
*/
/*  term.separator( "testing separator" );
  cout << "\n";
  term.right_status( term.countdown( 6 ) );
  cout << "\n";
*/
  term.HCU();
  for (int i=1; i < 1005; i++ ) { term.progress( i, 1005 ); usleep(5000); }
  term.SCU();
  cout << endl;
  cout << endl;
  term.summarize_me();

}
