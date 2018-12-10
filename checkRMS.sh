#!/bin/ksh

m=$1
n=$2

mkdir -p keepers
mkdir -p rejects
rm 1.cif 2.cif
if [[ ! -f rms.py ]]; then
 cp /home/jessica/bin/rms.py .
fi

if [[ $m == all || -z $m ]]; then
 ls *.cif > hold1.txt
 m=all
else
 echo $m > hold1.txt
 m=`echo $m | cut -f1 -d .`
fi

if [[ $n == all || -z $n ]]; then
 ls *.cif > hold2.txt
 n=all
else
 echo $n > hold2.txt
 n=`echo $n | cut -f1 -d .`
fi

lengthM=`less hold1.txt | wc -l`
lengthN=`less hold2.txt | wc -l`
header=""
for i in `seq 1 $lengthM`
do
 name1=`awk "NR==${i}" hold1.txt`
 next=${name1}
 keep=`grep $name1 keepers.txt`
 reject=`grep $name1 rejects.txt`
 if [[ -z $keep ]]; then
  if [[ -z $reject ]]; then
   echo $name1 >> keepers.txt
   cp $name1 keepers/
  fi
 fi

 cp $name1 1.cif
 k=1
 while [ $k -lt $i ];
 do
  next=${next}"\t--"
  k=$(($k+1))
 done

 for j in `seq $i $lengthN`
 do
  name2=`awk "NR==${j}" hold2.txt`
  cp $name2 2.cif
  if [[ $i -eq 1 ]]; then
   header=${header}"\t"${name2}
  fi
  if [[ $name1 == $name2 ]]; then
   rms=`python rms.py | awk '{print $1}' | sed 's/(//'| sed 's/,//'`
   next=${next}"\t"${rms}
  else
   rms=`python rms.py | awk '{print $1}' | sed 's/(//'| sed 's/,//'`
   next=${next}"\t"${rms}
   if [[ $rms != "None" ]]; then
    if [[ $rms -lt 0.01 ]]; then
     keep=`grep $name2 keepers.txt`
     reject=`grep $name2 rejects.txt`
     if [[ -z $keep ]]; then
      if [[ -z $reject ]]; then
       echo $name2 >> rejects.txt
       cp $name2 rejects/
      fi
     fi
    fi
   fi
  fi
 done
 if [[ $i -eq 1 ]]; then
  echo -e $header > ${m}vs${n}.txt
 fi
 echo -e $next >> ${m}vs${n}.txt
done
rm 1.cif 2.cif

