#!/usr/bin/perl
#
# DESCRIPTION: Call testcases included in check-multipath.pl (in current directory)
#              and compare output with expected result.
#
#              Put this script in the same directory as check-multipath.pl 
#              and call ./TEST_check-multipath.pl
#
#              ALWAYS USE IDENTICAL VERSIONS OF THE TWO SCRIPTS!
#
#
# AUTHOR:      Hinnerk Rümenapf (hinnerk.ruemenapf@rrz.uni-hamburg.de)
#
# Copyright (C) 2013 
# Hinnerk Rümenapf
#
#
#  Vs  0.1.7    Created test script for corresponding version of check-multipath.pl, Initial Version
#      0.1.7a   Improvements, return-code handling
#      0.1.8    Testcases for LUN names without HEX-ID
#      0.1.9    So far NO testcases for new Option --extraconfig, just minor changes.
#

use strict;
use warnings;
use Switch;

use Getopt::Long qw(:config no_ignore_case);


# === Version and similar info ===
my $NAME    = 'TEST_check-multipath.pl';
my $VERSION = '0.1.9   06. MAR. 2013';
my $AUTHOR  = 'Hinnerk Rümenapf';
my $CONTACT = 'hinnerk.ruemenapf@uni-hamburg.de  hinnerk.ruemenapf@gmx.de';


# Exit codes
my $E_OK       = 0;
my $E_WARNING  = 1;
my $E_CRITICAL = 2;
my $E_UNKNOWN  = 3;

# Nagios error levels reversed
my %reverse_exitcode
  = (
     0 => 'OK',
     1 => 'WARNING',
     2 => 'CRITICAL',
     3 => 'UNKNOWN',
    );



#
# Exptected test output, starting from index 1 (parameter  -d 1  for check-multipath.pl)
#
my @expectedTextOutput = (
"",
"O: LUN mpathb: 4/4.;O: LUN mpatha: 4/4.;",                                         # 1
"W: LUN mpathb: less than 4 paths (3/4).;O: LUN mpatha: 4/4.;",                     # 2 
"C: LUN mpathb: less than 2 paths (0/4)!;C: LUN mpatha: less than 2 paths (0/4)!;", # 3
"O: LUN mpathb: 4/4.;",                                                             # 4 
"W: LUN mpathb: less than 4 paths (2/4).;",                                         # 5
"C: LUN mpathb: less than 2 paths (1/4)!;",                                         # 6
"C: LUN mpathb: less than 2 paths (0/4)!;",                                         # 7
"C: LUN mpathb: less than 2 paths (1/4)!;C: LUN mpatha: less than 2 paths (1/4)!;W: LUN mpatha, path sde: ERROR.;W: LUN mpatha, path sdc: ERROR.;W: LUN mpathb, path sdk: NOT active.;W: LUN mpathb, path sdh: ERROR.;W: LUN mpathb, path sdf: ERROR.;",
"W: No LUN found or no multipath driver.;",
"ERROR: Line 4 not recognised. Expected path info, new LUN or nested policy:\n'4:0:1:1 sdd 8:48  active ready running' |TESTCASE|\n",
"ERROR: Line 1 not recognised. Expected path info, new LUN or nested policy:\n'mpatha 36000d77b000048d117c68c81bf7c160a) dm-0 FALCON,IPSTOR DISK' |TESTCASE|\n",
"ERROR: Line 2 not recognised. Expected LUN info:\n'sisze=2.0T features='1 queue_if_no_path' hwhandler='0' wp=rw' |TESTCASE|\n",
"ERROR: Path info before LUN name. Line 1:\n'  |- 4:0:1:1 sdd 8:48  active ready running' |TESTCASE|\n",
"O: LUN mpathb: 4/4.;O: LUN mpatha: 4/4.;",
"C: LUN mpatha: less than 2 paths (1/4)!;W: LUN mpathb: less than 4 paths (2/4).;W: LUN mpatha, path sdh: ERROR.;W: LUN mpatha, path sdd: ERROR.;W: LUN mpatha, path sdc: NOT active.;W: LUN mpathb, path sde: ERROR.;",
"C: LUN dm-0: less than 2 paths (1/4)!;O: LUN dm-2: 4/4.;O: LUN dm-5: 4/4.;",
"C: LUN dm-0: less than 2 paths (1/4)!;W: LUN dm-2: less than 4 paths (3/4).;W: LUN dm-5, path sdj: ERROR.;W: LUN dm-2, path sdc: NOT active.;W: LUN dm-5: less than 4 paths (2/4).;",
"O: LUN MYVOLUME: 8/4.;",
"W: LUN MYVOLUME, path sdj: NOT active.;W: LUN MYVOLUME, path sdh: ERROR.;W: LUN MYVOLUME, path sde: ERROR.;O: LUN MYVOLUME: 5/4.;",
"O: LUN foobar_postgresql_lun0: 4/4.;O: LUN foobar_backup_lun0: 4/4.;",
"C: LUN foobar_postgresql_lun0: less than 2 paths (0/4)!;W: LUN foobar_postgresql_lun0, path -: ERROR.;",
"W: LUN tex-lun4: less than 4 paths (2/4).;W: LUN tex-lun3: less than 4 paths (2/4).;",
"W: LUN 1STORAGE_server_target2: less than 4 paths (2/4).;",
"C: LUN 1STORAGE_server_target2: less than 2 paths (1/4)!;W: LUN 1STORAGE_server_target2, path sdd: ERROR.;",
    );

