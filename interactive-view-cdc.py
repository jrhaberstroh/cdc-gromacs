%pylab
from MDAnalysis.coordinates.xdrfile import libxdrfile2 as XDR
trr='test-output/cdc-output.trr'

## Load the TRR data of dihedrals
natoms = XDR.read_trr_natoms(trr)
DIM=3
x = np.zeros((natoms, DIM), dtype=np.float32)
v = np.zeros((natoms, DIM), dtype=np.float32)
f = np.zeros((natoms, DIM), dtype=np.float32)
box = np.zeros((DIM, DIM), dtype=np.float32)
TRR = XDR.xdrfile_open(trr, 'r')
x_t = []
status = XDR.exdrOK
while status == XDR.exdrOK:
        status,step,time, _, _, _, _ = XDR.read_trr(TRR, box, x, v, f)
        x_alloc = np.copy(x)
        x_t.append(x_alloc)

XDR.xdrfile_close(TRR)
x_t = np.array(x_t)
x_t = x_t.reshape( (x_t.shape[0], -1) )
