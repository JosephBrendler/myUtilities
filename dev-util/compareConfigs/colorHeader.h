/*
 * ensure you include <iostream> and <string>
 */

//---[ control sequence indicator == hex "0x1b["
#define CSI 		"\033["

//---[ Select Graphics Rendition (SGR) on/off ]--------------------------------
#define BOLD 		"1"
#define ULINE 		"4"
#define BLINK 		"5"
#define BLINKFAST 	"6"
#define ULINE_OFF 	"24"
#define BLINK_OFF 	"25"
#define SGR_OFF 	"0"

//---[ colors, foreground ]----------------------------------------------------
#define BLACK		"30"
#define RED 		"31"
#define GREEN		"32"
#define YELLOW		"33"
#define BLUE		"34"
#define MAG	    	"35"
#define LBLUE		"36"
#define WHITE		"37" );

//---[ my favorite colors, terminate with B_OFF ]------------------------------
#define DK_ON 		"\033[30;1mm"
#define BR_ON		"\033[31;1m"
#define BG_ON		"\033[32;1m"
#define BY_ON		"\033[33;1m"
#define BB_ON		"\033[34;1m"
#define BM_ON		"\033[35;1m"
#define LB_ON		"\033[36;1m"
#define BW_ON		"\033[37;1m"
#define B_OFF 		"\033[00m"

//---[ others ]------------------------------------------------------------------
#define K_ON 		"\033[30m"
#define R_ON		"\033[31m"
#define G_ON		"\033[32m"
#define Y_ON		"\033[33m"
#define B_ON		"\033[34m"
#define M_ON		"\033[35m"
#define L_ON		"\033[36m"
#define W_ON		"\033[37m"


//---[ backgrounds ]-------------------------------------------------------------
#define KBACK		"40"
#define RBACK		"41"
#define GBACK		"42"
#define YBACK		"43"
#define BBACK		"44"
#define MBACK		"45"
#define LBACK		"46"
#define WBACK		"47"

/*
//---[ cursor movement -- see more at http://ascii-table.com/ansi-escape-sequences.php
#define CLR		"\033[2J"	// Clear the screen
#define SCP		"\033[s"	// Save the current cursor position
#define RCP             "\033[u"	// Restore the cursor to the saved position
#define HCU		"\033[?25l"	// Hide the cursor (Note: the trailing character is lowercase L)
#define SCU		"\033[?25h"	// Show the cursor
//---[ these cursor movements can be generalized as functions -- (replace # with variable)
#define HVP_0		"\033[0;0f"	// Move cursor to the 0,0 position (you can make function)
#define CUP 		"\033[2A"	// Move cursor up one cell (2 accounts for \n to issue command)
#define CUD		"\033[1B"	// Move the cursor down one cell
#define CUF		"\033[1C"	// Move the cursor one cell forward
#define CUB		"\033[1D"	// Move the cursor one cell backward

*/
