# uspexTocif
Transforms output files produced by USPEX to Mercury-readable cif files. Intended only for the Tinker-USPEX interface. Will also perform an RMS overlap to check for redundant structures.
Requires ksh (http://www.kornshell.com/), python (https://www.python.org/), and openbabel (http://openbabel.org/wiki/Main_Page)

NOTE: you need to change line 10 in checkRMS.py to correctly reflect the location of rms.py:

cp /home/jessica/bin/rms.py .     <--Change this