my @expectedReturnCode = ( 42,
			   $E_OK,       $E_WARNING,   $E_CRITICAL, $E_OK,       $E_WARNING,
                           $E_CRITICAL, $E_CRITICAL,  $E_CRITICAL, $E_WARNING,  $E_UNKNOWN,
			   $E_UNKNOWN,  $E_UNKNOWN,   $E_UNKNOWN,  $E_OK,       $E_CRITICAL,
			   $E_CRITICAL, $E_CRITICAL,  $E_OK,       $E_WARNING,  $E_OK,
			   $E_CRITICAL, $E_WARNING,   $E_WARNING,  $E_CRITICAL,
    );


if ( scalar( @expectedTextOutput) != scalar(@expectedReturnCode) ) {
    print "INTERNAL ERROR: Testcase count mismatch.\n";
    print "Text output : ".scalar( @expectedTextOutput )."\n";
    print "Return codes: ".scalar( @expectedReturnCode )."\n";
    exit 7;
} # if
my $testcaseCount = scalar( @expectedTextOutput )-1;



# Usage text
my $USAGE = <<"END_USAGE";

Usage: $NAME [OPTION]...
END_USAGE



# Help text
my $HELP = <<"END_HELP";

$NAME   $VERSION

    Call testcases included in check-multipath.pl (in current directory)
    and compare output with expected results.

    Put this script in the same directory as check-multipath.pl 
    and call ./TEST_check-multipath.pl

    ALWAYS USE IDENTICAL VERSIONS OF THE TWO SCRIPTS!

see:
 http://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check-2Dmultipath-2Epl/details

OPTIONS:

  -h, --help          Display this help text
  -V, --version       Display version info
  -v, --verbose

END_HELP


# Version and license text
my $LICENSE = <<"END_LICENSE";

$NAME   $VERSION

Copyright (C) 2013 $AUTHOR
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by
$AUTHOR <$CONTACT>

END_LICENSE




# Options with default values
my %opt
  = ( 'help'          => 0,
      'version'       => 0,
      'verbose'       => 0,
      'test'          => 0, 
    );


# Get options
GetOptions('h|help'           => \$opt{help},
	   'V|version'        => \$opt{version},
	   'v|verbose'        => \$opt{verbose},
	  ) or do { print $USAGE; exit 3 };


# If user requested help
if ($opt{'help'}) {
    print $USAGE, $HELP;
    exit 0;
}

# If user requested version info
if ($opt{'version'}) {
    print $LICENSE;
    exit 0;
}

#=====================================================================

#---------------------------------------------------------------------
# Functions
#---------------------------------------------------------------------


#---------------------------------------
# print text for returncode if defined
sub printRc {
    my ($rc) = @_;
    if (defined ($reverse_exitcode{$rc}) ) {
	return $reverse_exitcode{$rc};
    } else {
	return "#$rc#";
    } # if    
} # sub

#=====================================================================



my $expectedVersion = '';
if ( $VERSION =~ m!^([\d\.]+)! ) {
    $expectedVersion = $1;
} else {
    print "INTERNAL ERROR: malformed version string '$VERSION'\n";
    exit 6;
} 


my $command = './check-multipath.pl -V';
my $gotResult =  qx($command);
my $pluginVersion = '';
if ($gotResult =~ m!check-multipath.pl\s+([\d\.]+)\s+\d+\.\s+\w+\.\s+\d+\n!) {
    $pluginVersion = $1;
}

if ($pluginVersion ne $expectedVersion) {
    print "\nERROR : version mismatch or error calling plugin.\n\n";
    print "GOT     : '$pluginVersion'\n";
    print "EXPECTED: '$expectedVersion'\n\n";
    print "Plugin output was:\n";
    print "==================\n";
    print "[$gotResult]\n\n";
    exit 5;
}


my $ret         = 0;
my $commandBase = "./check-multipath.pl -l ';' -t -v -S -d ";

my $di          = -1;
my $failedCount = 0;
foreach my $expectedResult (@expectedTextOutput) {

    $di++;
    if ($di == 0) { 
	next; 
    }

    $command = $commandBase . $di;
    my $expectedRc = $expectedReturnCode[$di];

    $gotResult =  qx($command);
    my $gotRc = $?;
    if ($gotRc != -1) {
	$gotRc = $gotRc >> 8;
    }

    my $failed =  ($gotResult ne $expectedResult) || ($expectedRc != $gotRc);

    if (!$failed) {
	if ($opt{'verbose'}) {
	    print "# $di OK\n$gotResult\n[".$reverse_exitcode{$expectedRc}."]\n\n";
	} else {
	    print "$di ";
	} # if
    } else {
	print "\n";
	if ($opt{'verbose'}) {
	    print "=============================\n";
	    print "# $di FAILED! ##\n";
	} else {
	    print "# $di FAILED!\n";
	}

	if ($gotResult ne $expectedResult) {
	    print "GOT:\n'$gotResult'\n\n";
	    print "EXPECTED:\n'$expectedResult'\n";
	    if  ($expectedRc != $gotRc) {
		print "\n";
	    }
	} # if

	if  ($expectedRc != $gotRc) {
	    print "EXPECTED RETURNCODE '$expectedRc' [".printRc($expectedRc)."]\n";
            print "     GOT RETURNCODE '$gotRc' ["     . printRc($gotRc)    ."]\n";
	} # if


	if ($opt{'verbose'}) {
	    print "=============================\n";
	}
	print "\n";
	$ret = 1;
	$failedCount++;
    } # if
   
} # foreach


if ($failedCount > 0){
    print "\n$failedCount of $testcaseCount testcases FAILED\n";
    if ($opt{'verbose'}) {
	print "=============================\n";
    }
    print "\n";
} else {
    print "[All $testcaseCount testcases OK]\n\n";
} # if

exit $ret;
