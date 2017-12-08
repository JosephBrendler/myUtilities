/*
 * ensure you include <iostream> and <string>
 */

  //---[ control sequence indicator == hex "0x1b["
  std::string CSI;
  CSI.assign<int>(1,0x1b);
  CSI.append<int>(1,0x5b);

  //---[ Select Graphics Rendition (SGR) on/off ]--------------------------------
  std::string BOLD;       BOLD.assign      ( "1" );
  std::string ULINE;      ULINE.assign     ( "4" );
  std::string BLINK;      BLINK.assign     ( "5" );
  std::string BLINKFAST;  BLINKFAST.assign ( "6" );
  std::string ULINE_OFF;  ULINE_OFF.assign ( "24" );
  std::string BLINK_OFF;  BLINK_OFF.assign ( "25" );
  std::string SGR_OFF;    SGR_OFF.assign   ( "0" );

  //---[ colors, foreground ]----------------------------------------------------
  std::string BLACK;      BLACK.assign     ( "30" );
  std::string RED;        RED.assign       ( "31" );
  std::string GREEN;      GREEN.assign     ( "32" );
  std::string YELLOW;     YELLOW.assign    ( "33" );
  std::string BLUE;       BLUE.assign      ( "34" );
  std::string MAG;        MAG.assign       ( "35" );
  std::string LBLUE;      LBLUE.assign     ( "36" );
  std::string WHITE;      WHITE.assign     ( "37" );

  //---[ my favorite colors, terminate with B_OFF ]------------------------------
  std::string BR_ON;      BR_ON.assign     ( CSI + RED    + ";" + BOLD + "m"  );
  std::string BG_ON;      BG_ON.assign     ( CSI + GREEN  + ";" + BOLD + "m"  );
  std::string BY_ON;      BY_ON.assign     ( CSI + YELLOW + ";" + BOLD + "m"  );
  std::string BB_ON;      BB_ON.assign     ( CSI + BLUE   + ";" + BOLD + "m"  );
  std::string BM_ON;      BM_ON.assign     ( CSI + MAG    + ";" + BOLD + "m"  );
  std::string LB_ON;      LB_ON.assign     ( CSI + LBLUE  + ";" + BOLD + "m"  );
  std::string BW_ON;      BW_ON.assign     ( CSI + WHITE  + ";" + BOLD + "m"  );

  std::string B_OFF;      B_OFF.assign     ( CSI + "0m" );
