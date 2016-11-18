#include <string>
#include <iostream>
#include <cstdio>

using namespace std;

int main()
{
  int i=23;
  char answer[50];

  sprintf(answer, "%d", i);
//  itoa(i, answer, 10);
  cout << "itoa returns: " << answer << std::endl;

}

