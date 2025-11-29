/* ctime example */
#include <ctime>	// time_t, time, ctime
#include <cstdio>	// printf
#include <unistd.h>	// POSIX - usleep
#include <iostream>	// cout

using namespace std;

int main()
{
  time_t rawtime;
  time (&rawtime);
  printf ("The current local time is: %s", ctime (&rawtime));

  cout << "\n\ncountdown:\n";
  for (int i=12; i>0; --i) {
    cout << i << std::endl;
    usleep( 1000000 );  // microseconds
  }
  cout << "Lift off!\n";

  return 0;
}
