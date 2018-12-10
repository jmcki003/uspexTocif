import pymatgen as mg
from pymatgen.analysis.structure_matcher import StructureMatcher

struct1 = mg.Structure.from_file("1.cif")
struct2 = mg.Structure.from_file("2.cif")

matcher = StructureMatcher(attempt_supercell=True, primitive_cell=False)
rms = matcher.get_rms_dist(struct1, struct2)
print rms
