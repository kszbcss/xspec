#! /bin/bash

# See issues 33 & 29 for several comments about shell scripts:
# http://code.google.com/p/xspec/issues/detail?id=33
# http://code.google.com/p/xspec/issues/detail?id=29

export XSPEC_HOME="."
export CLASSPATH=".:/Library/Application Support/oxygen9.3/lib/saxon9.jar"

##
## some variables ############################################################
##

INSTALL_DIR=`dirname $0`
# safety checks
if test \! -d "${INSTALL_DIR}"; then
    echo "INTERNAL ERROR: The install directory is not a directory?!?"
    echo "  -> ${INSTALL_DIR}"
    exit 1;
fi
if test \! -f "${INSTALL_DIR}/xspec.bat"; then
    echo "INTERNAL ERROR: The install directory seems to be corrupted?!?"
    echo "  -> ${INSTALL_DIR}"
    exit 1;
fi

##
## utility functions #########################################################
##

die() {
    echo
    echo "*** $@" >&2
    exit 1
}

if [ `uname` = "Darwin" ]; then
    OPEN=open
else
    OPEN=see
fi

##
## options ###################################################################
##

XSPEC=$1

if [ ! -f "$XSPEC" ]
then
    echo File not found.
    echo Usage:
    echo   xspec filename [coverage]
    echo     filename should specify an XSpec document
    echo     if coverage is specified, outputs test coverage report
    exit 1
fi

COVERAGE=$2

##
## files and dirs ############################################################
##

TEST_DIR=$(dirname "$XSPEC")/xspec
TARGET_FILE_NAME=$(basename "$XSPEC" | sed 's:\...*$::')

COMPILED=$TEST_DIR/$TARGET_FILE_NAME.xsl
COVERAGE_XML=$TEST_DIR/$TARGET_FILE_NAME-coverage.xml
COVERAGE_HTML=$TEST_DIR/$TARGET_FILE_NAME-coverage.html
RESULT=$TEST_DIR/$TARGET_FILE_NAME-result.xml
HTML=$TEST_DIR/$TARGET_FILE_NAME-result.html
COVERAGE_CLASS=com.jenitennison.xslt.tests.XSLTCoverageTraceListener

if [ ! -d "$TEST_DIR" ]
then
    echo "Creating XSpec Directory at $TEST_DIR..."
    mkdir "$TEST_DIR"
    echo
fi 

##
## compile the suite #########################################################
##

echo "Creating Test Stylesheet..."
java net.sf.saxon.Transform -o:"$COMPILED" -s:"$XSPEC" \
    -xsl:"$XSPEC_HOME/generate-xspec-tests.xsl" \
    || die "Error compiling the test suite"
echo

##
## run the suite #############################################################
##

echo "Running Tests..."
if test "$COVERAGE" = "coverage" 
then 
    echo "Collecting test coverage data; suppressing progress report..."
    java net.sf.saxon.Transform -T:$COVERAGE_CLASS \
        -o:"$RESULT" -s:"$XSPEC" -xsl:"$COMPILED" \
        -it:{http://www.jenitennison.com/xslt/xspec}main 2> "$COVERAGE_XML" \
        || die "Error collecting test coverage data"
else
    java net.sf.saxon.Transform -o:"$RESULT" -s:"$XSPEC" -xsl:"$COMPILED" \
        -it:{http://www.jenitennison.com/xslt/xspec}main \
        || die "Error running the test suite"
fi

##
## format the report #########################################################
##

echo
echo "Formatting Report..."
java net.sf.saxon.Transform -o:"$HTML" -s:"$RESULT" \
    -xsl:"$XSPEC_HOME/format-xspec-report.xsl" \
    || die "Error formating the report"
if test "$COVERAGE" = "coverage" 
then
    java net.sf.saxon.Transform -l:on -o:"$COVERAGE_HTML" -s:"$COVERAGE_XML" \
        -xsl:"$XSPEC_HOME/coverage-report.xsl" "tests=$XSPEC" \
        || die "Error formating the coverage report"
    $OPEN "$COVERAGE_HTML"
else
    $OPEN "$HTML"
fi

echo "Done."
