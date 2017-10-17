#!/usr/bin/perl
#=====================================================================#
#                               SecCopy
#                       ----------------------
#  Date       : 2011/02/14, v0.80
#  Copyright  : (c) 2009-2011 by Rafal Czarny
#  Email      : rafal.czarny@oracle.com
#---------------------------------------------------------------------#
#
#  This is a script for doing a quick copy via 'scp' between 
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
# --------------------------
#
	$ISONSUNRA  = 0;  # Are we on SunRay server???
	$ISONCORES  = 0;  # Are we on cores2 ???  ## TO BE CHANGED on CORES2 !!!
#
# This is used mainly to create switches and other global variables
	$USE_HELP   = 0;  # Should we print a quick 'help' messages?
	$USE_HOME   = 0;  # Table for source directories
	$JUSTCOPY   = 1;  # Just copy of all files
	$COPYALL    = 0;  # Do we copy all of the files
# Syncing and clearing all files
	$SYNCALL    = 0;  # Sync all folders in ~/Cases to Cores2
	$CLEARALL   = 0;  # Clear all folders from the files *~ and 'atr-*'
	$ARCHIVEALL = 0;  # Archive cases that are listed in 'Cases.txt' for active in ISP (was in 'Thunderbird'...)
#
	@SOURCE    = ();  # Table for source directories
	$DESTIN    = '';  # Backup folder
	@RestOfOptions = ();
#
# 
	$MYLOGIN  = 'rc208050';
	$CORESHOS = 'cores2-da-sparc-2-a.central.sun.com';
	$CORESDIR = 'cores';
#
	$SWANHOME = 'snuka.germany.sun.com:/export/home1/04/rc208050';
	$SUNRAYHO = 'hs-emeabpo-01.eu-spn.sun.com:/export/home1/03/rc208050';
	if ($ISONSUNRA) {
		$HOMEDIRE = '/home/rc208050'; }
	else {
		$HOMEDIRE = '/home'; }
	$SUNRAYCO = 'Cases';
	$SUNRAYAR = 'Cases/Archives';
	$HOMETEMP = 'Incoming';
#
	$ARCHFILE = '';  # File that contains the cases numbers to be archived (each case in first column in separate line
	@TAB_ALLC = ();  # All cases from 'Cases' folder on $HOME...
	@TAB_ACTV = ();  # All cases given in 'Cases.txt' for active in ISP (was in 'Thunderbird'...)
	@TAB_COMM = ();  # The intersection of the above arrays
	@TAB_ARCH = ();  # The rest cases from 'Cases' of $HOME that would be archived

# 
#
# The core of the script
# -----------------------
#
# Read and proceed all defined options, all these options will be removed from the @ARGV table
        GetOptions("a"   => \$COPYALL,
                   "c"   => sub { $JUSTCOPY = 0; $COPYALL = 1; $SYNCALL = 0; $CLEARALL = 1; $ARCHIVEALL = 0; },
                   "h"   => \$USE_HELP,
                   "l"   => \$USE_HOME,
                   "s"   => sub { $JUSTCOPY = 0; $COPYALL = 1; $SYNCALL = 1; $CLEARALL = 0; $ARCHIVEALL = 0; },
                   "w:s" => sub { $JUSTCOPY = 0; $COPYALL = 1; $SYNCALL = 1; $CLEARALL = 1; $ARCHIVEALL = 1; $ARCHFILE = $_[1]; },
                   "x:s" => sub { $JUSTCOPY = 0; $COPYALL = 1; $SYNCALL = 0; $CLEARALL = 1; $ARCHIVEALL = 1; $ARCHFILE = $_[1]; }
                  );
#
# If the -h option is used, then we will print small help and quit the script
	if ($USE_HELP) {
		CCPHelp();	exit(0);
	}
#
# 
# Checking all parameters from @ARGV
# -----------------------------------
	$CURRENT_DIR = `pwd`;
	chomp($CURRENT_DIR);
