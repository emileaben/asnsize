mkdir -p ./data
#for YEAR in 2007 2006 2005
#for YEAR in 2012 2011 2010 2009 2008
for YEAR in 2017
do
   #for MONTH in 12 11 10 09 08 07 06 05 04 03 02 01
   for MONTH in 01 02 03 04 05 06 07 08 09 10 11 12
   do
      echo "trying: $YEAR-$MONTH"
      export DATE=$YEAR-$MONTH-01
      if [ ! -f ./data/asnsize.$DATE.txt ]; then
        echo "processing $DATE"
         if [ ! -f ./data/dump.$DATE.txt ]; then
            echo " table dumping for $DATE"
            ~/bin/ido +xT $DATE +ds aggr +dc RIS_RIB_V -M 0/0 +M +minpwr 10 > ./data/dump.$DATE.txt
         fi
         if [ ! -f ./data/asnsize.$DATE.txt ]; then
            echo " data proc for $DATE"
            ./process.pl ./data/dump.$DATE.txt  > ./data/asnsize.$DATE.txt
         fi
      fi
      echo "done $MONTH"
   done
done
