/*
 * progress.cpp
 * Joe Brendler
 * 28 January 2015
 * employs the progress function in my terminal library
 */
#include "Terminal.h"
#include "colorHeader.h"
#include <cstdlib>

using namespace std;
Terminal term;

int main (int argc, char *argv[])
{
  using namespace std;
//  cout << " argc: " << argc << endl;
//  cout << " argv[0]: " << argv[0] << endl;
//  cout << " argv[1]: " << argv[1] << endl;
//  cout << " argv[2]: " << argv[2] << endl;

  if (argc != 3) { cout << BR_ON << "*** Error: progress() requires two arguments ( " << BW_ON "step " << BR_ON << "and" << BW_ON << " num_steps " << BR_ON << ")" << B_OFF << endl; return 3; }
  else
  {
    int step = atoi( argv[1] );  int num_steps = atoi( argv[2] );
    term.progress(step, num_steps);
  }
}