#
# 
	$DESTIN = CCPSearchForCaseNo();
#
	foreach $arg (@ARGV) {
		if (($arg =~ m/^-\w{1}$/) || ($arg =~ m/^--\w+$/)) {
			push(@RestOfOptions,$arg);
		}
		if (($arg =~ m/^\d{1}-\d{10}$/) || ($arg =~ m/^\d{1}-\d{7}$/)) {
			$DESTIN = $arg;
		}
		if ((-e $arg) && (-f $arg)) {
			push(@SOURCE,$arg);
		}
		if ((-e $arg) && (-d $arg)) {
			push(@SOURCE,$arg);
			push(@RestOfOptions,'-r');
		}
	}
#
# 
	if ($COPYALL) {
		@SOURCE = ('*');
		push(@RestOfOptions,'-r');
	}
#
##	print "RestOfOptions --> @RestOfOptions\n";
##	print "       SOURCE --> @SOURCE\n";
##	print "       DESTIN --> $DESTIN\n";
#
# 
# Additional checking of the parameters
# --------------------------------------
	if ($#SOURCE < 0) {
		ErrorAndExit("The file/folder $SOURCE didn't provide!");
	}
	if ($DESTIN eq '') {
		Warning("Copy to the HOME directory.");
		$USE_HOME = 1;
	}
	if ($ARCHIVEALL) {
		if ($ARCHFILE eq '') { $ARCHFILE = "$HOMEDIRE/$SUNRAYCO/Cases.txt"; }
		if (!-e $ARCHFILE) {
			ErrorAndExit("The file: $ARCHFILE doesn't exist!");
		}
	}
