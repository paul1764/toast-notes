# Lapack

module purge
module load gcc/4.6.3
module load cmake/3.1.0
mkdir /projects/b1011/blast-tng/lapack-3.6.0/build-2
cd /projects/b1011/blast-tng/lapack-3.6.0/build-2
cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/software/lapack/3.6.0 -DCMAKE_Fortran_COMPILER=gfortran
#to check other options run ccmake
ccmake
make
make install

# CFITSIO

module purge
module load gcc/4.6.3
module load cmake/3.1.0
mkdir /projects/b1011/blast-tng/cfitsio/build
cd /projects/b1011/blast-tng/cfitsio/build
#other options passed to cmake?
cmake .. -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/software/cfitsio/3.45
make
make install


# WCSLIB
# make should work, on quest make is gmake

module purge
module load gcc/4.6.3
cd /projects/b1011/blast-tng/wcslib-5.15
gmake
gmake install
gmake check
#reports C/twcstab, C/tdis3, C/twcslint, Fortran/twcstab failed (these tests are not done if --with-cfitsiolib/inc options are not passed, in that case it doesn't find the cfitsio installation)
#these tests all report not finding libcfitsio.so.3, but that exists!
#permissions on libcfitsio.so.3 seem fine
#old wcslib passes all checks
#made a module for cfitsio, loaded it (now the libraries for cfitsio are in my LD_LIBRARY_PATH)
./configure --prefix=/projects/b1011/blast-tng/software/wcslib/5.15/ --with-cfitsiolib=/projects/b1011/blast-tng/software/cfitsio/3.45/lib --with-cfitsioinc=/projects/b1011/blast-tng/software/cfitsio/3.45/include --without-pgplot
gmake
gmake check
#all checks passed!
gmake install

#FFTW

module purge
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load cmake/3.1.0
#make a directory for building with cmake
mkdir /projects/b1011/blast-tng/fftw-3.3.8/build
cd /projects/b1011/blast-tng/fftw-3.3.8/build

cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/softare/fftw-paw
ccmake ..
