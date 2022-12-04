while read value
do
  echo -en "value=[${value}], length=[${#value}], "
  echo -en '[[ "$(echo $value | sed 's/ //g')" != "" ]] evaluates to '
  [[ "$(echo $value | sed 's/ //g')" != "" ]] && echo true || echo false
done < /home/joe/testfile

#put this in /home/joe/testfile to test sed on "" (null), " " (space), and "    " (space and tab)
#joseph
#
#alfred
# 
#brendler
#  	
#senior

