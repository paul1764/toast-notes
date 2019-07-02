#Some of this information comes from Paul's notebook, other comes from emails between Paul, Giles, Pascal, Laura, and Steve. Mostly I have noted where something came from.

7/25/16 - notebook

quest has 128 GB/node

scaling from BLASTPol, BLAST-TNG will need all the memory in quest to do map-making


7/29/16 - notebook

python creates an XML runfile

XML file is read by toast – actually first converted into a binary file by toast_info, toast_mpi_map uses the binary as input.

 – the input file tells toast which observations to use, which stokes parameters to solve for, among other things


Work log:

changed data_etc_dir = /projects/b1011/fissel/data/etc

ran python setup.py install --home=/projects/b1011/fissel/pyblast

add /projects/b1011/fissel/pyblast/lib to python path, then:

import blast.config

works, but


import blast.mapmaker


fails.


#blast.mapmaker relies on pytoast.blast.runblast module, which I don't see anywhere


8/9/16 - notebook

need to find .xml and .sh files on hen and their paths

we want to replicate directory structure on quest

in the minimal blast dataset (last three letters often initials of person who made the file):

f_p22_f05_lmf:     flags

HWPR_ANG_pca: hwp angle

isc...                     :       pointing solution

      ...shifted     :        shifted for star camera pointing offsets

p24_c22_d20:         timestreams

photo                :        gain offsets


mp.dirfile_replace="/scratch2/r/rbond/sjb/blast_2012"

this path should be to minimal_blast_2012 on quest


edit $PYTHONPATH

change make_toast.py to get directories organized in the right way


8/10/16 - notebook

./autogen.sh → after notes

module load boost

after configure

Installation of toast:

./configure

make → fails in test

make install

autogen.sh only used if you need to regenerate the configure script

configure needed (prefix): lapak, blas, cfits.io, moat

I never found moat, tried every instance of maot.hpp, moat_mp.hpp and libmoat.so (.0.0.0) that I found, none worked.


Module files loaded by Pascal:

    automake/1.14
    autoconf/2.69
    automake/1.15
    python/anaconda
    mpi/openmpi-1.63-gcc-4.6.3
    gcc/4.8.3
    CfitsIO/3.37
    blas-lapack/3.5.0_gcc
    boost/1.56.0


8/12/16 - notebook

    what is os.environ["SCRATCH"]? – just an environment variable named scratch, I think this is set in one of the python scripts
    no scratch, even when I do an actual job submit to compute nodes
    no write access, couldn't change access, so made a new copy to edit (of what?) – maybe of the python scripts
    change path in line 62 and 78 (of what?)
    ...pascal/software/moat/bin → is the moat installation


