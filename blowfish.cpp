#include <cstdlib>
#include <iostream>
#include <fstream>
#include <cstdlib>
#include <string>
#include <iomanip>

using namespace std;

// ***************************************************************
//  Prototypes for external functions.
//	The "C" specifies to use the standard C/C++ style
//	calling convention.

extern "C" bool getOptions(int, char* [], bool *, FILE **, FILE **);
extern "C" void readKey(char [], int, int);
extern "C" void generateSubkeys(char []);
extern "C" bool getX(FILE *, char []);
extern "C" void blowfishEncrypt(char []);
extern "C" void blowfishDecrypt(char []);
extern "C" void writeX(FILE *, char [], bool);




int main(int argc, char* argv[])
{

	string	bars;
	bars.append(50,'-');
	static const int	KEY_MIN = 16;
	static const int	KEY_MAX = 56;
	FILE	*readFile, *writeFile;
	bool	encryptFlag;
	char	xArr[9];
	char	keyBuff[KEY_MAX+1];

	xArr[8] = 0;

	if (getOptions(argc, argv, &encryptFlag,
				&readFile, &writeFile)) {

		readKey(keyBuff, KEY_MIN, KEY_MAX);
		generateSubkeys(keyBuff);

		while (getX(readFile, xArr)) {

			if (encryptFlag) {
				blowfishEncrypt(xArr);
			} else {
				blowfishDecrypt(xArr);
			}

			writeX(writeFile, xArr, encryptFlag);
		}
	}

	return 0;
}
