// obtaining file size
#include <iostream>
#include <fstream>
using namespace std;

int main () {
  streampos begin,end;
//  ifstream myfile ("example.bin", ios::binary);
  ifstream myfile ("example.txt", ios::binary);
  begin = myfile.tellg();
  myfile.seekg (0, ios::end);
  end = myfile.tellg();
  myfile.close();
  cout << "file size is: " << (end-begin) << " bytes.\n";
  return 0;
}
