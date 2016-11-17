/***********************************************************************
 * Terminal.h
 * Joe Brendler
 * 28 January 2015
 * class definition -- easy (linux) terminal utilities for c++ programs
 **********************************************************************/
#ifndef Terminal_h
#define Terminal_h

#include <string>
#include <ctime>        // time_t, time, ctime
#include <cstdio>       // printf, etc.
#include <unistd.h>     // POSIX - usleep
#include <iostream>     // cout << , etc.

#include <sys/ioctl.h>  // a linux header with io controls
#include <unistd.h>   // a POSIX header

#include "colorHeader.h"

using namespace std;

class Terminal
{
  public:
    Terminal();
    int width();                                 // return terminal width (# columns)
    int height();                                // return terminal height (# rows)
    string repeat( char ch, int limit );         // return a string of #limit chars (ch)
    void separator( string title );              // draw a horizontal line with a simple title
    bool countdown( int duration );	         // count down #duration seconds
    void right_status( int status );             // output a boolean status (arg) at the right margin
    void message ( string msg );                 // print message after a green asterisk
    void E_message ( string msg );               // print out error message after a red asterisk
    void progress( int step, int num_steps );    // display an arrow depicting progress
    bool summarize_me();                         // print out error message after a red asterisk
    void CLR();                                  // clear the screen
    void SCP();                                  // save the current cursor position
    void RCP();                                  // restore the cursor to the saved position
    void HCU();                                  // Hide the cursor (Note: the trailing character is lowercase L)
    void SCU();                                  // Show the cursor
    void HVP( int row, int col );                // move cursor to position row, col
    void CUP( int row, int col );                // move cursor to position row, col
    void CUU( int reps );                        // Move the cursor up ( #reps cells )
    void CUD( int reps );                        // Move the cursor down ( #reps cells )
    void CUF( int reps );                        // Move the cursor forward ( #reps cells )
    void CUB( int reps );                 // Move the cursor backward ( #reps cells )
  private:
    int _cols, _lines;
  #ifdef TIOCGSIZE
    struct ttysize _ts;
  #elif defined(TIOCGWINSZ)
    struct winsize _ts;
  #endif /* TIOCGSIZE */
};

#endif
