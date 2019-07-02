#1/31/2019

#running toast in interactive job

msub -I -A b1011 -q short -l nodes=1:ppn=8 -l walltime=01:00:00

source modules_source
export SCRATCH=/projects/b1011/fissel/runfiles/gls
cd $SCRATCH/mickey
module load boost
# dist_chan can't be more than number of cores 
mpirun -np 8 -npernode 8 toast_mpi_map mickey_toast_new_test.bin --bin --diagntt --cov --gls --gls_maxiter 60 --gls_dump_iter -1 --rcond 0.01 --dist_chan 8 --out mickey_toast_new_gls_test_20190131


#converged after ~30 iterations

#Then we started rebuilding libraries in a new directory: /projects/b1011/blast-tng/

#First lapack:

module load gcc/4.6.3
module load cmake/3.1.0
mkdir /projects/b1011/blast-tng/lapack-3.6.0/build-2
cd /projects/b1011/blast-tng/lapack-3.6.0/build-2
cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/software/lapack/3.6.0 -DCMAKE_Fortran_COMPILER=gfortran
#to check other options run ccmake
ccmake
make
make install

#fftw:

module load gcc/4.6.3
module load cmake/3.1.0
mkdir /projects/b1011/blast-tng/fftw-3.3.8/build
cd /projects/b1011/blast-tng/fftw-3.3.8/build
#were there other cmake options used here?
cmake .. -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/software/fftw/3.3.8
make
make install
#had to repeat to get double and single precision libraries? 
#do we need to repeat again to get mpi libraries? I don't see mpi libraries

#cfitsio (used 3.45, the most recent version. 3.37 was no longer available from developer):

module load gcc/4.6.3
module load cmake/3.1.0
mkdir /projects/b1011/blast-tng/cfitsio/build
cd /projects/b1011/blast-tng/cfitsio/build
#other options passed to cmake?
cmake .. -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/software/cfitsio/3.45
make
make install

# wcslib (used the only available gmake, in /usr/bin/gmake, gmake v3.82):
# on quest make is gmake (realized later)

module load gcc/4.6.3
cd /projects/b1011/blast-tng/wcslib-5.15
./configure --prefix=/projects/b1011/blast-tng/software/wcslib/5.15
gmake
gmake check
gmake install
#install failed, tried to install in /usr/local/bin
#tried adding / to end of prefix
./configure --prefix=/projects/b1011/blast-tng/software/wcslib/5.15/
gmake
gmake check
gmake install
#worked!

#then found old config.log in /projects/b1011/fissel/pascal/wcslib-5.15/config.log, so I am going to use the options there for running configure
#removing previous installation
rm -rf /projects/b1011/blast-tng/software/wcslib/
module load gcc/4.6.3
cd /projects/b1011/blast-tng/wcslib-5.15
./configure --prefix=/projects/b1011/blast-tng/software/wcslib/5.15/ --with-cfitsiolib=/projects/b1011/blast-tng/software/cfitsio/3.45/lib --with-cfitsioinc=/projects/b1011/blast-tng/software/cfitsio/3.45/include --without-pgplot
gmake
gmake install
gmake check
#reports C/twcstab, C/tdis3, C/twcslint, Fortran/twcstab failed (these tests are not done if --with-cfitsiolib/inc options are not passed, in that case it doesn't find the cfitsio installation)
#these tests all report not finding libcfitsio.so.3, but that exists!
#permissions on libcfitsio.so.3 seem fine
#old wcslib passes all checks
#made a module for cfitsio, loaded it (now the libraries for cfitsio are in my LD_LIBRARY_PATH)
module use /projects/b1011/blast-tng/modules
module load cfitsio
./configure --prefix=/projects/b1011/blast-tng/software/wcslib/5.15/ --with-cfitsiolib=/projects/b1011/blast-tng/software/cfitsio/3.45/lib --with-cfitsioinc=/projects/b1011/blast-tng/software/cfitsio/3.45/include --without-pgplot
gmake
gmake check
#all checks passed!
gmake install

# MOAT

module load gcc/4.6.3
cd /projects/b1011/blast-tng/MOAT_3/MOAT
./configure --prefix=/projects/b1011/blast-tng/software/moat/
#part of output
##=========== Build Configuration ===========
##C++ Compiler       : g++
##C++ Compile flags  : -O3
##F77 Compiler       : gfortran
##MPICXX Compiler    : g++
##OpenMP             : Detected (-fopenmp)
##OpenCL             : Disabled
##ACML Vendor Lib    : Disabled
##MASS Vendor Lib    : Disabled
##MKL Vendor Lib     : Disabled
##Apple Vendor Lib   : Disabled
##===========================================
make
make install

#then I checked the old moat config.log in /projects/b1011/fissel/pascal/Experimental/MOAT_3/MOAT/config.log
#configure command was: ./configure --prefix=/projects/b1011/fissel/pascal/Experimental/moat_new --with-boost=/projects/b1011/fissel/pascal/Experimental/boost BOOST_ROOT=/projects/b1011/fissel/pascal/Experimental/boost MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp --with-fftw-libs=-L/software/FFTW/3.3.3/lib -lfftw3 CFLAGS=-I/software/FFTW/3.3.3/include CXXFLAGS=-I/software/FFTW/3.3.3/include -with-fftw-cpp=-I/software/FFTW/3.3.3/include

#so I need to wait until boost is built and installed to build moat (although make check seems to pass all tests right now, but we want to have boost).
#also need to load mpi, module load mpi/openmpi-1.6.3-gcc.4.6.3


# 2/21/2019

# Boost

module purge
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3

cd /projects/b1011/blast-tng/boost_1_61_0
./bootstrap.sh --help
#saw that python is used, should load it so we are consistent
module load python
which python
#output: /software/anaconda2/bin/python
./bootstrap.sh --show-libraries
#lists libraries that require build and installation steps, that is the ones that you can list in --with-libraries
#this list includes mpi, I am going to build them all
./bootstrap.sh --with-libraries=all --prefix=/projects/b1011/blast-tng/software/boost/1.61.0
./b2 
./b2 install

# 2/22/2019

# going to try starting over for fftw so I don't mess up what Erin already did, following the instructions here: http://www.fftw.org/fftw3_doc/Installation-on-Unix.html#Installation-on-Unix

# FFTW