8/15/16 - notebook

    Pyblast libraries
        config/bolotable.py: parses a configuration file
            divides bolos into top, bottom, high IP, low IP, etc.
            has a function to give stats on the table (# good bolos, etc)
        config/obslog.py: parses obslog config file
            uses target to decide which scan types to use
            parses log as numpy array
            functions to get which obs are good for a given target, convert things to chunks
            jackknife tests by time, list good chunks, etc
        config/scoffset.py
            similar, parses offset file to a numpy array
        mapmaker/config.py: tables for looking up mapmaking settings and file locations based on the map to be made
        mapmaker/dependent.py: classes for declaring parameters to be dependent on others
        mapmaker/flag_frac.py: determines how many samples are flagged in one map
        params.py: handles parameters in a common way, uses dependent_parameter
        runnaive.py: how to run naivepol
            encode parameters for map into a...
            command line subprocess that actually calls the mapmaker
    create an xml file on hen in my directory?
    bolotable file: offset of each bolometer
    obslog: excel, index ranges for what targets were observed when
    scoffsets: any auxiliary info in scoffsets? probably in Natalie's thesis
    reasonable to run naive map, single bolo map on hen if it doesn't work on quest.


8/16/16 - notebook

    Trying to run toast_make_all_runs.py on hen
    changed paths so it saves in my home on hen
    works for mp.use_toast = True & mp.use_naive = False
    but not for mp.use_naive = True & mp.use_toast = False
    gives warning: naivepol requires write and run
    added mp.run() (actually if-statement) and got an error in run()
    this is using scp'd version from quest that Pascal and Laura edited for quest (*_lmf)
        but I changed directories to store xml in my hen ~/blast/runfiles
    use_toast = True in the script coped from Steve (_sjb), that's where xmls are from, maybe we can test w/ these on quest since at least we have them, even though they will take longer

8/30/16 - long email

    Pascal built getdata 0.9.3, which required automake/1.15 and autoconf/2.69. Had to hack configure script to bypass tests for python, problem with syntax

8/31/16 - notebook

    alpha=0 add ; in declaration (in some source code we edited)
    use sed to edit xml file, find & replace
        must escape brackets in sed
    make sure we don't overwrite alpha_*, other parameters in getdata header files → no alpha in getdata header files
    Running toast_make_all_runs_lmf.py on hen
    blast/runfiles: correct_ip = True, do_pol = True, do_gls = False, noise_use_model = False
    blast/do_gls: do_gls = True, others same as in runfiles
    blast/no_pol: do_pol = False, others same as in runfiles
    blast/use_noise_model: use_noise_model = True, others same
    None of them put an alpha in the xml files!
    There is an alpha in pascal/software/toast2/include/toast/tpm/times.h and vec.h, is this the same alpha?

9/1/16 - long email

    #when do_polarization = False (in toast_make_all_runs_lmf.py on hen), we still get qip and other polarization columns in the xml file
    #Pascal used sed to put alpha="0.0" in the xml files, toast_info can parse it and create a binary runfile
    #ran mapmaker, failed because it couldn't find a library, we thought it was because we forgot to load a module

9/2/16 - long email

    But turns out our installation of Boost didn't have a certain shared library, so when toast ran it couldn't find that and failed (library is libboost_serialization-mt.so.5)
    Steve said that on SciNet that library was just a link to libboost_serialization.so.5, which he also says should work since version 1.42 of boost.
        Toast requires boost 1.43 or newer, we built on quest with boost 1.56
    Pascal created symlink to the regular (non-mt version) and found that other libraries then were not found, also all mt versions
    So he ran interactively and created the mt symlinks until no more were needed.

    Then toast::exception in 7 of 16 processes:

    what():  Exception at line 139 of file formats/toast_stream_native.cpp:  TOD file streamset/B5E07V/B5E07V has a different sample rate (0) than the observation in which it lies (100.158)


    Steve says this is weird, he would expect this type of error earlier, when the rate is calculated for the TOD file
    Pascal thinks the alpha=0.0 that we put in the xml file could be causing this error, also he sees toast_info checking alpha and interpreting as yaw

9/6/16 - long email

    Pascal rebuilt everything in /projects/b1011/fissel/pascal/Experimental
    now has full python 2.7 functionality
    still issues with importing blast.mapmaker, now an issue with blas/lapack header

9/8/16 - 9/19/16 - long email

    #fixed mismatched rates problem: script generating xml files had the file suffix (P24_C22...) wrong, so toast couldn't even find our TOD files
    correct suffix is: _P24_C22_D20_F05_T19_ISC11SH_LMF, this can be changed in toast_make_all_runs*.py, mp.bolo_suffix is the variable
    new error when running toast_mpi_map: what():  Exception at line 330 of file ../../../experiments/blast/IO/toast_pointing_blast.cpp:  cannot read pointing at non-standard sample rate: 100.158 (expect 100.158, err: 7.04721e-08)
    changed tolerance to from 5.0e-8 to 1.0e-7, as I found in /projects/b1011/fissel/new_toast/TOAST/experiments/blast/IO/toast_pointing_blast.cpp:line 327
    old value found in /projects/b1011/fissel/pascal/TOAST/experiments/blast/IO/toast_pointing_blast.cpp:line 327

9/20/16 - notebook

    What is alpha?
        in main toast: yaw
        in blast experiment: rate
        in IO: looks for column called alpha
    move xml from hen, try on toast

9/21/16 - notebook

    copied mickey_good_500_p10_good_run.xml on hen to mickey_hen_500_run.xml
    running toast_info: had to use sed to insert alpha column again, set alpha=1.0 (otherwise toast_detector_blast.cpp:85 gives error)
    after fixing, got error: dirfile_io_blast.cpp:201 failed to get dirfile start time, but getdata is loaded from pascal/getdata/bin
    copied good_500_p10_2493151_run.xml, had to fix paths and suffixes, toast_info runs! Need to try mapmaker
    toast_mpi_map + old hen xml _ + naive → dat file, how to get a fits?
    next: gls instead of naive, if that works try new hen xml
    find interval in pyblast to see why we have so many interval tags in new xml file, only one in old xml

9/22/16 - 9/30/16 - email

    toast_convert will convert dat files to fits files
    at first all fits files (except hits map) were all NaN
    Steve says that because the xml files had stokes="IQU" for the mapset, it would try to solve for polarization
    But if we only gave it one hwp angle, it would fail because it would try to invert a singular matrix
    so changed to stokes="I", and then it worked!
    #However, gls and naive maps looked the same, likely because we had no cross-linking (and we probably didn't have a noise model)

10/17/16 - email

    GLS ideally uses 8 scans, rising and setting at each of 4 HWP positions
    Steve recommends using toast_make_all_runs.py rather than editing xml directly
    mp.do_gls = True means a noise model with 1/f is passed to toast
    mp.do_gls = False means a white noise model is used, with fixed per-detector weights
    mp.noise_use_model = True means the noise model is a simple fit to detector PSDs
    mp.noise_use_model = False means logarithmically binned PSDs are used (not actually sure how this is a noise model)
    #Usually the noise_use_model options give the same thing, but when they aren't, Steve prefers log-binned PSD data. He used that for all his maps
    But need extra data (the PSDs) for noise_use_model = False, so with no extra data (beyond bolotable) do noise_use_model = True and that is almost as good (according to Steve)

10/18/16 - email

    Steve found the problem with angle/alpha! The git repos on galadriel did not have the latest code, so we cloned the repos to quest under new_toast and new_moat
    the main change was that "alpha" was broken up into "angle" and "hwpoffset"

11/3/16 - email

    Probably made a gls map by:
    used pyblast on hen to make a new xml file, set mp.use_gls = True, mp.noise_use_model = True
    moved to quest, edited in the same way I did the others (angle to alpha, etc) since we are using old toast still
    ran toast using this xml, got a slightly different map than the ones I got before (and different from naive maps)
    however, gls only iterated once, so we still need more testing. maybe just on another source with more sky rotation
    no new toast yet

11/17/16 - email and notebook

    New toast installed!
    installed to /projects/b1011/fissel/pascal/Experimental/toast_new

    configure invocation (from /projects/b1011/fissel/pascal/Experimental/TOAST_5/TOAST/config.log)

    ./configure --prefix=/projects/b1011/fissel/pascal/Experimental/toast_new --with-lapack=/projects/b1011/fissel/pascal/Experimental/lapack/lib64/liblapack.so --with-blas=/projects/b1011/fissel/pascal/Experimental/lapack/lib64/libblas.so --with-cfitsio=/software/supplemental/cfitsio/3.37 --with-hdf5=no MPICC=mpicc MPICXX=mpic++ MPIFC=mpif90 CC=gcc CXX=g++ FC=gfortran --with-moatconfig=/projects/b1011/fissel/pascal/Experimental/moat_new/bin/moatconfig --with-wcslib=/projects/b1011/fissel/pascal/Experimental/wcslib --enable-exp-blast --with-getdata=/projects/b1011/fissel/pascal/Experimental/getdata CFLAGS=-I/projects/b1011/fissel/pascal/Experimental/wcslib/include/wcslib-5.15 -I/projects/b1011/fissel/pascal/Experimental/getdata/include/getdata -I/projects/b1011/fissel/pascal/Experimental/boost/include -I/projects/b1011/fissel/pascal/Experimental/boost/include/boost CXXFLAGS=-I/projects/b1011/fissel/pascal/Experimental/wcslib/include/wcslib-5.15 -I/projects/b1011/fissel/pascal/Experimental/getdata/include/getdata -I/projects/b1011/fissel/pascal/Experimental/boost/include -I/projects/b1011/fissel/pascal/Experimental/boost/include/boost CPPFLAGS=-I/projects/b1011/fissel/pascal/Experimental/wcslib/include/wcslib-5.15 -I/projects/b1011/fissel/pascal/Experimental/getdata/include/getdata -I/projects/b1011/fissel/pascal/Experimental/boost/include -I/projects/b1011/fissel/pascal/Experimental/boost/include/boost LDFLAGS=-L/software/anaconda2/lib -L/projects/b1011/fissel/pascal/Experimental/python/lib


    mostly this shows us what versions of libraries we were using

    from notes, had to change #include <getdata/dirfile.h> to #include <dirfile.h> in experiments/blast/IO/toast_blast.hpp

11/18/16 - notebook

    reinstalled toast in correct directory: toast_new
    overwrote old toast binaries though
    #running toast_info, couldn't find a boost library, so I made a link from the one it looked for (1.55) to the correct one (1.61) in our private boost install
    copied an xml file to change alpha back to angle (since toast now looks for angle)
    new xml: mickey_good_500_new_toast.xml has all the scans except the bad one
    mickey_500_new_toast_gls_1_scan.xml: new, for scan tests. going to have one xml file for each scan, will have the scan number in the xml file name
    also new submit script for tests: toast_new_mickey_500_test.sh
    first test with all scans ran out of time, retrying with 24 hours
    finished at ~2:55pm on 11/18
    ..._long_test has 24 hours of time, left the nodes, ppn the same
    ran a second test, all the same settings, added a 2 to output names

    toast in gls mode outputs a "binned" file, seems to be the same as naive map
