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

int main()
{
  int i=735823;
  string answer("");
//  char answer[50];

//  sprintf(answer, "%d", i);
//  itoa(i, answer, 10);
  answer = itoa(i);
  cout << "itoa returns: " << answer << std::endl;

}