cd /projects/b1011/blast-tng/fftw-3.3.8
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
#first double precision, try with mpi (I think it does both mpi and single thread)
./configure --prefix=/projects/b1011/blast-tng/software/fftw-paw/3.3.8 CC=gcc MPICC=mpicc --enable-mpi --enable-openmp
#no permission to write the config.log in this directory, Erin created it
cd /projects/b1011/blast-tng
mv fftw-3.3.8/ fftw-3.3.8-erin
mkdir fftw-3.3.8
cp -r fftw-3.3.8-erin/* fftw-3.3.8/
cd /projects/b1011/blast-tng/fftw-3.3.8
./configure --prefix=/projects/b1011/blast-tng/software/fftw-paw/3.3.8 CC=gcc MPICC=mpicc --enable-mpi --enable-openmp
make
make check
#passed all checks
make install
ls /projects/b1011/blast-tng/software/fftw-paw/3.3.8/lib/
#output: cmake  libfftw3.a  libfftw3.la  libfftw3_mpi.a  libfftw3_mpi.la  libfftw3_omp.a  libfftw3_omp.la  pkgconfig
#only has static libraries, not shared need --enable-shared
rm -r /projects/b1011/blast-tng/software/fftw-paw/
./configure --prefix=/projects/b1011/blast-tng/software/fftw-paw/3.3.8 CC=gcc MPICC=mpicc --enable-mpi --enable-openmp --enable-shared
make
make install
make check
#passed all checks
ls /projects/b1011/blast-tng/software/fftw-paw/3.3.8/lib/
#output: cmake  libfftw3.a  libfftw3.la  libfftw3_mpi.a  libfftw3_mpi.la  libfftw3_omp.a  libfftw3_omp.la  pkgconfig
#same as last time, I guess it's fine? But in the one Erin did, there are shared libraries
#try cmake way
module load cmake/3.1.0
rm -r /projects/b1011/blast-tng/fftw-3.3.8/build
mkdir build
cd /projects/b1011/blast-tng/fftw-3.3.8/build
rm -r /projects/b1011/blast-tng/software/fftw-paw
cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/softare/fftw-paw
ccmake ..
#not making any changes
make
#error in Linking C executable bench
##collect2: ld returned 1 exit status
rm -r *
cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/softare/fftw-paw
make
#same error
rm -r *
cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/softare/fftw-paw
ccmake ..
#change ENABLE_OPENMP to ON
make
#same error
ccmake ..
#disable openmp, enable float
make
#same error
ccmake ..
#defaults, disable BUILD_TESTS
make
#built?
rm -r *
cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/softare/fftw-paw
#defaults, disable BUILD_TESTS
make
#worked!
make install
#typo in install prefix, changing to:
cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1011/blast-tng/software/fftw-paw/3.3.8/
ccmake ..
#disable BUILD_TESTS
make
make install
ccmake ..
#enable OPENMP
make
make install
ccmake ..
#enable OPENMP, enable FLOAT
make
#makes both serial and omp libraries
make install
ccmake ..
#enable long double, enable OPENMP
make
make install

#so we have fftw shared libraries for:

#  double serial and openmp
#  float serial and openmp
#  long double serial and openmp
#  trick was disabling the BUILD_TESTS

# 2/28/19

# building getdata 0.9.3 (latest is 0.10.0, maybe want to upgrade later?)

module load gcc/4.6.3
#previous configure for getdata in /home/paw663/fissel/getdata-0.9.3
#command: ./configure --disable-idl --disable-matlab --disable-perl --disable-python --disable-php --disable-zzslim --prefix=/projects/b1011/fissel/pascal/getdata
#I will leave python support this time

cd /projects/b1011/blast-tng/getdata-0.9.3
./configure --disable-idl --disable-matlab --disable-perl --disable-php --disable-zzslim --prefix=/projects/b1011/blast-tng/software/getdata/0.9.3
make
#Error:
##CDPATH="${ZSH_VERSION+.}:" && cd . && /bin/sh /projects/b1011/blast-tng/getdata-0.9.3/missing aclocal-1.15 -I m4
##/projects/b1011/blast-tng/getdata-0.9.3/missing: line 81: aclocal-1.15: command not found
##WARNING: 'aclocal-1.15' is missing on your system.
##         You should only need it if you modified 'acinclude.m4' or
##         'configure.ac' or m4 files included by 'configure.ac'.
##         The 'aclocal' program is part of the GNU Automake package:
##         <http://www.gnu.org/software/automake>
##         It also requires GNU Autoconf, GNU m4 and Perl in order to run:
##         <http://www.gnu.org/software/autoconf>
##         <http://www.gnu.org/software/m4/>
##         <http://www.perl.org/>
##make: *** [aclocal.m4] Error 127

module load automake/1.15
./configure --disable-idl --disable-matlab --disable-perl --disable-php --disable-zzslim --prefix=/projects/b1011/blast-tng/software/getdata/0.9.3
make
#failed on python related things:
##building 'pygetdata' extension
##gcc -pthread -fno-strict-aliasing -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -D_GNU_SOURCE -fPIC -fwrapv -DNDEBUG -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -D_GNU_SOURCE -fPIC -fwrapv -fPIC -DHAVE_CONFIG_H=1 -I../../src -I../../src -I/usr/lib64/python2.7/site-packages/numpy/core/include -I/usr/include/python2.7 -c pydirfile.c -o build/temp.linux-x86_64-2.7/pydirfile.o
##cc1: error: unrecognised debug output level "record-gcc-switches"
##cc1: error: unrecognised debug output level "record-gcc-switches"
##cc1: error: unrecognized command line option ‘-fstack-protector-strong’
##cc1: error: unrecognized command line option ‘-fstack-protector-strong’
##error: command 'gcc' failed with exit status 1
##make[4]: *** [build/lib.linux-x86_64-2.7/pygetdata.so] Error 1
##make[4]: Leaving directory `/projects/b1011/blast-tng/getdata-0.9.3/bindings/python'
##make[3]: *** [all-recursive] Error 1
##make[3]: Leaving directory `/projects/b1011/blast-tng/getdata-0.9.3/bindings/python'
##make[2]: *** [all] Error 2
##make[2]: Leaving directory `/projects/b1011/blast-tng/getdata-0.9.3/bindings/python'
##make[1]: *** [all-recursive] Error 1
##make[1]: Leaving directory `/projects/b1011/blast-tng/getdata-0.9.3/bindings'
##make: *** [all-recursive] Error 1

module load python
./configure --disable-idl --disable-matlab --disable-perl --disable-php --disable-zzslim --prefix=/projects/b1011/blast-tng/software/getdata/0.9.3
make
make check
#all checks that ran were passed
make install
#made a module

#MOAT

#again, from /projects/b1011/blast-tng/MOAT_3/MOAT/config/log:
# ./configure --prefix=/projects/b1011/fissel/pascal/Experimental/moat_new --with-boost=/projects/b1011/fissel/pascal/Experimental/boost BOOST_ROOT=/projects/b1011/fissel/pascal/Experimental/boost MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp --with-fftw-libs=-L/software/FFTW/3.3.3/lib -lfftw3 CFLAGS=-I/software/FFTW/3.3.3/include CXXFLAGS=-I/software/FFTW/3.3.3/include -with-fftw-cpp=-I/software/FFTW/3.3.3/include

module use /projects/b1011/blast-tng/modules
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load python

module load fftw #using Erin and Pascal's fftw
module load lapack
module load boost
rm -r /projects/b1011/blast-tng/software/moat

cd /projects/b1011/blast-tng/MOAT_3/MOAT
./configure --prefix=/projects/b1011/blast-tng/software/moat --with-boost=/projects/b1011/blast-tng/software/boost/1.61.0 BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1011/blast-tng/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include
#output includes:
##configure: =========== Build Configuration ===========
##configure:   C++ Compiler       : g++
##configure:   C++ Compile flags  : -I/projects/b1011/blast-tng/software/fftw/3.3.8/include
##configure:   F77 Compiler       : gfortran
##configure:   MPICXX Compiler    : mpic++
##configure:   OpenMP             : Detected (-fopenmp)
##configure:   OpenCL             : Disabled
##configure:   ACML Vendor Lib    : Disabled
##configure:   MASS Vendor Lib    : Disabled
##configure:   MKL Vendor Lib     : Disabled
##configure:   Apple Vendor Lib   : Disabled
##configure: ===========================================
#but I noticed mpic++ is in the anaconda directory, think it should be from the mpi module instead
module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
#now mpic++ is from this module
module load fftw
module load lapack
module load boost
./configure --prefix=/projects/b1011/blast-tng/software/moat --with-boost=/projects/b1011/blast-tng/software/boost/1.61.0 BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1011/blast-tng/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include
#output includes:
##configure: =========== Build Configuration ===========
##configure:   C++ Compiler       : g++
##configure:   C++ Compile flags  : -I/projects/b1011/blast-tng/software/fftw/3.3.8/include
##configure:   F77 Compiler       : gfortran
##configure:   MPICXX Compiler    : mpic++
##configure:   OpenMP             : Detected (-fopenmp)
##configure:   OpenCL             : Disabled
##configure:   ACML Vendor Lib    : Disabled
##configure:   MASS Vendor Lib    : Disabled
##configure:   MKL Vendor Lib     : Disabled
##configure:   Apple Vendor Lib   : Disabled
##configure: ===========================================
make
make check
#failing in a test of dense matrix ops
#terminate called after throwing an instance of 'moat::exception'
# what():  Exception at line 142 of file frameworks/03_la/test_mv.cpp:  Fail on transposed output vector consistency
# this looks boost related, and ./configure --help does say to use boostv1.53, we have v1.61.0. But we used 1.61.0 before
# maybe because when I built boost I loaded the python module last, so we used its mpic++? I can try to re-build boost loading python first



# 3/1/19

# trying make check for old MOAT build

cd /projects/b1011/fissel/pascal/Experimental/MOAT_3/MOAT
make check
#same exact error as when I ran yesterday in my new moat build directory
#maybe this is okay?

# Boost
# trying boost again, load python module first this time
# putting it in software/boost2

cd /projects/b1011/blast-tng/boost_1_61_0
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
./bootstrap.sh --with-libraries=all --prefix=/projects/b1011/blast-tng/software/boost2/1.61.0
./b2
#error about not using mpi, have to add something to user-config.jam to get mpi support, maybe that is the problem?
./b2 install

#re-run ./b2 to see error message:
./b2
#warning: 
##Graph library does not contain MPI-based parallel components.
##note: to enable them, add "using mpi ;" to your user-config.jam
##    - zlib                     : yes (cached)
##    - iconv (libc)             : yes (cached)
##    - icu                      : no  (cached)
##    - icu (lib64)              : no  (cached)
##    - compiler-supports-visibility : yes (cached)
##    - compiler-supports-ssse3  : yes (cached)
##    - compiler-supports-avx2   : no  (cached)
##    - gcc visibility           : yes (cached)
##    - long double support      : yes (cached)
##warning: skipping optional Message Passing Interface (MPI) library.
##note: to enable MPI support, add "using mpi ;" to user-config.jam.
##note: to suppress this message, pass "--without-mpi" to bjam.
##note: otherwise, you can safely ignore this message.

#made a boost2 module to point to the new boost installation

# try moat with the new boost

cd /projects/b1011/blast-tng/MOAT_3/MOAT
module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
#now mpic++ is from this module
module use /projects/b1011/blast-tng/modules
module load fftw
module load lapack
module load boost2
./configure --prefix=/projects/b1011/blast-tng/software/moat --with-boost=/projects/b1011/blast-tng/software/boost2/1.61.0 BOOST_ROOT=/projects/b1011/blast-tng/software/boost2/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1011/blast-tng/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include
#output includes:
##configure: =========== Build Configuration ===========
##configure:   C++ Compiler       : g++
##configure:   C++ Compile flags  : -I/projects/b1011/blast-tng/software/fftw/3.3.8/include
##configure:   F77 Compiler       : gfortran
##configure:   MPICXX Compiler    : mpic++
##configure:   OpenMP             : Detected (-fopenmp)
##configure:   OpenCL             : Disabled
##configure:   ACML Vendor Lib    : Disabled
##configure:   MASS Vendor Lib    : Disabled
##configure:   MKL Vendor Lib     : Disabled
##configure:   Apple Vendor Lib   : Disabled
##configure: ===========================================

make
make check
#same error while testing dense matrix ops

# Boost again!

cd /projects/b1011/blast-tng/boost_1_61_0
vim ./tools/build/example/user-config.jam
#added "using mpi" on a new line at the end
module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
rm -r ../software/boost2
./bootstrap.sh --with-libraries=all --prefix=/projects/b1011/blast-tng/software/boost2/1.61.0
./b2
#still got warning about mpi
#changed last line of user-config.jam to "using mpi ;"
./bootstrap.sh --with-libraries=all --prefix=/projects/b1011/blast-tng/software/boost2/1.61.0
./b2
#same warning
#maybe I need to change project-config.jam, which is created by boostrap.sh
./bootstrap.sh --with-libraries=all --prefix=/projects/b1011/blast-tng/software/boost2/1.61.0
vim project-config.jam
#added new final line "using mpi ;"
./b2
#no warning, building new things this time
./b2 install
#going to put it in the regular location (boost, not boost2)
./bootstrap.sh --with-libraries=all --prefix=/projects/b1011/blast-tng/software/boost/1.61.0
echo "using mpi ;" >> project-config.jam
./b2
./b2 install

# try moat again, with full mpi boost support

module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module use /projects/b1011/blast-tng/modules
module load fftw
module load lapack
module load boost
./configure --prefix=/projects/b1011/blast-tng/software/moat --with-boost=/projects/b1011/blast-tng/software/boost/1.61.0 BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1011/blast-tng/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include
#output includes:
##configure: =========== Build Configuration ===========
##configure:   C++ Compiler       : g++
##configure:   C++ Compile flags  : -I/projects/b1011/blast-tng/software/fftw/3.3.8/include
##configure:   F77 Compiler       : gfortran
##configure:   MPICXX Compiler    : mpic++
##configure:   OpenMP             : Detected (-fopenmp)
##configure:   OpenCL             : Disabled
##configure:   ACML Vendor Lib    : Disabled
##configure:   MASS Vendor Lib    : Disabled
##configure:   MKL Vendor Lib     : Disabled
##configure:   Apple Vendor Lib   : Disabled
##configure: ===========================================

make
make check
#still fails same test
make install

# maybe we don't need that operation for toast, after all the old moat build fails the same test
# could be an fftw issue, I have been using the less complete version for moat
# I made a module for fftw-paw, I will try using that next for moat

module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module use /projects/b1011/blast-tng/modules
module load fftw-paw
module load lapack
module load boost
./configure --prefix=/projects/b1011/blast-tng/software/moat --with-boost=/projects/b1011/blast-tng/software/boost/1.61.0 BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1011/blast-tng/software/fftw-paw/3.3.8/lib64 CFLAGS=-I/projects/b1011/blast-tng/software/fftw-paw/3.3.8/include CXXFLAGS=-I/projects/b1011/blast-tng/software/fftw-paw/3.3.8/include --with-fftw-cpp=-I/projects/b1011/blast-tng/software/fftw-paw/3.3.8/include
#output includes:
##configure: =========== Build Configuration ===========
##configure:   C++ Compiler       : g++
##configure:   C++ Compile flags  : -I/projects/b1011/blast-tng/software/fftw-paw/3.3.8/include
##configure:   F77 Compiler       : gfortran
##configure:   MPICXX Compiler    : mpic++
##configure:   OpenMP             : Detected (-fopenmp)
##configure:   OpenCL             : Disabled
##configure:   ACML Vendor Lib    : Disabled
##configure:   MASS Vendor Lib    : Disabled
##configure:   MKL Vendor Lib     : Disabled
##configure:   Apple Vendor Lib   : Disabled
##configure: ===========================================

make
make check
#fails same test
#not installing this time, going to use the version with the less complete fftw

#    changed the directory structure of the fftw installations slightly, now only one fftw directory but two versions
#    same for the modules
#    modules should still work though


#    need to try toast next
#    found the old config.log (/projects/b1011/fissel/pascal/Experimental/TOAST_5/TOAST/config.log)

#./configure --prefix=/projects/b1011/fissel/pascal/Experimental/toast_new --with-lapack=/projects/b1011/fissel/pascal/Experimental/lapack/lib64/liblapack.so --with-blas=/projects/b1011/fissel/pascal/Experimental/lapack/lib64/libblas.so --with-cfitsio=/software/supplemental/cfitsio/3.37 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/fissel/pascal/Experimental/moat_new/bin/moatconfig --with-wcslib=/projects/b1011/fissel/pascal/Experimental/wcslib --enable-exp-blast --with-getdata=/projects/b1011/fissel/pascal/Experimental/getdata CFLAGS=-I/projects/b1011/fissel/pascal/Experimental/wcslib/include/wcslib-5.15 -I/projects/b1011/fissel/pascal/Experimental/getdata/include/getdata -I/projects/b1011/fissel/pascal/Experimental/boost/include -I/projects/b1011/fissel/pascal/Experimental/boost/include/boost CXXFLAGS=-I/projects/b1011/fissel/pascal/Experimental/wcslib/include/wcslib-5.15 -I/projects/b1011/fissel/pascal/Experimental/getdata/include/getdata -I/projects/b1011/fissel/pascal/Experimental/boost/include -I/projects/b1011/fissel/pascal/Experimental/boost/include/boost CPPFLAGS=-I/projects/b1011/fissel/pascal/Experimental/wcslib/include/wcslib-5.15 -I/projects/b1011/fissel/pascal/Experimental/getdata/include/getdata -I/projects/b1011/fissel/pascal/Experimental/boost/include -I/projects/b1011/fissel/pascal/Experimental/boost/include/boost LDFLAGS=-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib

# edited with new paths:

# Note: CFLAGS, CXXFLAGS, CPPFLAGS are all the same.

#./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.a --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.a --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS=-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost CXXFLAGS=-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost CPPFLAGS=-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost LDFLAGS=-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib

# potential problems and differences between new and old:

#    old lapack used shared library, we only have static. – may require just changing an option in ccmake — did this

#    in the old getdata/include/getdata, there is a link to ../getdata.h. New one has no link, should we make one? — didn't do this

#    /projects/b1011/fissel/pascal/Experimental/python/lib contains a link to a library in the anaconda2 python, should we recreate that link? — didn't recreate link, just left that path in the LDFLAGS variable

# 3/11/19

# rebuilding lapack with shared libraries

cd /projects/b1011/blast-tng/lapack-3.6.0/build-2
module load gcc/4.6.3
module load cmake/3.1.0
ccmake ..
#changed BUILD_SHARED_LIBS to ON
make
#now there are shared libraries in addition to static ones, changing the toast configure to use shared lib

#    new toast configure command
#    using liblapack.so and libblas.so

#./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS=-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost CXXFLAGS=-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost CPPFLAGS=-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost LDFLAGS=-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib

# toast installation attempt:

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
#adding quotes around all flags (otherwise it sees the space and thinks -I/.../getdata is a new option)
./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" LDFLAGS="-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib"
#end of output:
##checking for the Boost serialization library... no
##configure: error: cannot find the flags to link with Boost serialization

# adding BOOST_ROOT to configure call

./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" LDFLAGS="-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib" BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0/include/boost/
#end of output
##configure: Detected BOOST_ROOT; continuing with --with-boost=/projects/b1011/blast-tng/software/boost/1.61.0/include/boost/
##checking for Boost headers version >= 1.53.0... no
##configure: cannot find Boost headers version >= 1.53.0
##configure: error: Could not find BOOST library >= 1.53!

# changing BOOST_ROOT path slightly

./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" LDFLAGS="-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib" BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0/include/
#end of output
##configure: Detected BOOST_ROOT; continuing with --with-boost=/projects/b1011/blast-tng/software/boost/1.61.0/include/
##checking for Boost headers version >= 1.53.0... /projects/b1011/blast-tng/software/boost/1.61.0/include/
##checking for Boost's header version... 1_61
##checking for the toolset name used by Boost for g++... gcc46 -gcc
##checking boost/archive/text_oarchive.hpp usability... yes
##checking boost/archive/text_oarchive.hpp presence... yes
##checking for boost/archive/text_oarchive.hpp... yes
##checking for the Boost serialization library... no
##configure: error: cannot find the flags to link with Boost serialization

#back where we started, so the first time I used BOOST_ROOT,  configure got an error earlier

./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" LDFLAGS="-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib" BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0/
#worked!
make

#example compile step (during make)
##g++ -DHAVE_CONFIG_H -I. -I../..  -I../../src/libtoast -I../../src/libtoast/map -I../../src/libtoast/IO -I../../src/libtoast/math -I../../src/libtoast/math/tpm -I../../src/tests  -I/projects/b1011/fissel/pascal/Experimental/moat_new/include -I/projects/b1011/fissel/pascal/Experimental/boost/include -fopenmp -I/software/FFTW/3.3.3/include -I/projects/b1011/blast-tng/software/cfitsio/3.45/include -I/projects/b1011/blast-tng/software/boost/1.61.0//include -I/projects/b1011/blast-tng/software/getdata/0.9.3/include   -I/projects/b1011/blast-tng/software/wcslib/5.15/include -I../../src/libtoast -I../../experiments/blast/IO -I../../experiments/blast/tests      -fopenmp -I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost -MT toast_test_readwrite.o -MD -MP -MF .deps/toast_test_readwrite.Tpo -c -o toast_test_readwrite.o toast_test_readwrite.cpp
#-I/software/FFTW/3.3.3/include is here! Why? holdover from last time? How can we delete old settings?

#end of make output:
##In file included from ../../../src/libtoast/IO/../../../experiments/blast/IO/toast_blast.hpp:3:0,
##                 from ../../../src/libtoast/IO/experiments_IO.hpp:4,
##                 from ../../../src/libtoast/IO/toast_io_internal.hpp:16,
##                 from ../../../src/libtoast/toast_internal.hpp:12,
##                 from ../../../src/libtoast-mpi/toast_mpi_internal.hpp:8,
##                 from toast_mpi_run.cpp:3:
##/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata/dirfile.h:25:27: fatal error: getdata/types.h: No such file or directory
##compilation terminated.

#make link to one directory back up, types.h is in the same directory as dirfile.h (as are a bunch of other header files)
ln -s /projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata /projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata/getdata

#Problems:

#    old FFTW seems to being used, don't see where in configure output it is being included
#    maybe old moat is being used too, based on Build Configuration output?
#    getdata header files, probably need to hack them so they look in the right place
#    are things being cached? configure output says they are, but I don't see a config.cache
#    saved most recent configure output in config.output so I can look later

# 4/9/2019

# rebuilding MOAT using make clean

cd /projects/b1011/blast-tng/MOAT_3/MOAT
module purge
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module use /projects/b1011/blast-tng/modules
module load fftw
module load lapack
module load boost
./configure --prefix=/projects/b1011/blast-tng/software/moat --with-boost=/projects/b1011/blast-tng/software/boost/1.61.0 BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1011/blast-tng/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1011/blast-tng/software/fftw/3.3.8/include

make clean
make
make check
# fails same "testing dense matrix ops" test
make install

# TOAST again
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

./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" LDFLAGS="-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib" BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0/

make clean
./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" LDFLAGS="-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib" BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0/

make

# failed because of getdata header files in the wrong place, changing getdata path (in CFLAGS, CPPFLAGS, CXXFLAGS) 
# and deleting the link at /projects/b1011/blast-tng/software/getdata/0.9.3/include/getdata/getdata
make clean

./configure --prefix=/projects/b1011/blast-tng/software/toast --with-lapack=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1011/blast-tng/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1011/blast-tng/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/blast-tng/software/moat/bin/moatconfig --with-wcslib=/projects/b1011/blast-tng/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1011/blast-tng/software/getdata/0.9.3 CFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1011/blast-tng/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1011/blast-tng/software/getdata/0.9.3/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include -I/projects/b1011/blast-tng/software/boost/1.61.0/include/boost" LDFLAGS="-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib" BOOST_ROOT=/projects/b1011/blast-tng/software/boost/1.61.0

make
#error:
##In file included from ./experiments_IO.hpp:4:0,
##                 from ./toast_io_internal.hpp:16,
##                from toast_fits.cpp:3:
##./../../../experiments/blast/IO/toast_blast.hpp:3:21: fatal error: dirfile.h: No such file or directory

# changed line 3 of /projects/b1011/blast-tng/TOAST_5/TOAST/experiments/blast/IO/toast_blast.hpp to:
#include <getdata/dirfile.h>

# next we need our own anaconda installation of python to avoid conflicts with libraries, like libbz2


#################################################################################
# Starting over on slurm cluster, going to make our own python:
# Also starting in the new project space, /projects/b1092
# 
#################################################################################

# Anaconda python
cd /projects/b1092/

# Anaconda install script downloaded from anaconda's website
bash ./Anaconda2-2019.03-Linux-x86_64.sh -p /projects/b1092/software/anaconda
# the last thing the installer asks is "do you want to run conda init?"
# say no, we will load this python using a module instead
# made a module, now we need to always load this python by issuing "module use ..." before "module load python"


# Lapack
module purge
cd /projects/b1092/lapack-3.6.0
rm -rf build
rm -rf build-2
mkdir build
cd /projects/b1092/lapack-3.6.0
module use /projects/b1092/modules
module load python
module load gcc/4.6.3
module load cmake/3.1.0

cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1092/software/lapack/3.6.0 -DCMAKE_Fortran_COMPILER=gfortran
ccmake ..
# turn BUILD_SHARED_LIBS ON
make
make install
# no static libraries this time, even though it is turned ON in ccmake
# only difference in Makefiles from this time and last time is paths for build directory

ccmake ..
# turn BUILD_SHARED_LIBS OFF
make
make install
# now we have both shared and static. Not sure if we need them all, but they are there


# Getdata
module purge
module use /projects/b1092/modules
module load python
module load gcc/4.6.3
module load automake/1.15
cd /projects/b1092/getdata-0.9.3
./configure --disable-idl --disable-matlab --disable-perl --disable-php --disable-zzslim --prefix=/projects/b1092/software/getdata/0.9.3
make clean
./configure --disable-idl --disable-matlab --disable-perl --disable-php --disable-zzslim --prefix=/projects/b1092/software/getdata/0.9.3
make
make check
# all checks that ran, passed (only 17 did not run)
make install
# made a module at /projects/b1092/modules/getdata/0.9.3


# Boost
module purge
module use /projects/b1092/modules
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
cd /projects/b1011/blast-tng/boost_1_61_0
./b2 clean
# not sure how much this helped, it says it performed configuration checks and built Boost C++ libraries
./bootstrap.sh --with-libraries=all --prefix=/projects/b1092/software/boost/1.61.0
echo "using mpi ;" >> project-config.jam
./b2
./b2 install

# Cfitsio
cd /projects/b1092/cfitsio/build/
module purge
module load gcc/4.6.3
cmake .. -DCMAKE_C_COMPILER=/hpc/software/gcc/4.6.3-rhel7/bin/gcc -DCMAKE_INSTALL_PREFIX=/projects/b1092/software/cfitsio/3.45 -DCMAKE_Fortran_COMPLIER=gfortran
#here I got an error about a path in CMakeCache.txt, so I edited the path names in that file and re-ran above command (seemed to work...)
make
make install 
#things seemed to work without error, there is now cfitsio listed in the software directory

# FFTW
cd /projects/b1092/fftw-3.3.8/
module list (gcc/4.6.3)
module load mpi
module list 
./configure --prefix=/projects/b1092/sofware/fftw/3.3.8 CC=gcc MPICC=mpicc --enable-mpi --enable-openmp --enable-shared
module load cmake/3.1.0
cd build/
cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1092/software/fftw/3.3.8/
ccmake .. #(press c, q to save parameters)
#checking to make sure all flags are turned on or off from above (enable long double, enable OPENMP, enable FLOAT, disable BUILD_TESTS), everything was except one...can't remember which, oops
make
make install

# Wcslib
cd /projects/b1092/wcslib-5.15
module purge
module load gcc/4.6.3
module use /projects/b1092/modules/
module load cfitsio
./configure --prefix=/projects/b1092/software/wcslib/5.15/ --with-cfitsiolib=/projects/b1092/software/cfitsio/3.45/lib --with-cfitsioinc=/projects/b1092/software/cfitsio/3.45/include --without-pgplot
gmake clean
gmake
gmake check
#passes all tests
gmake install

#5/1/2019
#attempt to install moat (failed in same place as it did previously)
cd /projects/b1092
cp -r ../b1011/blast-tng/MOAT_3/ .
cd MOAT_3/MOAT
module use /projects/b1092/modules/
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load fftw
module load lapack
module load boost
./configure --prefix=/projects/b1092/software/moat --with-boost=/projects/b1092/software/boost/1.61.0 BOOST_ROOT=/projects/b1092/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1092/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1092/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1092/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1092/software/fftw/3.3.8/include
make clean
make
make check
#output:
#Testing dense matrix ops...
#PROFILE:  TEST_MV (Matrix-Vector test time) :
#PROFILE:     Elapsed process time = 1.648071e-01 seconds
#PROFILE:     Total thread time = 9.229197e+00 thread-seconds
#PROFILE:     Active thread time = 1.648071e-01 thread-seconds
#PROFILE:     Idle thread time = 9.064389e+00 thread-seconds
#PROFILE:     Thread efficiency = 1.79%
#terminate called after throwing an instance of 'moat::exception'
#  what():  Exception at line 142 of file frameworks/03_la/test_mv.cpp:  Fail on transposed output vector consistency
#/bin/sh: line 5: 42667 Aborted                 ${dir}$tst
#FAIL: moat_test
make install
#did this because this is what was done previously. I must say that it is somewhat worrisome if this is failing in a matrix
#operation since the mapmaker relies on inverting matricies 

#6/4/2019
#looks like when moat fails the check it stops and doesn't check anything else
#could remove references to 03_la directory in src/libmoat/frameworks/Makefile

#toast
module purge
module use /projects/b1092/modules
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load fftw
module load lapack
module load boost
module load moat
module load cfitsio
module load wcslib
module load getdata
# for some reason needed automake
module load automake/1.15

#changed all paths to point to b1092 installation of libraries except for the libboost_python library that we had to make a link to, that one doesn't exist in our anaconda
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-L/projects/b1092/software/anaconda/lib" BOOST_ROOT=/projects/b1092/blast-tng/software/boost/1.61.0

#fixing BOOST_ROOT, still was wrong path
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-L/projects/b1092/software/anaconda/lib" BOOST_ROOT=/projects/b1092/software/boost/1.61.0

make
#failed on some library conflicts:
#/usr/bin/ld: warning: libgfortran.so.3, needed by /projects/b1092/software/lapack/3.6.0/lib64/liblapack.so, may conflict with libgfortran.so.4
#/usr/bin/ld: warning: libbz2.so.1, needed by /projects/b1092/software/getdata/0.9.3/lib/libgetdata++.so, may conflict with libbz2.so.1.0

# making a conda environment with just basic python to avoid library conflicts
conda create --prefix /projects/b1092/software/toast-python python=2.7
conda activate /projects/b1092/software/toast-python

#try again to configure and make
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-L/projects/b1092/software/anaconda/lib" BOOST_ROOT=/projects/b1092/software/boost/1.61.0
make
#/usr/bin/ld: warning: libgfortran.so.3, needed by /projects/b1092/software/lapack/3.6.0/lib64/liblapack.so, may conflict with libgfortran.so.4

#forgot to clean...
make clean
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-L/projects/b1092/software/anaconda/lib" BOOST_ROOT=/projects/b1092/software/boost/1.61.0

#still had regular anaconda libs in the LDFLAGS, start again with configure
make clean
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-L/projects/b1092/software/toast-python/lib" BOOST_ROOT=/projects/b1092/software/boost/1.61.0
make
#got an error about mpi conflicts, noticed we had the wrong version of fftw. we had the system one, we forgot to make our own module
#got to rebuild moat then toast, they are the only ones with fftw dependencies


#moat
#not in conda environment, never needed it before
cd /projects/b1092/MOAT_3/MOAT
module purge
module use /projects/b1092/modules/
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load fftw
module load lapack
module load boost
./configure --prefix=/projects/b1092/software/moat --with-boost=/projects/b1092/software/boost/1.61.0 BOOST_ROOT=/projects/b1092/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1092/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1092/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1092/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1092/software/fftw/3.3.8/include
make clean
./configure --prefix=/projects/b1092/software/moat --with-boost=/projects/b1092/software/boost/1.61.0 BOOST_ROOT=/projects/b1092/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1092/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1092/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1092/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1092/software/fftw/3.3.8/include
make
make check
#same dense matrix ops check fails like always
make install

#toast
cd /projects/b1092/TOAST_5/TOAST
module purge
module use /projects/b1092/modules
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load fftw
module load lapack
module load boost
module load moat
module load cfitsio
module load wcslib
module load getdata
module load automake/1.15

make clean
conda activate /projects/b1092/software/toast-python
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-L/projects/b1092/software/toast-python/lib" BOOST_ROOT=/projects/b1092/software/boost/1.61.0

make clean
make

#compile step that failed:
mpif90 -cpp -I../../src/libtoast -I../../src/libtoast/map -I../../src/libtoast/IO -I../../src/libtoast/math -I../../src/libtoast/math/tpm -I../../src/libtoast-mpi -I../../src/libtoast-mpi/math -I../../src/libtoast-mpi/IO -I../../src/libtoast-mpi/map -I../../src/tests-mpi  -I/projects/b1092/software/moat/include -I/projects/b1092/software/boost/1.61.0/include -fopenmp -I/projects/b1092/software/fftw/3.3.8/include -I/projects/b1092/software/cfitsio/3.45/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/getdata/0.9.3/include   -I/projects/b1092/software/wcslib/5.15/include -I../../src/libtoast -I../../src/libtoast-mpi -g -O2 -c -o toast_mpi_fdist.o toast_mpi_fdist.f03

/bin/sh ../../libtool --tag=CXX   --mode=link mpic++ -fopenmp -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost  -L/projects/b1092/software/toast-python/lib -o toast_mpi_fdist toast_mpi_fdist.o ../../src/libtoast-mpi/libftoast-mpi.la ../../src/libtoast/libftoast.la ../../src/libtoast-mpi/libtoast-mpi.la ../../src/libtoast/libtoast.la -lexpat -L/projects/b1092/software/moat/lib -lmoat-mpi -lmoat -lm -fopenmp -L/projects/b1092/software/fftw/3.3.8/lib64 -L/projects/b1092/software/boost/1.61.0/lib -Wl,-R,/projects/b1092/software/boost/1.61.0/lib -lboost_mpi -L/projects/b1092/software/moat/lib -lmoat -lm -fopenmp -L/projects/b1092/software/fftw/3.3.8/lib64 -L/projects/b1092/software/cfitsio/3.45/lib -lcfitsio -L/projects/b1092/software/getdata/0.9.3/lib -lgetdata++ -lgetdata -lbz2 -lz -L/projects/b1092/software/wcslib/5.15/lib -lwcs -lm   -L/projects/b1092/software/boost/1.61.0/lib -Wl,-R,/projects/b1092/software/boost/1.61.0/lib -lboost_serialization -L/projects/b1092/software/boost/1.61.0/lib -Wl,-R,/projects/b1092/software/boost/1.61.0/lib -lboost_regex /projects/b1092/software/lapack/3.6.0/lib64/liblapack.so /projects/b1092/software/lapack/3.6.0/lib64/libblas.so -lm -L/projects/b1092/software/toast-python/lib -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3 -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3/../../../../lib64 -L/lib/../lib64 -L/usr/lib/../lib64 -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3/../../.. -lgfortran -lm -lquadmath -fopenmp  -L/projects/b1092/software/toast-python/lib -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3 -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3/../../../../lib64 -L/lib/../lib64 -L/usr/lib/../lib64 -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3/../../.. -lgfortran -lm -lquadmath 

libtool: link: mpic++ -fopenmp -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost -o .libs/toast_mpi_fdist toast_mpi_fdist.o -fopenmp -Wl,-R -Wl,/projects/b1092/software/boost/1.61.0/lib -fopenmp -Wl,-R -Wl,/projects/b1092/software/boost/1.61.0/lib -Wl,-R -Wl,/projects/b1092/software/boost/1.61.0/lib /projects/b1092/software/lapack/3.6.0/lib64/liblapack.so /projects/b1092/software/lapack/3.6.0/lib64/libblas.so -fopenmp  -L/projects/b1092/software/toast-python/lib ../../src/libtoast-mpi/.libs/libftoast-mpi.so ../../src/libtoast/.libs/libftoast.so ../../src/libtoast-mpi/.libs/libtoast-mpi.so ../../src/libtoast/.libs/libtoast.so -L/projects/b1092/TOAST_5/TOAST/src/libtoast/map -L/projects/b1092/TOAST_5/TOAST/src/libtoast/IO -L/projects/b1092/TOAST_5/TOAST/src/libtoast/math -L/projects/b1092/TOAST_5/TOAST/src/libtoast/math/tpm -lexpat -L/projects/b1092/software/moat/lib /projects/b1092/software/moat/lib/libmoat-mpi.so -L/projects/b1092/software/fftw/3.3.8/lib64 -L/projects/b1092/software/boost/1.61.0/lib -lboost_mpi /projects/b1092/software/moat/lib/libmoat.so -lfftw3 -L/projects/b1092/software/cfitsio/3.45/lib -lcfitsio -L/projects/b1092/software/getdata/0.9.3/lib /projects/b1092/software/getdata/0.9.3/lib/libgetdata++.so /software/gcc/4.6.3-rhel7/lib/../lib64/libstdc++.so /projects/b1092/software/getdata/0.9.3/lib/libgetdata.so -llzma -lbz2 -lz -L/projects/b1092/software/wcslib/5.15/lib -lwcs -lboost_serialization -lboost_regex -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3 -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3/../../../../lib64 -L/lib/../lib64 -L/usr/lib/../lib64 -L/hpc/software/gcc/4.6.3-rhel7/bin/../lib/gcc/x86_64-redhat-linux-gnu/4.6.3/../../.. /software/gcc/4.6.3-rhel7/lib/../lib64/libgfortran.so /software/gcc/4.6.3-rhel7/lib/../lib64/libquadmath.so -lm -lquadmath -Wl,-rpath -Wl,/projects/b1092/software/toast/lib -Wl,-rpath -Wl,/projects/b1092/software/moat/lib -Wl,-rpath -Wl,/projects/b1092/software/getdata/0.9.3/lib -Wl,-rpath -Wl,/software/gcc/4.6.3-rhel7/lib/../lib64
toast_mpi_fdist.o: In function 'MAIN__':
/projects/b1092/TOAST_5/TOAST/src/tests-mpi/toast_mpi_fdist.f03:76: undefined reference to 'mpi_init_'
/projects/b1092/TOAST_5/TOAST/src/tests-mpi/toast_mpi_fdist.f03:77: undefined reference to 'mpi_comm_rank_'
/projects/b1092/TOAST_5/TOAST/src/tests-mpi/toast_mpi_fdist.f03:78: undefined reference to 'mpi_comm_size_'
/projects/b1092/TOAST_5/TOAST/src/tests-mpi/toast_mpi_fdist.f03:205: undefined reference to 'mpi_barrier_'
/projects/b1092/TOAST_5/TOAST/src/tests-mpi/toast_mpi_fdist.f03:256: undefined reference to 'mpi_exscan_'
/projects/b1092/TOAST_5/TOAST/src/tests-mpi/toast_mpi_fdist.f03:266: undefined reference to 'mpi_barrier_'
/projects/b1092/TOAST_5/TOAST/src/tests-mpi/toast_mpi_fdist.f03:372: undefined reference to 'mpi_finalize_'
/projects/b1092/TOAST_5/TOAST/src/tests-mpi/toast_mpi_fdist.f03:87: undefined reference to 'mpi_abort_'

#it is the second step that has a problem, the /bin/sh one. We tried running the first two ourselves and the second one reproduced this error
#try adding include folder for mpi in configure in CFLAGS
#also adding -L/.../lib for mpi in LDFLAGS

#6/13/19
#toast

cd /projects/b1092/TOAST_5/TOAST
module purge
module use /projects/b1092/modules
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load fftw
module load lapack
module load boost
module load moat
module load cfitsio
module load wcslib
module load getdata
module load automake/1.15

make clean
conda activate /projects/b1092/software/toast-python

#this configure has the mpi include in CFLAGS, CXXFLAGS, CPPFLAGS and has mpi lib64 in LDFLAGS
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/lib64 -L/projects/b1092/software/toast-python/lib" BOOST_ROOT=/projects/b1092/software/boost/1.61.0

make clean
make
#no errors!
make install
make check
#all (2) tests passed

#6/14/19
#made a module for toast that loads all the dependency modules, only have to `module use ...` and then `module load toast` now
module use /projects/b1092/modules
module load toast

#also noticed that the old toast module modified the python path to include pytoast, so I moved pytoast from the old project space to the new, and the toast module still adds this directory to the python path

#trying to use toast now:
#using old_toast_things/scripts/toast_mickey_500.sh
export SCRATCH=/projects/b1092/old_toast_things/runfiles

# DIRECTORY TO RUN - $PBS_O_WORKDIR is directory job was submitted from
cd $SCRATCH/maps_2012/mickey

# SET THE NUMBER OF THREADS PER PROCESS:
export OMP_NUM_THREADS=1

toast_info "good_500_p10_2493151_run.xml" --binary "good_500_p10_2493151_run.bin"

#boost eror message:
##terminate called after throwing an instance of 'boost::exception_detail::clone_impl<boost::exception_detail::error_info_injector<std::logic_error> >'
##  what():  character conversion failed
##Aborted

#ran in gdb:
#found some things referencing boost 1.53
ldd /projects/b1092/software/toast/bin/toast_info
#looking for a library with -mt ending again:
#libboost_program_options-mt.so.1.53.0 => /lib64/libboost_program_options-mt.so.1.53.0

#made a link to our real 1.60.0 library
ln -s libboost_program_options.so.1.61.0 libboost_program_options-mt.so

#also looking for an fftw3 library, but not getting it from us:
#libfftw3.so.3 => /lib64/libfftw3.so.3
#I think this is because we tried to make all the libraries (of various precisions) in one step, and it only made the long double ones


# FFTW
module purge
module use /projects/b1092/modules
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load cmake/3.1.0
#make a directory for building with cmake (if it exists, rm it first so we start fresh)
rm -rf /projects/b1092/fftw-3.3.8/build
mkdir /projects/b1092/fftw-3.3.8/build
cd /projects/b1092/fftw-3.3.8/build


cmake .. -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=/projects/b1092/software/fftw/3.3.8/
#have to do ccmake, make, make install several times because each time we only get one set of libraries (only one precision at a time)
ccmake .. 

# must turn BUILD_TESTS OFF in ccmake, otherwise the build fails
# turn BUILD_SHARED_LIBS ON
# these two stay the same way the whole time

# Then we need to make a few sets of libraries
# turn ENABLE_OPENMP ON in ccmake
# turn both ENABLE_FLOAT and ENABLE_LONG_DOUBLE OFF (this will make the double libs, which are the defaults)

#`c', then `g' to configure and generate the Makefile
make
make install

ccmake .. #again, this time turn ENABLE_FLOAT and ENABLE_OPENMP ON, ENABLE_LONG_DOUBLE OFF
make
make install

ccmake .. #again, this time turn ENABLE_LONG_DOUBLE and ENABLE_OPENMP ON, ENABLE_FLOAT OFF
make
make install


#need to rebuild moat and toast now
#moat
#not in conda environment, never needed it before
cd /projects/b1092/MOAT_3/MOAT
module purge
module use /projects/b1092/modules/
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load fftw
module load lapack
module load boost
./configure --prefix=/projects/b1092/software/moat --with-boost=/projects/b1092/software/boost/1.61.0 BOOST_ROOT=/projects/b1092/software/boost/1.61.0 MPICXX=mpic++ CC=gcc CXX=g++ F77=gfortran LIBS=-lgomp LIBS=-lfftw3 --with-fftw-libs=-L/projects/b1092/software/fftw/3.3.8/lib64 CFLAGS=-I/projects/b1092/software/fftw/3.3.8/include CXXFLAGS=-I/projects/b1092/software/fftw/3.3.8/include --with-fftw-cpp=-I/projects/b1092/software/fftw/3.3.8/include
make clean

make
make check
#same dense matrix ops check fails like always
make install


#6/18/19
cd /projects/b1092/TOAST_5/TOAST
module purge
module use /projects/b1092/modules
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load fftw
module load lapack
module load boost
module load moat
module load cfitsio
module load wcslib
module load getdata
module load automake/1.15

make clean
conda activate /projects/b1092/software/toast-python

#this configure has the mpi include in CFLAGS, CXXFLAGS, CPPFLAGS and has mpi lib64 in LDFLAGS
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/lib64 -L/projects/b1092/software/toast-python/lib" BOOST_ROOT=/projects/b1092/software/boost/1.61.0

make clean
make
#no errors!
make check
#all (2) tests passed
make install


#trying to run toast_info:
#tried many different xml files
#some "cannot to encode BLAST detector angle" because they don't have the angle field
toast_info mickey_hen_500_run.xml --binary mickey_hen_500_run.bin
#terminate called after throwing an instance of 'toast::exception'
 # what():  Exception at line 201 of file ../../../experiments/blast/IO/dirfile_io_blast.cpp:  Failed to get dirfile start time
#Aborted

toast_info mickey_good_500_p10_good_C_run.xml --binary mickey_good_500_p10_good_C_run.bin19
#terminate called after throwing an instance of 'toast::exception'
 # what():  Exception at line 94 of file ../../../experiments/blast/IO/toast_detector_blast.cpp:  cannot encode BLAST detector angle
#Aborted

#some failed to get dirfile start time, because they are using the wrong suffix for the detector files, use _P24_C22_D20_F05_T19_ISC11SH_LMF
#nope, that doesn't work either
#this one after replacing suffixes
toast_info mickey_hen_500_run.xml --binary mickey_hen_500_run.bin
#terminate called after throwing an instance of 'toast::exception'
 # what():  Exception at line 201 of file ../../../experiments/blast/IO/dirfile_io_blast.cpp:  Failed to get dirfile start time
#Aborted

#do I need to replace the other suffix, is it for the pointing data?


#going to rebuild toast using libtool/2.4.6 from system instead of /artspace/pascal, don't know why we were doing that...

cd /projects/b1092/TOAST_5/TOAST
module purge
module use /projects/b1092/modules
module load python
module load gcc/4.6.3
module load mpi/openmpi-1.6.3-gcc-4.6.3
module load fftw
module load lapack
module load boost
module load moat
module load cfitsio
module load wcslib
module load getdata
module load libtool/2.4.6
module load automake/1.15

make clean
conda activate /projects/b1092/software/toast-python

#this configure has the mpi include in CFLAGS, CXXFLAGS, CPPFLAGS and has mpi lib64 in LDFLAGS
./configure --prefix=/projects/b1092/software/toast --with-lapack=/projects/b1092/software/lapack/3.6.0/lib64/liblapack.so --with-blas=/projects/b1092/software/lapack/3.6.0/lib64/libblas.so --with-cfitsio=/projects/b1092/software/cfitsio/3.45 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1092/software/moat/bin/moatconfig --with-wcslib=/projects/b1092/software/wcslib/5.15 --enable-exp-blast --with-getdata=/projects/b1092/software/getdata/0.9.3 CFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CXXFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" CPPFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/include -I/projects/b1092/software/wcslib/5.15/include/wcslib-5.15 -I/projects/b1092/software/getdata/0.9.3/include -I/projects/b1092/software/boost/1.61.0/include -I/projects/b1092/software/boost/1.61.0/include/boost" LDFLAGS="-I/software/mpi/openmpi-1.6.3-gcc-4.6.3-RH7/lib64 -L/projects/b1092/software/toast-python/lib" BOOST_ROOT=/projects/b1092/software/boost/1.61.0

make clean
make
#no errors!
make check
#all (2) tests passed
make install

#still has artspace lib, because our mpi relies on it

#tried running in an interactive session:
srun -A b1094 -p ciera-std -t 1:00:00 --mem=50G -N 1 -n 28 --pty bash -l
module use /projects/b1092/modules
module load toast
mpirun toast_mpi_map /projects/b1092/old_toast_things/runfiles/maps_2012/mickey/good_500_p10_2493151_run.bin --bin --diagntt --cov --gls --gls_maxiter 1 --gls_dump_iter -1 --rcond 0.01 --dist_chan 16 --out good_500_p10_2493151_run_test
#terminate called after throwing an instance of 'toast::exception'
  #what():  Exception at line 146 of file toast_run_binary.cpp:  File "/projects/b1092/old_toast_things/runfiles/maps_2012/mickey/good_500_p10_2493151_run.bin" was generated by a different source revision (101f23b6d7cfab4fed4ccbd1061d336e0dd582c0) than the current library (657b30112bcc6c79c7a6546596eccac91203366b)
#also tried different -np parameters passed to mpirun and setting OMP_NUM_THREADS to see if toast was starting the right number of threads, and it was.
toast_mpi_map --help #this didn't work, it would just sit there for a long time, not give the output or throw an error
ldd /path/to/toast_mpi_map #compared this to what you get on a login node, no difference
toast_map --help #this one worked, some kind of mpi problem


#6/25/19

module use /projects/b1092/modules
module load toast
conda activate /projects/b1092/software/toast-python
srun -A b1094 -p ciera-std -t 1:00:00 --mem=50G -N 1 -n 28 --pty bash -l
mpirun toast_mpi_map /projects/b1092/old_toast_things/runfiles/maps_2012/mickey/good_500_p10_2493151_run.xml --bin --diagntt --cov --gls --gls_maxiter 1 --gls_dump_iter -1 --rcond 0.01 --dist_chan 16 --out good_500_p10_2493151_run_test
#waited a long time, gave up

# to check available cores on each node:
sinfo -N -p ciera-std -o %C
# output (allocated, idle, other, total)
CPUS(A/I/O/T)
13/15/0/28
22/6/0/28
26/2/0/28
28/0/0/28
22/6/0/28
28/0/0/28
28/0/0/28
25/3/0/28
19/9/0/28

#errors:
  what():  Exception at line 330 of file ../../../experiments/blast/IO/toast_pointing_blast.cpp:  cannot read pointing at non-standard sample rate: 100.158 (expect 0, err: inf)
# the variable rate_ is set to zero and remains zero
#6/27/19
#I edited the xml file again, I changed the flags in the pointing tag, and toast_info had no problems, so I wanted to try to run toast_mpi_map

#requested a job with only 6 cores
srun -A b1094 -p ciera-std -t 1:00:00 --mem=50G -N 1 -n 6 --pty bash -l
#I get the following prompt:
bash-4.2$
#but it should be the regular one. Plus, I can't access the project space or the home space

#06/28/19 -Alper
#Importing blast.config and blast.mapmaker without an error so that "toast_make_all_runs.py" 
#could run and create an xml file correctly. I did the installation on the compute node
#by submitting an interactive job. After the installation is completed, I logged out from
#the interactive sessions and loaded imported the blast.config and blast.mapmaker on
#the login node.

#On the compute node (interactive session)

$ cp -r * /projects/b1092/lib64/python2.7/site-packages/pyblast /projects/b1092/pyblast

#Edited /projects/b1092/pyblast/setup.py to comment out line 31 (starting with git_hash = ..)

$ module use /projects/b1092/modules
$ module load python/anaconda
$ conda create -p /projects/b1092/software/pyblast-env python=2.7
$ source activate /projects/b1092/software/pyblast-env
$ cd /projects/b1092/pyblast
$ python setup.py install (this installs within pyblast-env)
$ cp -r /projects/b1092/software/toast/lib/python2.7/site-packages/pytoast /projects/b1092/software/pyblast-env/lib/python2.7/site-packages/

$ cp /projects/b1092/software/getdata/0.9.3/lib/python2.7/site-packages/pygetdata.* /projects/b1092/software/pyblast-env/lib/python2.7/site-packages/
$ conda install numpy
$ conda install scipy
$ source deactivate

$ logout #end interactive session and go back to login onde

$ module load fftw/3.3.8 cfitsio/3.45 getdata/0.9.3 wcslib/5.15 boost/1.61.0 python/anaconda
$ python
#>>> import blast.config
#>>> import blast.mapmaker
#>>> 

#On the compute node this did not work as I encountered libboost_python-mt.so.1.53.0 error. 
#See below for error
#I think Paul was creating a symlink for this file.

#(/projects/b1092/software/pyblast-env) [egc2975@qnode8101 boost]$ python
#Python 2.7.16 |Anaconda, Inc.| (default, Mar 14 2019, 21:00:58)
#[GCC 7.3.0] on linux2
#Type "help", "copyright", "credits" or "license" for more information.
#>>> import blast.config
#>>> import blast.mapmaker
#Traceback (most recent call last):
#  File "<stdin>", line 1, in <module>
#  File "/projects/b1092/software/pyblast-env/lib/python2.7/site-packages/blast/mapmaker/__init__.py", line 11, in <module>
#    from params import *
#  File "/projects/b1092/software/pyblast-env/lib/python2.7/site-packages/blast/mapmaker/params.py", line 15, in <module>
#    from pytoast.blast.runblast import ToastRunConfig
#  File "/projects/b1092/software/pyblast-env/lib/python2.7/site-packages/pytoast/blast/runblast.py", line 11, in <module>
#    import pytoast.core as pt
#  File "/projects/b1092/software/pyblast-env/lib/python2.7/site-packages/pytoast/core/__init__.py", line 2, in <module>
#    from _pytoast import *
#ImportError: libboost_python-mt.so.1.53.0: cannot open shared object file: No such file or directory

#On the login node it does not give libboost_python-mt.so.1.53.0 error.

