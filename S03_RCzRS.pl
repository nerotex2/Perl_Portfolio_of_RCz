#!/usr/bin/perl
#=====================================================================#
#                                RCzRS
#                       ----------------------
#  Date       : 2011/08/08, v0.42
#  Copyright  : (c) 2010-2011 by Rafal Czarny
#  Email      : rafal.czarny@oracle.com
#---------------------------------------------------------------------#
#
#  This is a script that works as wrapper for 'rsync' (RS)
#  
#  
#=====================================================================#
#
# We use standard 'Getopt' module to handle all options
  use Getopt::Long;
  Getopt::Long::Configure ('bundling','ignore_case','pass_through');
#
#
# Default flags and switches
# ---------------------------
#
# This is used mainly to create switches and other global variables
	$LOGFLS_DIR = '/home/Other/Logs/RSync'; # Log Dir given
#
	$USE_HELP  = 0;   # should we print a quick 'help' messages?
	$EMPTYARGS = 0;   # it will be "1" if there is no email numbers are given at all
#
	$RS_SOURCE  = '';  # Source directory
	$RS_BACKUP  = '';  # Backup folder / Destination
	$RS_EXCLUD  = '';  # Filename for the exclude operations
	$RS_LOGFLS  = '';  # Log file given 
	$RS_TEST    = 0;   # Do we perform test run (dryrun)
	$RS_EXVERB  = 0;   # Extra verbosity for this run
	$RS_DELETE  = 0;   # Delete file/folders that are not sync
# 
#
# The core of the script
# -----------------------
#
# Read and proceed all defined options, all these options will be removed from the @ARGV table
	GetOptions("d=s" => \$RS_BACKUP,
               "e=s" => \$RS_EXCLUD,
               "l=s" => \$RS_LOGFLS,
               "h"   => \$USE_HELP,
               "n"   => \$RS_TEST,
               "s=s" => \$RS_SOURCE,
               "v"   => \$RS_EXVERB,
               "x"   => \$RS_DELETE
              );
#
#
# If the -h option is used, then we will print small help and quit the script
	if ($USE_HELP) {
		RSHelp();	exit(0);
	}
#
# 
# Addtional variables and tables used
# ------------------------------------
#
	$RS_ACTUALDT = `date '+20%y-%m-%d_T%H-%M-%S'`;
	chomp($BKACTUALDT);
	@RestOfOptions = @ARGV;
#
# 
# First verifications
# --------------------
#   *** Disabled for now! ***
#	if (!-e $RS_SOURCE) {
#		RSErrorAndExit("The directory: $RS_SOURCE doesn't exist!");
#	}
#	if (($RS_EXCLUD ne '') && (!-e $RS_EXCLUD)) {
#		RSErrorAndExit("The file: $RS_EXCLUD doesn't exist!");
#	}
#
# 
#---------------------------------------------------------------------#
#
#
# Script core
# ------------
#
	$RS_CORE_OPT = "--recursive --links --times -D --numeric-ids --protect-args --delete --human-readable --itemize-changes --stats --progress";
	if ($RS_EXCLUD ne '') {
		$RS_CORE_OPT .= " --exclude-from=$RS_EXCLUD";
	}
	if ($RS_DELETE) {
		$RS_CORE_OPT .= " --delete-excluded";
	}
	if ($RS_EXVERB) {
		$RS_CORE_OPT .= " -vv"; }
	else {
		$RS_CORE_OPT .= " --verbose";
	}
	if ($RS_TEST) {
		$RS_CORE_OPT .= " --dry-run";
	}
 	if ($RS_LOGFLS eq '') {
 		$RS_LOG_NAME = "$LOGFLS_DIR/RSync-Log_"."$RS_ACTUALDT"; }
 	else {
 		$RS_LOG_NAME = "$LOGFLS_DIR/$RS_LOGFLS";
 	}
#
	if ($RS_LOGFLS eq 'e') {
		system("rsync @RestOfOptions $RS_CORE_OPT \'$RS_SOURCE\' \'$RS_BACKUP\'");
	}
	else {
		system("rsync @RestOfOptions $RS_CORE_OPT \'$RS_SOURCE\' \'$RS_BACKUP\' | tee $RS_LOG_NAME");
	}
#
#
#	print "RS_CORE_OPT --> $RS_CORE_OPT\n";
	print "\nBackup --> $RS_SOURCE\n";
	print "Source --> $RS_BACKUP\n";
	print "Rest   --> @RestOfOptions\n";
#
#
# 
# END ;-)
# -------
	print "Done.\n";
#
#
#---------------------------------------------------------------------#
#
#
# Warnings and Errors
# --------------------
sub RSWarning {
	my($WarningText) = @_;	
	print "WARNING: $WarningText\n";
}
#
sub RSErrorAndExit {
	my($ErrorText) = @_;	
	print "ERROR: $ErrorText\n";
	print "Exiting the script...\n";
	exit(0);
}
#
#
# Help Messaage
# -------------
#
sub RSHelp {
$HelpMsg=<<_BOT_;

  Perl script 'RCzBackup'
  -----------------------
  This is a simple, Perl script for doing a wrapper for famous and excellent 'rsync'...
 
  
  USAGE
    RCzRS [<Options>] -s <Source> -d <Destination>


  ARGUMENTS
    -s <Source>
      What is used as source, what are the data to backup (good to add '/' at the end -- avoid extra folder on dest.

    -d <Destination>
      Where to copy the backup

    [<Options>]  : Option listed below


  OPTIONS
    -e <Exclude-from-file>
      What patterns or files to be excluded

    -h, --help
      Print this help message.

    -l [<Log file name>]
      Log file name, by default it's 'RSync-Log_<ActualDate>' or name given as optional argument.
    -l e
      Do not create log file.

    -n
      Run a "dryrun", just for test.

    -v
      Extra-verbose, that is "-vv" from 'rsync'

    -x
      Delete excluded files from destination


  REMARKS


  2011/01/12, v0.40
  (c) 2010-2011 by Rafal Czarny

_BOT_
	print $HelpMsg;
}
#
#
#---------------------------------------------------------------------#
#=====================================================================#
#
# 2011/01/12, v0.40
# (c) 2010-2011 by Rafal Czarny
