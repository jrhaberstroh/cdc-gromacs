from __future__ import division, print_function
import numpy as np
import matplotlib.pyplot as plt
import argparse
import logging
logging.basicConfig(level=logging.DEBUG)
import os
SRCDIR=os.path.dirname(os.path.realpath(__file__))

parser = argparse.ArgumentParser(description="")
parser.add_argument("gro", type=str, help="gro file to build configruation for")
## parser.add_argument("-exception", action="store_true", help="Use exception-style \
## format for configuration file. Required when order of file is not [Protein, BCL, \
## Solvent, Ions].")
args   = parser.parse_args()

CONSTANT_HEADER='''
#define BCL_N_ATOMS 140
#define SECRET_ION_CODE -90210420
// GOTO header
// Computed as Qb0 - Qb1
static double bcl_cdc_charges[BCL_N_ATOMS] = {0.017,0.027,0.021,0.000,0.053,0.000,0.030,0.000,0.028,-0.020,-0.031,-0.009,0.000,-0.003,0.000,-0.004,0.000,0.000,0.000,-0.004,0.000,0.000,0.001,0.000,0.000,-0.003,0.001,0.001,0.014,-0.023,-0.070,0.027,0.027,0.001,0.000,0.000,0.000,0.023,0.013,0.000,0.000,0.000,0.000,0.039,-0.041,-0.060,-0.005,0.000,-0.003,0.000,-0.003,0.000,0.000,0.000,-0.004,0.000,0.000,-0.001,0.000,0.000,0.000,0.012,-0.053,-0.047,0.018,-0.004,-0.002,0.000,0.000,0.000,0.027,0.009,-0.002,0.000,-0.002,0.002,0.003,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000,0.000};
'''

t_HOH="HOH"
t_SOL="SOL"
t_NA="NA"
t_CL="CL"
t_BCL="BCL"
t_SECRET_ION_CODE="SECRET_ION_CODE"
protein_resnr = []
NONPROTEIN=[t_HOH, t_SOL, t_NA, t_CL, t_BCL]
SOLVENTS=[t_HOH, t_SOL]

with open(args.gro) as f:
    comment = f.readline()
    natoms  = int(f.readline())
    count_pro_atom = 0
    count_bcl_res  = 0
    count_ion_res  = 0
    ## Start count_pro_chain at 1 because first protein residues will never 
    ## be greater than zero, so logic in body of text will fail to produce
    ## the correct count with zero-based counting without silly and excessive
    ## logic workarounds.
    count_pro_chain = 1
    previ_any_resid = 0
    previ_pro_resid = 0
    maxim_pro_resid = 0
    count_ion_reachedsol = 0
    set_prorestype = set([])
    current_printid = ""
    b_reachedsol = False
    b_reachedion = False
    for i_readline in range(natoms):
        l = f.readline()
        this_rescode=l[0:8]
        this_resid  =int(this_rescode[:5])
        this_restype=str(this_rescode[5:]).strip()
        ## CASE 1: Discovered a solvent molecule
        if this_restype in SOLVENTS:
            b_reachedsol=True
        ## CASE 2: Have not yet reached solvent and encountered a new resid
        if this_resid != previ_any_resid and not b_reachedsol:
            ## CASE 2.1: Found protein (aka the double negative, NOT nonprotein)
            if not (this_restype in NONPROTEIN):
                set_prorestype.add(this_restype) 
                if this_resid < previ_pro_resid:
                    count_pro_chain += 1
                maxim_pro_resid = max(this_resid, maxim_pro_resid)
                previ_pro_resid = this_resid
                ## NOTE: Offset is always zero if count_pro_chain==1, so 
                ##       the fact that maxim_pro_resid will be wrong is of
                ##       no consequence
                offset = (count_pro_chain - 1) * maxim_pro_resid
                current_printid = this_resid - 1 + offset
            ## CASE 2.2: Found BCL
            elif this_restype == t_BCL:
                count_bcl_res += 1
                current_printid = -count_bcl_res
            ## CASE 2.3: Found ion
            elif this_restype in [t_NA, t_CL]:
                count_ion_res += 1
                current_printid = t_SECRET_ION_CODE
            previ_any_resid = this_resid
        ## CASE 3: Print as long as we're not solvent!
        if not b_reachedsol:
            if this_restype in set_prorestype:
                count_pro_atom += 1
            protein_resnr.append(current_printid)
        ## CASE 4: Crash if we have found solvent and are BCL 
        if b_reachedsol and this_restype == t_BCL:
            raise ValueError("Fatal Error: Erroneously reached BCL residue after encountering a SOL residue. Protocol has no method of handling this file format. Aborting.")
        ## CASE 7: Found an ion in the solvent section
        if b_reachedsol and this_restype in [t_NA, t_CL]:
            b_reachedion = True
            count_ion_reachedsol += 1
        if b_reachedion and this_restype in SOLVENTS:
            raise ValueError("Fatal Error: Erroneously reached SOL residue after encountering an ion residue. Protocol has no method of handling this file format. Aborting.")
            
           
if count_pro_atom % count_pro_chain != 0:
    raise ValueError("Number of atoms assigned to protein ({}) does divide equally into number of protein chains found ({})."
            .format(count_pro_atom, count_pro_chain))

print("// Metadata from generate_3eoj.py")
print("// Num BCLs: ({}), Num protein atoms ({}), Num Protein Chains ({}), Num ion residues ({}).".
        format(count_bcl_res, count_pro_atom, count_pro_chain, count_ion_res))
print("// Max protein resid ({})".format(maxim_pro_resid))
print("// Protein residues found: {}".format(set_prorestype))

print(CONSTANT_HEADER)
print("#define BCL_N_BCL {}".format(count_bcl_res))
print("#define BCL_N_BCL_IN_SECTION {}".format(0))
print("#define MAX_RESID {}".format(maxim_pro_resid * count_pro_chain))
print("#define ION_N_ATOMS {}".format(count_ion_reachedsol))
print("#define PROTEIN_N_ATOMS ({} * {}) + ( {} * BCL_N_ATOMS ) + {}".format(count_pro_atom//count_pro_chain, count_pro_chain, count_bcl_res, count_ion_res))

print("""
static int BCL4_resnr[PROTEIN_N_ATOMS] =
{
"""
+
    ', '.join([str(resnr) for resnr in protein_resnr])
+
"""
};
"""
)
