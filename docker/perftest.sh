#!/bin/bash
#
# perftest, run simple io benchmarking on persistent volume
# (or to use empheral, set WORKDIR to /var/tmp)
#

#
# Get set ENV vars, unless already set in dc
#
test -z "$TESTCPU" && TESTCPU=1              ### Run the cpu test(s)?
test -z "$TESTMEM" && TESTMEM=1              ### Run the mem test(s)?
test -z "$TESTIO"  && TESTIO=1               ### Run the io test(s)?
test -z "$TESTFIO" && TESTFIO=0              ### Run the fio test?
test -z "$MAXTIME" && MAXTIME=90             ### Max run time for benchmarks

### io specific params
test -z "$SIZE_GB" && SIZE_GB=1              ### Max file size for tests
test -z "$FILENUM" && FILENUM=16             ### Number of files
test -z "$MODES"   && MODES="rndrd rndwr rndrw" ### Read/Write Modes to test
test -z "$THREADS" && THREADS="4"            ### Threads, may be a list "1 4 8"

test -z "$WORKDIR" && WORKDIR=/app/web/mnt   ### Persistant volume mount point
test -z "$IMAGE"   && IMAGE=unknown          ### Runnig docker image version
 
PODNAME=`hostname`
OUTFILE=$WORKDIR/perftest.${PODNAME}.txt
RUNFILE=$WORKDIR/perftest.${PODNAME}.run
DONEFILE=$WORKDIR/perftest.${PODNAME}.done

out() {
    echo "$*" >> $OUTFILE
}

msg() {
    echo -e "===" `date +'%Y-%m-%d %H:%M:%S'` "$*" >>  $OUTFILE
}

#
# initialize
#
test -f $OUTFILE && {
    mv $OUTFILE $OUTFILE.`date +'%Y-%m-%d_%H%M%S'`
}
echo "" > $OUTFILE
touch $RUNFILE
rm -f $DONEFILE

#
# Run perftests
#
msg "cd $WORKDIR"
cd $WORKDIR

msg "========================= test info ==========================="
WORKER=`nslookup localhost |head -1 |awk '{print "nslookup "$2}' |sh -x | grep name | awk '{print $4}' `
FSTYPE=`mount |egrep 'gluster|nfs|mnt' | awk '{print $5}'`
DF=`df -h . `
out "ENABLED TESTS: TESTIO=$TESTIO TESTFIO=$TESTFIO TESTCPU=$TESTCPU TESTMEM=$TESTMEM"
out "IMAGE        : $IMAGE"
out "PODNAME      : $PODNAME"
out "WORKER       : $WORKER"
out "FSTYPE       : $FSTYPE"
out "SIZE_GB      : $SIZE_GB"
out "MAXTIME      : $MAXTIME"
out "$DF"
msg "==============================================================="

if [ "$TESTIO" -eq 1 ]; then
msg "============================ dd ==============================="
msg "Starting dd, writing ${SIZE_GB}Gb sequentially..."
msg "dd if=/dev/zero of=$WORKDIR/testfile1 bs=4k count=256000"
dd if=/dev/zero of=$WORKDIR/testfile1 bs=4k count=256000 >> $OUTFILE  2>&1
rm -f $WORKDIR/testfile1
msg "==============================================================="
msg "Finished dd."

msg "=========================== ioping ============================"
msg "Starting ioping for latency...."
msg "ioping -c 10 ."
ioping -c 10 .  >> $OUTFILE 2>&1 
msg "==============================================================="
msg "Finished ioping."
fi

ORGDIR=`pwd`
mkdir ${PODNAME}
cd ${PODNAME}

if [ "$TESTIO" -eq 1 ]; then
BASEOPTS="fileio --file-total-size=${SIZE_GB}G --time=${MAXTIME} --max-requests=0 --file-num=${FILENUM} --file-io-mode=async"
for MODE in $MODES; do
    for THREAD in $THREADS; do
        EXTRAPOPTS=" --file-test-mode=$MODE --threads=${THREAD}"
        SYSOPTS="${BASEOPTS} ${EXTRAPOPTS}"
        msg "========================== sysbench io ========================="
        msg "sysbench ${SYSOPTS} prepare"
        sysbench ${SYSOPTS} prepare >> $OUTFILE  2>&1
        msg "sysbench ${SYSOPTS} run"
        sysbench ${SYSOPTS} run >> $OUTFILE  2>&1
        msg "sysbench ${SYSOPTS} cleanup"
        sysbench ${SYSOPTS} cleanup >> $OUTFILE  2>&1
        msg "==============================================================="
    done
done
msg "Finished sysbench."
fi

if [ "$TESTFIO" -eq 1 ]; then
BASEOPTS="--name=fio.${PODNAME} --direct=1 --rw=readwrite --bs=4k --size=${SIZE_GB}G --numjobs=1 --time_based --runtime=${MAXTIME} --group_reporting"
msg "============================= fio ============================="
msg "fio ${BASEOPTS}"
     fio ${BASEOPTS} >> $OUTFILE 2>&1
msg "==============================================================="
rm -f fio.*
msg "Finished fio."

fi

if [ "$TESTMEM" -eq 1 ]; then
msg "========================= sysbench mem ========================"
BASEOPTS="--test=memory --memory-block-size=1K --memory-scope=global --memory-total-size=100G"
for MODE in read write; do
msg "sysbench $BASEOPTS --memory-oper=$MODE run"
sysbench $BASEOPTS --memory-oper=$MODE run >> $OUTFILE  2>&1
msg "==============================================================="
done
msg "Finished sysbench mem."
fi

if [ "$TESTCPU" -eq 1 ]; then
msg "========================= sysbench cpu ========================"
BASEOPTS="cpu --cpu-max-prime=2000 run"
msg "sysbench $BASEOPTS"
sysbench $BASEOPTS >> $OUTFILE 2>&1
msg "==============================================================="
msg "Finished sysbench cpu."

msg "========================= stress-ng ========================"
BASEOPTS="--cpu 4 --cpu-method matrixprod  --metrics-brief -t $MAXTIME"
msg "stress-ng $BASEOPTS"
stress-ng $BASEOPTS >> $OUTFILE  2>&1
msg "==============================================================="
msg "Finished stress-ng cpu test."
fi


cd $ORGDIR
rm -f $RUNFILE
touch $DONEFILE
