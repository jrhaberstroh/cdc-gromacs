# umbrellamacs2
energy gap umbrella sampling modifications to gromacs-4.6.7


++ Usage
  1. Build header for your molecular configuration
  * NOTE: Atom order in configuration file must be as follows:
    1. Protein ("environment")
    2. Chromophores ("bcl")
    3. solvent molecules (assumed to be waters -- does it assume a specific water model??)
    4. ions, any type
  2. Build with one of the included build scripts, making any necessary 
 modifications for your local system.
  3. Use "pull" methods with lambda = 0 to calculate cdc during execution
  4. Pull with lambda != 0 currently broken; To fix, you must include a
 clause that only applies forces for the biased molecule.

++ Major files

modifications/src/mdlib/pull.BASE.c:
  Core modifications to perform umbrella sampling and CDC calculations.

modifications/src/mdlib/pull.3eoj.c:
  Header for 3eoj PDB xtal structure with all residues modeled and 
  physiological pH

modifications/src/mdlib/pull.4bcl.c:
  Header for 4bcl PDB xtal structure with no missing residues modeled 
  and a neutralizing quantity of ions.
