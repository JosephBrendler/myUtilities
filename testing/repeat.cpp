/*********************************************
 *  repeat.cpp -- test program               *
 *  compile with:  g++ repeat.cpp -o repeat  *
 *********************************************/
#include <iostream>
#include <string>

using namespace std;
char dash[2] = {'-',0};
char l_bracket[2] = {'[',0};
char r_bracket[2] = {']',0};
char bar[2] = {'|',0};
char space[2] = {' ',0};

string rpt ( char *c, int limit )
{
  string output;
  for ( int i=0; i<limit; i++) {
    output += c;
  }
  return output;
}

string separator ( string msg1, string msg2 )
{
  string output;
//  output.append( rpt (dash, 5) );
//  output.append(bar);
  output.append( rpt (dash, 5) ).append(bar).append(space).append(msg1);
  output.append(space).append(msg2).append(space).append(bar);
  output.append( rpt (dash, 6) );
  return output;
}

int main ( int argc, char *argv[] )
{
  std::string myString ("Initial string");
  char ch = '-';

  std::cout << '\n' << "myString: " << myString << '\n';
  std::cout << "ch: " << ch << '\n';
  std::cout << "dash: " << dash << '\n';
  std::cout << "l_bracket: " << l_bracket << '\n';
  std::cout << "r_bracket: " << r_bracket << '\n';
  std::cout << "bar: " << bar << '\n';
  std::cout << "space: " << space << '\n';
  std::cout << '\n';
  std::cout << "rpt(dash_variable, 5): " << rpt ( dash, 5 ) << '\n';
  std::cout << "separator on next line:" << '\n';
  std::cout << separator( "hello", "there" ) << std::endl;

  return 0;
}
