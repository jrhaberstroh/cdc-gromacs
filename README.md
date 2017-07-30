# umbrellamacs2
energy gap umbrella sampling modifications to gromacs-4.6.7


++ Usage
  1. Build header for your molecular configuration
  * NOTE: Atom order in configuration file must be as follows:
    1. Protein ("environment")
    2. Chromophores ("bcl")
    3. solvent molecules (assumed to be waters -- does it assume a specific water model??)
    4. ions, any type
  * NOTE: Your index file must have an index group for the molecule you want to
 perform the CDC calculation on.
  2. Build with one of the included build scripts, making any necessary 
 modifications for your local system.
  3. Set pull-group1 to the BCL molecule that you want to calculate
    * Use "pull" methods with lambda = 0 to calculate cdc during execution
    * Pull with lambda != 0 for biased simulation
    * BCL\_N\_ATOM from the header must have the same number of atoms as
 the specified pull group or else the behavior is unspecified.

++ Major files

modifications/src/mdlib/pull.BASE.c:
  Core modifications to perform umbrella sampling and CDC calculations.

modifications/src/mdlib/pull.3eoj.c:
  Header for 3eoj PDB xtal structure with all residues modeled and 
  physiological pH

modifications/src/mdlib/pull.4bcl.c:
  Header for 4bcl PDB xtal structure with no missing residues modeled 
  and a neutralizing quantity of ions.
