/*
 *
 * my_itoa - convert integer to string test program
 *
 *  compiler command:
 *  $ g++ -o my_itoa my_itoa.cpp
 */

#include <string>
#include <iostream>
#include <cstdio>

using namespace std;
string itoa( int number )
{
  char _alpha[50];
  int _number = number;

  sprintf(_alpha, "%d", _number);
  return _alpha;
}

int atoi( char *c )
{
  int _number;
  char _c = *c;
  _number = int ( _c );
  return _number;
}

int main()
{
  int i=735823;
  string answer("");
  cout << "integer i = " << i << std::endl;
  answer = itoa(i);
  cout << "itoa returns: " << answer << std::endl;

  char ch[2] = {'j',0};
  cout << "alpha char[] = " << ch << std::endl;
  int i_answer = atoi(ch);
  cout << "atoi returns: " << i_answer << std::endl;
}

