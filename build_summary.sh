# command to get BLASTPol 2012 data from hen:
# also can see record in /projects/b1092/minimal_blast_2012/data_copy_record
# don't really use paulwilliams@hen, use IP address
cd /projects/b1092
rsync -rLptEv paulwilliams@hen:/data3/minimal_blast_2012 ./minimal_blast_2012

# Anaconda python
cd /projects/b1092/
bash ./Anaconda2-2019.03-Linux-x86_64.sh -p /projects/b1092/software/anaconda
# the last thing the installer asks is "do you want to run conda init?"
# say no, we will load this python using a module instead
# made a module, now we need to always load this python by issuing "module use ..." before "module load python"

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
#TODO Erin: other options passed to cmake the first time?
cmake .. -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/software/cfitsio/3.45
make
make install


# WCSLIB
# make should work, on quest make is gmake
module purge
module load gcc/4.6.3
# need cfitsio for to make wcslib, so we need to have a module for it. Load that module
module use /projects/b1011/blast-tng/modules
module load cfitsio
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

cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/software/fftw/3.3.8/
ccmake ..
# must turn BUILD_TESTS OFF in ccmake, otherwise the build fails
# turn BUILD_SHARED_LIBS ON

# Then we need to make a few sets of libraries
# turn ENABLE_OPENMP ON in ccmake
# turn both ENABLE_FLOAT and ENABLE_LONG_DOUBLE OFF (this will make the double libs, which are the defaults)
make
make install

ccmake .. #again, this time turn ENABLE_FLOAT and ENABLE_OPENMP ON
make
make install

ccmake .. #again, this time turn ENABLE_LONG_DOUBLE and ENABLE_OPENMP ON
make
make install

#should have shared libs for 
#  double serial and openmp
#  float serial and openmp
#  long double serial and openmp


#Getdata
module purge
module load python
module load gcc/4.6.3
module load automake/1.15
cd /projects/b1011/blast-tng/getdata-0.9.3
./configure --disable-idl --disable-matlab --disable-perl --disable-php --disable-zzslim --prefix=/projects/b1011/blast-tng/software/getdata/0.9.3
make
make check
make install


#Boost
module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
cd /projects/b1011/blast-tng/boost_1_61_0
./bootstrap.sh --with-libraries=all --prefix=/projects/b1011/blast-tng/software/boost/1.61.0
echo "using mpi ;" >> project-config.jam
./b2
./b2 install


#MOAT
module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module use /projects/b1011/blast-tng/modules
module load fftw
module load lapack
module load boost
./configure --prefix=/projects/b1011/blast-tng/software/moat --with-boost=/projects/b1011/blast-tng/software/boost/1.61.0 BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1011/blast-tng/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include

make
make check
#expect it to fail a test of dense matrix ops, but otherwise be successful
make install


#TOAST
cd /projects/b1011/blast-tng/TOAST_5/TOAST

module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module use /projects/b1011/blast-tng/modules
module load fftw
module load lapack
module load boost
module load moat
module load cfitsio
module load wcslib
module load getdata

# changed line 3 of /projects/b1011/blast-tng/TOAST_5/TOAST/experiments/blast/IO/toast_blast.hpp to:
#include <getdata/dirfile.h>
./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" LDFLAGS="-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib" BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0

