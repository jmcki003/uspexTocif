#!/bin/zsh
zmodload zsh/mathfunc

if [[ -e hold.txt ]]; then
 rm hold.txt
 else
 :
fi

if [[ `ls *.scf.out | wc -l` -gt 1 ]]; then
ls *.scf.out | awk '{printf "%-3s%s\n", NR,$1}' | cut -f1 -d "." > tmp.txt
cat tmp.txt
 echo "Please select input file"
 read select_file
 name=`awk 'NR==i{print $2}' i=$select_file tmp.txt`
 rm tmp.txt
 else
 name=`ls *.scf.out | cut -f1 -d "."`
fi

if [[ -n $name ]]; then
 num=1
 else
 grep "JOB DONE" * | awk '{print $1}' > hold.txt
 num=`less hold.txt | wc -l`
fi

for i in `seq 1 $num`; do
 if [[ -a hold.txt ]]; then
  name=`awk "NR==$i" hold.txt | cut -f1 -d "."`
  newName=`awk "NR==$i" hold.txt | cut -f1 -d "." | sed 's/r-//g'`
 else
  newName=$name
 fi
 mkdir -p "cif"
 cp /home/jessica/work/templates/mercury.cif cif/${newName}.cif
 cp ${name}.scf.out cif/
 cd cif/
 sed -i "s/data_pos/data_${newName}/g" ${newName}.cif
 
 holdNum=`grep -n "ATOMIC_POSITIONS (" ${name}.scf.out | tail -1 | cut -f1 -d :`
 lineNum=$(( $holdNum + 1))
 start=$(( `grep -n "_atom_site_fract_z" ${newName}.cif | cut -d : -f 1` + 1))
 check=`awk "NR==${lineNum}" ${name}.scf.out | awk '{print $1}'`

 #this is a loop to replace atom type and positions
 while [[ $check != "End" ]]
 do
  sed -i "${start}s/^$/`awk "NR==${lineNum}" ${name}.scf.out`\n/" ${newName}.cif
  start=$((${start}+1))
  lineNum=$(($lineNum + 1))
  check=`awk "NR==${lineNum}" ${name}.scf.out | awk '{print $1}'`
 done

 holdx=$((`grep -i -n "CELL_PARAMETERS" ${name}.scf.out | tail -1 | cut -f1 -d :` + 1))
 holdy=$(($holdx + 1))
 holdz=$(($holdx + 2))
 blah=`grep -i "(alat)" ${name}.scf.out | tail -1 | awk '{print $5}'`

# blah=`grep -i "CELL_PARAMETERS" ${name}.scf.out | tail -1 | awk '{print $2}' | cut -f1 -d ")" | sed 's/(//'`
# alat=$(($blah*0.529177))
 xx=`awk "NR==$holdx" ${name}.scf.out | awk '{print $1}'`
 xy=`awk "NR==$holdx" ${name}.scf.out | awk '{print $2}'`
 xz=`awk "NR==$holdx" ${name}.scf.out | awk '{print $3}'`
 yx=`awk "NR==$holdy" ${name}.scf.out | awk '{print $1}'`
 yy=`awk "NR==$holdy" ${name}.scf.out | awk '{print $2}'`
 yz=`awk "NR==$holdy" ${name}.scf.out | awk '{print $3}'`
 zx=`awk "NR==$holdz" ${name}.scf.out | awk '{print $1}'`
 zy=`awk "NR==$holdz" ${name}.scf.out | awk '{print $2}'`
 zz=`awk "NR==$holdz" ${name}.scf.out | awk '{print $3}'`
 a=$(( sqrt($xx*$xx + $xy*$xy + $xz*$xz) * 0.529177 ))
 b=$(( sqrt($yx*$yx + $yy*$yy + $yz*$yz) * 0.529177 ))
 c=$(( sqrt($zx*$zx + $zy*$zy + $zz*$zz) * 0.529177 ))

 pi=3.141592653589793
# gamma=`echo $((acos(($xx*$yx + $xy*$yy + $xz*$yz)*($alat*$alat)/($a*$b))*(180/pi)))`
# beta=`echo $((acos(($xx*$zx + $xy*$zy + $xz*$zz)*($alat*$alat)/($a*$c))*(180/pi)))`
# alpha=`echo $((acos(($yx*$zx + $yy*$zy + $yz*$zz)*($alat*$alat)/($b*$c))*(180/pi)))`
 gamma=`echo $((acos(($xx*$yx + $xy*$yy + $xz*$yz)/($a*$b))*(180/pi)))`
 beta=`echo $((acos(($xx*$zx + $xy*$zy + $xz*$zz)/($a*$c))*(180/pi)))`
 alpha=`echo $((acos(($yx*$zx + $yy*$zy + $yz*$zz)/($b*$c))*(180/pi)))`


 sed -i "s/_cell_length_a/_cell_length_a $a/" ${newName}.cif
 sed -i "s/_cell_length_b/_cell_length_b $b/" ${newName}.cif
 sed -i "s/_cell_length_c/_cell_length_c $c/" ${newName}.cif
 sed -i "s/_cell_angle_alpha/_cell_angle_alpha $alpha/" ${newName}.cif
 sed -i "s/_cell_angle_beta/_cell_angle_beta $beta/" ${newName}.cif
 sed -i "s/_cell_angle_gamma/_cell_angle_gamma $gamma/" ${newName}.cif
 sed -i '/_atom_site_type_symbol/d' ${newName}.cif

 if [[ -n `grep "ATOMIC_POSITIONS (" ${name}.scf.out | tail -1 | grep -i angstrom` ]]; then
  sed -i 's/fract/Cartn/g' ${newName}.cif
  babel -icif ${newName}.cif -ofract ${newName}.frac 
  lineNum=3
  start=$(( `grep -n "_atom_site_Cartn_z" ${newName}.cif | cut -d : -f 1` + 1))
  eof=`less ${newName}.frac | wc -l`
  while [[ $lineNum -lt eof ]]
  do
   sed -i "${start}s/`awk "NR==${start}" ${newName}.cif`/`awk "NR==${lineNum}" ${newName}.frac`/" ${newName}.cif
   start=$((${start}+1))
   lineNum=$(($lineNum + 1))
  done  
  sed -i 's/Cartn/Fract/g' ${newName}.cif
  rm ${newName}.frac
fi
 
 rm ${name}.scf.out
 cd ../
done


