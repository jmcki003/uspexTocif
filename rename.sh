#!/bin/ksh

numres=$1
#echo $numres
cd xyz/
ls poscar*.xyz > hold.txt
num=`less hold.txt| wc -l`
for i in `seq 1 $num`
do
 oldname=`awk "NR==$i" hold.txt`
 name=poscar${numres}`echo $oldname|cut -c7-`
 echo $oldname $name
 mv $oldname $name
 oldname=`echo $oldname | cut -f1 -d .`
 newname=`echo $name| cut -f1 -d .`
 sed -i "s/$oldname/$newname/" $name
done
cd ../cif
echo CIF~~~~~
ls *.cif > hold.txt
num=`less hold.txt| wc -l`
for j in `seq 1 $num`
do
 oldname=`awk "NR==$j" hold.txt`
 name=poscar${numres}`echo $oldname|cut -c7-`
 echo $oldname $name
 mv $oldname $name
 oldname=pos`echo $oldname | cut -f1 -d . | cut -c7-`
 newname=pos`echo $name| cut -f1 -d .  | cut -c7-`
 sed -i "s/$oldname/$newname/" $name
done
cd ../poscars
echo POSCARS~~~~~~~
ls POSCAR* > hold.txt
num=`less hold.txt| wc -l`
for k in `seq 1 $num`
do
 oldname=`awk "NR==$k" hold.txt`
 name=poscar${numres}`echo $oldname|cut -c7-`
 echo $oldname $name
 mv $oldname $name
 oldname=`echo $oldname | cut -f1 -d .`
 newname=`echo $name| cut -f1 -d .`
 sed -i "s/$oldname/$newname/" $name
 oldEA=`grep EA $newname | awk $1`
 newEA=3${oldEA}
 sed -i "s/$oldEA/$newEA/" $newname
done
cd ../

