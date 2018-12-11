#!/bin/ksh

name=$1

if [[ -z $name ]]; then
 name=gatheredPOSCARS
fi

resNum=`ls results* | grep results | wc -l`
ls results* | grep results | cut -f1 -d : > holdRes

if [[ `cat holdRes | wc -l` -eq 0 ]]; then
 resNum=1
 echo results1 > holdRes
fi

mkdir -p all
mkdir -p all/cif
rm all/cif/*.cif
for res in `seq 1 $resNum`
do
 resName=`awk "NR==${res}" holdRes`
 cd ${resName}
 echo `pwd`
 if [[ ! -d holdStruc/ ]]; then
  #make necessary directories and clean out pre-existing directories
  mkdir -p holdStruc/
  cd holdStruc/
  mkdir -p poscars
  mkdir -p xyz
  mkdir -p cif
  rm lineNums
  #copy the files we need into our new directory
  cp ../${name} .
  cp ${name} poscars/editPOSCARS
  
  #declare variables to loop over all lines in ${name}
  if [[ -f ../EAvals ]]; then
   cp ../EAvals .
   line=`less EAvals | wc -l`
   for i in `seq 1 $line`
   do
    num=`awk "NR==${i}" EAvals`
    echo `grep -n -m 1 "EA${num}" ${name} | awk '{print $1}' | sed 's/[0-9]*:EA//'` $num >> lineNums
   done
  
  else
   grep -n "EA" ${name} | awk '{print $1}' | sed 's/:EA[0-9]*//' > hold.txt
   line=`less hold.txt | wc -l`
   for i in `seq 1 $line`
   do
    num=`awk "NR==${i}" hold.txt`
    echo `awk "NR==${num}" ${name} | awk '{print $1}' | sed 's/EA//'` $num >> lineNums
   done
   rm hold.txt
  fi
  
  sed -i '1i EA lineNum' lineNums
  count=`less lineNums | wc -l`
  countEndOfFile=`grep "EA" ${name} | wc -l `
  endLine=`wc -l ${name} | awk '{print $1}'`
  
  #Loop over given POSCARS in ${name}
  for i in `seq 2 $count`;
  do
   #makes sure our arrays are empty
   unset atoms
   unset atomNums
   unset atomOrder
   unset atomType
   
   #find out between which lines the poscars exist
   l1=`awk "NR==${i}" lineNums | awk '{print $2}'`
   holdnum=`awk "NR==${i}" lineNums | awk '{print $1}'`
   #tmp=$(($holdnum + 1)) 
   #l2=`grep -n -m 1 "EA${tmp}" ${name} | awk '{print $1}' | sed 's/:EA[0-9]*//'`
   if [ $(($i - 1)) == $countEndOfFile ];
   then
    l2=$(($endLine+1))
   else
    l2=`awk "NR==$(( ${i} + 1 ))" lineNums | awk '{print $2}'`
   fi
  
   #echo "l1:" $l1 "l2:" $l2 
   #this directory will contain the original VASP POSCAR files
   cd poscars/
  
   #print every line between lines l1 and l2 into POSCAR$i
   #then we will perform math on this information
   #Note after line 8 we only need the first three columns (these are the direct coord)
   countls=0
   for j in `seq $l1 $(($l2 - 1))`
   do
     if [ $countls -lt 8 ];
     then
       awk "NR==${j}" editPOSCARS >> POSCAR${holdnum}
     else
       x=`awk "NR==${j}" editPOSCARS | awk '{print $1}'`
       y=`awk "NR==${j}" editPOSCARS | awk '{print $2}'`
       z=`awk "NR==${j}" editPOSCARS | awk '{print $3}'`
       echo $x $'\t' $y $'\t' $z >> POSCAR${holdnum}
     fi
     countls=$(($countls+1))
   done
  
  cp POSCAR${holdnum} ../xyz/
  cd ../xyz/
  cp ~/work/templates/mercury.cif ../cif/poscar${holdnum}.cif
  # need to create poscar$i.xyz now. We will do so by using the information present in the file POSCAR$i itself
  #cell is lines 3-5 x-vector: line 3; y-vector: line 4; z-vector: line 5
  #Line 6 tells us which atoms are which
  #line 7 tells how many of each atoms are present
  # Skip line 8
  # Lines 9-end are our direct coordinates
  firstLine=`awk 'NR==1' POSCAR${holdnum}`
  a=`echo $firstLine | awk '{print $2}'`
  b=`echo $firstLine | awk '{print $3}'`
  c=`echo $firstLine | awk '{print $4}'`
  alpha=`echo $firstLine | awk '{print $5}'`
  beta=`echo $firstLine | awk '{print $6}'`
  gamma=`echo $firstLine | awk '{print $7}'`
  
  sed -i "s/data_pos/data_pos${holdnum}/" ../cif/poscar${holdnum}.cif
  sed -i "s/\(_cell_length_a\)/\1 ${a}/" ../cif/poscar${holdnum}.cif
  sed -i "s/\(_cell_length_b\)/\1 ${b}/" ../cif/poscar${holdnum}.cif
  sed -i "s/\(_cell_length_c\)/\1 ${c}/" ../cif/poscar${holdnum}.cif
  sed -i "s/\(_cell_angle_alpha\)/\1 ${alpha}/" ../cif/poscar${holdnum}.cif
  sed -i "s/\(_cell_angle_beta\)/\1 ${beta}/" ../cif/poscar${holdnum}.cif
  sed -i "s/\(_cell_angle_gamma\)/\1 ${gamma}/" ../cif/poscar${holdnum}.cif
  
  tempEndLine=`wc -l POSCAR${holdnum} | awk '{print $1}'`
  com1=`awk 'NR==3' POSCAR${holdnum}`
  com2=`awk 'NR==4' POSCAR${holdnum}`
  com3=`awk 'NR==5' POSCAR${holdnum}`
  
  #Short loop to determine what atom goes in front of each of the coordinates
  #also to find out how many atoms there are (numAtoms)
  endColNum=`awk "NR==6" POSCAR${holdnum} | wc -w`
 
  if [ $endColNum == 1 ];
  then
   atoms=`awk "NR==6" POSCAR${holdnum} | awk '{print $1}'`
   atomNums=`awk "NR==7" POSCAR${holdnum} | awk '{print $1}'`
   countAtoms=0
    for holdNum in `seq 1 $atomNums`
    do
     atomType[$countAtoms]=`echo ${atoms}${holdNum}`
     countAtoms=$(($countAtoms+1))
    done
  
   else
    countAtoms=0
    for num in `seq 1 $endColNum`
    do
      atoms[$(($num-1))]=`awk "NR==6" POSCAR${holdnum} | awk '{print $var}' var="$num"`
      atomNums[$(($num-1))]=`awk "NR==7" POSCAR${holdnum} | awk '{print $var}' var="$num"` 
      atomsLeft=0
      while [ $atomsLeft -lt `echo ${atomNums[$(($num-1))]}` ]
      do
        atomOrder[$countAtoms]=`echo ${atoms[$(($num-1))]}`
        atomType[$countAtoms]=`echo ${atoms[$(($num-1))]}$(($atomsLeft+1))`
        countAtoms=$(($countAtoms+1))
        atomsLeft=$(($atomsLeft+1))
      done
    done
   fi
  
   totNumAtoms=$(($tempEndLine-8))
  
   atomCount=0
  
   #We also want to create some .cif files so that way we can view them in mercury
   #now we're going to use a script to loop over the coordinates
    for k in `seq 9 $tempEndLine`
    do
    startmercuryLine=$((`grep -n "_atom_site_fract_z" ../cif/poscar${holdnum}.cif | sed  's/:_atom_site_fract_z//'`+1))
    atomCount=$(($atomCount+1))
  
    #extracting the direct coordinates
    dirCoorx=`awk "NR==${k}" POSCAR${holdnum} | awk '{print $1}'`
    dirCoory=`awk "NR==${k}" POSCAR${holdnum} | awk '{print $2}'`
    dirCoorz=`awk "NR==${k}" POSCAR${holdnum} | awk '{print $3}'`
  
    #ensuring we print the correct atoms in front of each cartesean coordinate
    atom=`echo ${atomOrder[$(($atomCount-1))]}`
    type=`echo ${atomType[$(($atomCount-1))]}`
    #now throw them all into the file
  
    #For mercury we want the fractional coordinates instead
    sed -i "${startmercuryLine}i $type $atom $dirCoorx $dirCoory $dirCoorz" ../cif/poscar${holdnum}.cif
    startmercuryLine=$((startmercuryLine+1))
    done
 
   babel -icif ../cif/poscar${holdnum}.cif -oxyz poscar${holdnum}.xyz
   volInfo=`awk "NR==1" POSCAR${holdnum}`
   sed -i "2s/.*/poscar${holdnum} ${volInfo}/" poscar${holdnum}.xyz
   rm POSCAR${holdnum}
 
   #makes a file that contains all poscars for easy-viewing
   cat poscar${holdnum}.xyz >> all.xyz
 
   cd ../
  done
  resNum2=`echo ${resName} | sed 's/results//'`
  rename.sh ${resNum2}
  cd ../
 fi
 resNum2=`echo ${resName} | sed 's/results//'`
 cp OUTPUT.txt ../all/OUTPUT${resNum2}.txt
 cp gatheredPOSCARS ../all/gatheredPOSCARS${resNum2}
 sed -i "s/EA/EA${resNum2}/g" ../all/gatheredPOSCARS${resNum2}
 cp holdStruc/cif/* ../all/cif/
 cd ../all/cif
 checkRMS.sh all all
 mkdir ${resNum2}
 mv poscar${resNum2}* keepers keepers.txt rejects.txt rejects/ allvsall.txt ${resNum2}/
 cd ../../
done

cd all/cif/
cp */keepers/*.cif .
checkRMS.sh all all
cp keepers.txt ../
cd ../
cat gatheredPOSCARS* > uniq_gatheredPOSCARS
createSymEnerVolPlotall
mv symms symmsFull
createSymEnerVolPlotall keepers.txt
mv symms symmsKeeps
cd ../
echo Finished!