#
#
# 
# Main core -- Copy operations Cores2 <--> SunRay
# ------------------------------------------------
if ($JUSTCOPY) {
	if ($ISONCORES) {## *** Copy: SWAN/Cores2 --> SunRay ***
		if ($USE_HOME) {
##			print ("[change] Copy local: SWAN/Cores2 --> SunRay");
			system("scp @RestOfOptions @SOURCE $MYLOGIN\@$SUNRAYHO/$HOMETEMP");
		}
		else {
##			print ("[change] Copy case: SWAN/Cores2 --> SunRay");
			system("scp @RestOfOptions @SOURCE $MYLOGIN\@$SUNRAYHO/$SUNRAYCO/$DESTIN");
		}
	} else {#        ## *** Copy: SunRay --> SWAN/Cores2 ***
		if ($USE_HOME) {
##			print ("[change] Copy local: SunRay --> SWAN/Cores2");
			system("scp @RestOfOptions @SOURCE $MYLOGIN\@$SWANHOME/$HOMETEMP");
		}
		else {
##			print ("[change] Copy case: SunRay --> SWAN/Cores2");
			system("scp @RestOfOptions @SOURCE $MYLOGIN\@$CORESHOS:/$CORESDIR/$DESTIN");
		}
	}
}
#
# 
# Main core -- Operation on directories
# --------------------------------------
if (!$JUSTCOPY && !$ISONCORES) {
#
# Building the arrays
	chdir("$HOMEDIRE/$SUNRAYCO");
	($FILES_Temp_Ref,$DIRS_Temp_Ref) = CCPGetDirCont("$HOMEDIRE/$SUNRAYCO");
	@DIRS_All_Temp = @$DIRS_Temp_Ref;
	foreach $DirTmp (@DIRS_All_Temp) {
		if (($DirTmp =~ /^\d{1}-\d{7}$/) || ($DirTmp =~ /^\d{1}-\d{10}$/)) {
			push(@TAB_ALLC,$DirTmp);
		}
	}
	@TAB_ALLC_Save = @TAB_ALLC;
	@TAB_ALLC = sort @TAB_ALLC_Save;
	@TAB_ACTV = CCPGivenActiveCases();
# 	
	%TAB_TempCount = ();
	@TAB_TempARCH = ();
# Searching for intersection array from 'Cases' and ISP cases (@TAB_COMM) and XOR array (@TAB_TempARCH):
	foreach $DirTmp (@TAB_ALLC, @TAB_ACTV) { $TAB_TempCount{$DirTmp}++; }
	foreach $DirTmp (keys %TAB_TempCount) {
		push(@{ $TAB_TempCount{$DirTmp} > 1 ? \@TAB_COMM : \@TAB_TempARCH }, $DirTmp);
	}
# Again, we will search for intersection of XOR array (@TAB_TempARCH) with all cases from 'Cases', gives as 'Archived' folders
	%TAB_TempCount = ();
	foreach $DirTmp (@TAB_ALLC, @TAB_TempARCH) { $TAB_TempCount{$DirTmp}++; }
	foreach $DirTmp (keys %TAB_TempCount) {
		push(@{ $TAB_TempCount{$DirTmp} > 1 ? \@TAB_ARCH : \@TAB_ALLC_Save }, $DirTmp);
	}
	@TAB_ALLC_Save = ();
# 
	if ($CLEARALL) {
		CCPClearAllFolders(@TAB_ALLC);
	}
	if ($ARCHIVEALL) {
		CCPArchiveAllFolders(@TAB_ARCH);
	}
	if ($SYNCALL) {
		if ($ARCHIVEALL) {
			CCPSyncAllFolders(@TAB_COMM); }
		else {
			CCPSyncAllFolders(@TAB_ALLC); }
	}
#
#
# Some tests
#	print "\n";
#	print "TAB_ALLC -->  @TAB_ALLC\n";
#	print "TAB_ACTV -->  @TAB_ACTV\n";
#	print "TAB_COMM -->  @TAB_COMM\n";
#	print "TAB_ARCH -->  @TAB_ARCH\n";
#
	chdir("$CURRENT_DIR");
}
#
#
#
#---------------------------------------------------------------------#
#
#
# Warnings and Errors
# --------------------
sub Warning {
	my($WarningText) = @_;	
	print "WARNING: $WarningText\n";
}
#
sub ErrorAndExit {
	my($ErrorText) = @_;	
	print "ERROR: $ErrorText\n";
	print "Exiting the script...\n";
	exit(0);
}
#
#
# Searching for the case no
# --------------------------
sub CCPSearchForCaseNo {
	my @CurrentDirLevels = split(/\//,$CURRENT_DIR);
	my @CurrentDirLevelsNew = ();
	my $CDLi = -1;
	my $CaseNoIndex = -1;
	my $CaseNoFound = 0;
	my $RET_CASE_NO = 0;
	foreach $Level (@CurrentDirLevels) {
		$CDLi++;
		if ((($Level =~ m/^\d{8}$/) || ($Level =~ m/^\d{1}-\d{10}$/)) && ($CaseNoFound == 0)) {
			$CaseNoIndex = $CDLi; $CaseNoFound = 1; }
	}
	if ($CaseNoFound) {
		$RET_CASE_NO = $CurrentDirLevels[$CaseNoIndex]; # case number for further ref.
	}
	return $RET_CASE_NO;
}
#
#
# Getting the directory contents
# -------------------------------
sub CCPGetDirCont {
	my($LocFOLDER) = @_; # $LocFOLDER: Name of the folder
	my @LocFilesTab = ();
	my @LocFilesRet = ();
	my @LocDiresRet = ();
	my $LocEl = '';
	opendir(LocDIR,"$LocFOLDER") || die "Can't open $LocFOLDER directory.\n";
	@LocFilesTab = readdir(LocDIR);
	closedir(LocDIR);
	foreach $LocEl (@LocFilesTab) {
		if ($LocEl !~ /^\.+$/) {
			if (-f $LocEl) {
				push(@LocFilesRet,$LocEl); }
			if (-d $LocEl) {
				push(@LocDiresRet,$LocEl); }
		}
	}
	return (\@LocFilesRet,\@LocDiresRet);
}
#
#
# Retrieve all cases from the file name given
# --------------------------------------------
sub CCPGivenActiveCases {
	my @ActiveCases = ();
	my @ActiveCasesTmp = ();
#
	open(ACT_CASES,"$ARCHFILE");
	while ($LocLine = <ACT_CASES>) {
		if ($LocLine =~ /\d{1}-\d{7,10}/) {
	  		push(@ActiveCases,$&);
		}
	}
	@ActiveCasesTmp = @ActiveCases;
	@ActiveCases = sort @ActiveCasesTmp;
	close(ACT_CASES);
	return @ActiveCases;
}
#
#
# Clear all folders
# ------------------
sub CCPClearAllFolders {
	my(@DIRS_List_Loc) = @_;
	foreach $DirTmp (@DIRS_List_Loc) {
		chdir("$HOMEDIRE/$SUNRAYCO/$DirTmp");
		print("Clearing the SR# $DirTmp... ");
		system("rm *~ 2> /dev/null");
		system("rm atr-* 2> /dev/null");
		print("Done.\n");
	}
	chdir("$CURRENT_DIR");
}
#
#
# Syncing all folders
# --------------------
sub CCPSyncAllFolders {
	my(@DIRS_List_Loc) = @_;
	foreach $DirTmp (@DIRS_List_Loc) {
		chdir("$HOMEDIRE/$SUNRAYCO/$DirTmp");
		print("Synching the SR# $DirTmp... ");
##		print ("[change] Copy case: SunRay --> SWAN/Cores2");
		system("scp @RestOfOptions @SOURCE $MYLOGIN\@$CORESHOS:/$CORESDIR/$DirTmp");
		print("Done.\n");
	}
	chdir("$CURRENT_DIR");
}
#
#
# Archiving given folders
# ------------------------
sub CCPArchiveAllFolders {
	my(@DIRS_ArchList_Loc) = @_;
	foreach $DirTmp (@DIRS_ArchList_Loc) {
		print("Archiving the SR# $DirTmp... ");
		system("mv -f $DirTmp $HOMEDIRE/$SUNRAYAR/");
		print("Done.\n");
	}
}
#
#
# Help Messaage
# -------------
#
sub CCPHelp {
$HelpMsg=<<_BOT_;

  Perl script 'SecCopy' aka 'ccp'
  --------------------------------
  Script for 'scp' that will copy the given files to the Cores2 server.

 
   USAGE
     ccp [<Rest_of_Options_for_scp>] <Source> [<Case_ref._on_Cores2>] [<Options>]

   or
     ccp -c|-s|-w [<ISP_Cases.txt>]|-x [<ISP_Cases.txt>]

   [<Options>] :  see below
   <Case_ref._on_Cores2> :  optional, if no given, this will be searched from the active directory.

             
   OPTIONS
     -a
       Copy all contents (so use '*' and set '-r' option).

     -c
       Clear only all cases' folders from the files '*~', 'atr-*'

     -h
       Print this help message.

     -l
       Copy to Local folder.

     -s
       Only sync all folders. Not recommended as it may copy to already closed cases on Cores2.

     -w [<ISP_Cases.txt>]
       Clear, Archive and Synchronize active an not archived folders.

     -x [<ISP_Cases.txt>]
       Clear and Archive all folders with no Cores2 synchronization.

     <ISP_Cases.txt> :  File name used with 'Archive' option.
                        Text file that contains list of the active cases on ISP. Each case no. needs to be in separate line,
                        possibly on a being of the line, other text can be give after white spaces.
                        If no name is given then it assumes by default 'Cases.txt'.


  REMARKS

  2011/02/14, v0.80
  (c) 2009-2011 by Rafal Czarny

_BOT_
	print $HelpMsg;
}
#
#
#---------------------------------------------------------------------#
#=====================================================================#
#
# 2011/02/14, v0.80
# (c) 2009-2011 by Rafal Czarny
