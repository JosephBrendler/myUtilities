#include <iostream>
#include <cstdio>
#include <string>
#include "colorHeader.h"

using namespace std;

void demo( bool yesno )
{
  if ( yesno ) {
    cout << "unbold" << BR_ON << " bold red    " << B_OFF << "unbold" << '\n';
    cout << "unbold" << BG_ON << " bold green  " << B_OFF << "unbold" << '\n';
    cout << "unbold" << BY_ON << " bold yellow " << B_OFF << "unbold" << '\n';
    cout << "unbold" << BB_ON << " bold blue   " << B_OFF << "unbold" << '\n';
    cout << "unbold" << BM_ON << " bold mag    " << B_OFF << "unbold" << '\n';
    cout << "unbold" << LB_ON << " bold lblue  " << B_OFF << "unbold" << '\n';
    cout << "unbold" << BW_ON << " bold white  " << B_OFF << "unbold" << '\n';
    cout << "unbold" << " un-bold white  " << "unbold" << '\n';
  }
}



int main ()
{
   cout << "running demo...\n";
   demo ( true );

   cout << "\nthis is a " << BM_ON << "cout " << BG_ON << "test," << B_OFF << " now complete.\n";
   printf ( "this is a %sprintf%s test, %snow complete.\n", BM_ON, BG_ON, B_OFF );
}

