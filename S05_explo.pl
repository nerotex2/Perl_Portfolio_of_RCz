#!/usr/bin/perl
#=====================================================================#
#                               explo
#                       ----------------------
#  date       : 2010/03/30, v0.90
#  copyright  : (c) 2009-2010 by Rafal Czarny
#  email      : Rafal.Czarny@sun.com
#---------------------------------------------------------------------#
#
#  This is a very simple, Perl script that will unzip/untar the file given,
#  change permissions for files and sub-directories...
#  ...and finally it will run some extras.
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
# This is used mainly to create switches and other global variables
	$USE_HELP  = 0;  # should we print a quick 'help' messages?
	$EMPTYARGS = 0;  # it will be "1" if there is no email numbers are given at all
	$FILEorDIR = -1; # do we handle: file -> 0, directory -> 1
	$FILESPERM = 0;  # 0 -> '644', 1 -> '666' (-r), 2 -> '755' (-s), 3 -> '777 (-t)'
	$DIRESPERM = 0;  # 0 -> '777', 1 -> '755' (-x), 
	$PERMonDIR = 0;  # if we change only the permission on the directory
	$PROACTIVE = 1;  # if we want to copy the Explorer to ProActive folder
#
	$EXPLO_Dir = '';  # Name of the Main Explorer directory
	$EXPLO_TGz = '';  # Name of the Main Explorer .tar.gz file
	$ProActiveDir = '/net/ace1104.uk/spool/incoming';
# 
#
# Options and help
# ----------------
#
# Read and proceed all defined options
	GetOptions("h"  => \$USE_HELP,
             "n"  => sub { $PROACTIVE = 0 },
             "p"  => \$PERMonDIR,
             "r"  => sub { $FILESPERM = 1 },
             "s"  => sub { $FILESPERM = 2 },
             "t"  => sub { $FILESPERM = 3 },
             "x"  => sub { $DIRESPERM = 1 }
						);
#
# If the -h option is used, then we will print small help and quit the script
	if ($USE_HELP) {
		ExploHelp();	exit(0);
	}

#
# 
# Pre-checks
# ----------
#
# Current Dir
	$CURRENT_DIR = `pwd`; chomp($CURRENT_DIR);
#
# Handling Input data
	if ($#ARGV >= 0) {
		$EXPLO_Input = $ARGV[0]; }  # input data
	else {
		$EXPLO_Input = '';
	}
	if ((!-e $EXPLO_Input) || ($EXPLO_Input eq '')) {
		ExploErrorAndExit("File/Dir $EXPLO_Input doesn't exist or no argument given!");
	}
	if ((-e $EXPLO_Input) && (-f $EXPLO_Input)) {
		$EXPLO_TGz = $EXPLO_Input;
		$FILEorDIR = 0;
	}
	if ((-e $EXPLO_Input) && (-d $EXPLO_Input)) {
		$EXPLO_Dir = $EXPLO_Input;
		$FILEorDIR = 1;
	}
#
# Settings the global Files/Dirs permissions to be set
	if ($FILESPERM == 0) {
		$PERM_GlFiles = 0644; }
	else {
		if ($FILESPERM == 1) {
			$PERM_GlFiles = 0666; }
		if ($FILESPERM == 2) {
			$PERM_GlFiles = 0755; }
		if ($FILESPERM == 3) {
			$PERM_GlFiles = 0777; }
	}
#
	if ($DIRESPERM == 0) {
		$PERM_GlDires = 0777; }
	else {
		if ($DIRESPERM == 1) {
			$PERM_GlDires = 0755; }
	}
#
#
# Now the core of the script
# --------------------------
#
# Unzipping first
	print "\n";
	if ($FILEorDIR == 0) {
		($FILES_Ref,$DIRS_Before_Ref) = ExploGetDirCont("$CURRENT_DIR");
		@DIRS_Before = @$DIRS_Before_Ref;
#
		print "[1]: Uncompressing...\n";
	#	system("gzcat $EXPLO_TGz | tar xf -");  # <--- SOLARIS version!!!
		system("gunzip -c $EXPLO_TGz | tar xf -");
		print "[1]: Uncompressing done.\n";
#
# If it was a file given then we need to find out what is the unpacked dir name
		($FILES_Ref,$DIRS_After_Ref) = ExploGetDirCont("$CURRENT_DIR");
		@DIRS_After = @$DIRS_After_Ref;
		%DIRS_Before = map {$_, 1} @DIRS_Before;
		@DIRS_Diff = grep {!@DIRS_Before {$_}} @DIRS_After;
#
# Finding the Explorer file name
		$EXPLO_Dir_j = -1;
		for($i=0; $i<=$#DIRS_Diff; $i++) {
			if ($DIRS_Diff[$i] =~ /.*explorer.*/) {
				$EXPLO_Dir = $DIRS_Diff[$i];
				$EXPLO_Dir_j = $i;
			}
		}
		splice(@DIRS_Diff,$EXPLO_Dir_j,1);
#
# moving the orphants directories to the main folder
		if ($#DIRS_Diff >= 0) {
			foreach $dir (@DIRS_Diff) {
				system("mv \"$dir\" \"$EXPLO_Dir/2-$dir\"");
			}
		}
	}
#
# Running permissions changes on this directory
	$EXPLO_Dir =~ s/\/$//g;
	print "[2]: Permissions changes...\n";
	chmod($PERM_GlDires,"$CURRENT_DIR/$EXPLO_Dir");
	ExploPermissionsRuns("$CURRENT_DIR/$EXPLO_Dir");
	print "[2]: Permissions changes done.\n";
#
# Running "extra stuffs" on the Explorer directory
	if ($PERMonDIR == 0) {
		print "[3]: Running extras...\n";
		ExploExtraRuns("$CURRENT_DIR/$EXPLO_Dir");
		print "[3]: Running extras done.\n";
	}
#
# Copying the Explorer .tar.gz file to the "ProActive" folder
	if ($PROACTIVE && !$FILEorDIR && !$PERMonDIR) {
		print "[4]: Copying the Explorer to ProActive...\n";
		system("mv $EXPLO_TGz $EXPLO_Dir.tar.gz");
		system("cp $EXPLO_Dir.tar.gz /home/Temp/ProActive");
		chmod(0666,"/home/Temp/ProActive/$EXPLO_Dir.tar.gz");
#		system("cp $EXPLO_Dir.tar.gz $ProActiveDir");  # <--- SOLARIS version!!!
#		system("chmod 666 $ProActiveDir/$EXPLO_Dir.tar.gz"); # <--- SOLARIS version!!!
		system("rm $EXPLO_Dir.tar.gz");
		print "[4]: Copying the Explorer to ProActive done.	\n";
	}
#
#
#=====================================================================#
#
#
# Warnings and Errors
# --------------------
sub ExploWarning {
	my($WarningText) = @_;	
	print "WARNING: $WarningText\n";
}
#
sub ExploErrorAndExit {
	my($ErrorText) = @_;	
	print "ERROR: $ErrorText\n";
	print "Exiting the script...\n";
	exit(0);
}
#
#
# Getting the directory contents
# ------------------------------
sub ExploGetDirCont {
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
# Extra "stuff" to be run on Explorer folder
# ------------------------------------------
sub ExploExtraRuns {
	my($LocEXPLO) = @_;  # $LocEXPLO needs to be a Explorer dir...
	chdir("$LocEXPLO");
#
# create ExploMiner folder (if it doesn't exist)
	if (!-e "$LocEXPLO/ExploMiner") {
		system("mkdir $LocEXPLO/ExploMiner");
		chmod($PERM_GlDires,"$LocEXPLO/ExploMiner");
#		system("chmod 777 $CURRENT_DIR/$entry/ExploMiner");
	}
#
# creating the symb link to the 'disks/iostat-En.out'
	if ((-e "$LocEXPLO/sysconfig/iostat-En.out") && (-e "$LocEXPLO/disks/")) {
		if (!-e "$LocEXPLO/disks/iostat-En.out") {
			system("ln -s ../sysconfig/iostat-En.out disks/iostat-En.out");
		}
	}
#
# creating the symb link to the 'netinfo/ifconfig-a.out'
	if ((-e "$LocEXPLO/sysconfig/ifconfig-a.out") && (-e "$LocEXPLO/netinfo/")) {
		if (!-e "$LocEXPLO/netinfo/ifconfig-a.out") {
			system("ln -s ../sysconfig/ifconfig-a.out netinfo/ifconfig-a.out");
		}
	}
	chdir("$CURRENT_DIR");
#
# E x p e r i m e n t a l !
# running the script "ExploSum in the directory on the Explorer --- 
	my $Which_ExploSum = `which explosum 2> /dev/null`; chomp($Which_ExploSum);
	my @Which_ExploSum_Tab = split(//,$Which_ExploSum);
	if ($Which_ExploSum_Tab[0] eq '/') {
		print "     -- Running \"ExploSum\" script...\n";
		system("explosum $LocEXPLO $LocEXPLO > /dev/null");
	}
}
#
#
# 
# -------------
sub ExploPermissionsRuns {
	my($LocEXPLO) = @_;  # $LocEXPLO needs to be a Explorer dir...
#	
	my @BFSFIFO = ();
	my %BFSVSTD = ();
	my @FOLDERS = ();
	my $node = '';  my $CurrDir = '';  my @CurrDirTab = ();  my $i = '';
	my $FilesTmp_Ref = '';  my $DirsTmp_Ref = '';  my @FileNeigh = ();  my @NodeNeigh = ();
#
	push(@BFSFIFO,".");
	$BFSVSTD{"."} = 0;
	while ($#BFSFIFO >= 0) {
		$node = splice(@BFSFIFO,0,1);
		chdir("$LocEXPLO/$node/");
#
# Changing the permissions
		($FilesTmp_Ref,$DirsTmp_Ref) = ExploGetDirCont("$LocEXPLO/$node/");
		@FileNeigh = @$FilesTmp_Ref;
		@NodeNeigh = @$DirsTmp_Ref;
		chmod($PERM_GlFiles,@FileNeigh);
		chmod($PERM_GlDires,@NodeNeigh);
#
		$CurrDir = `pwd`;	chomp($CurrDir);
		@CurrDirTab = split(/$LocEXPLO\//,$CurrDir);
		if ($#CurrDirTab == 1) {
			push(@FOLDERS,$CurrDirTab[1]);
		} else {
			push(@FOLDERS,".");
		}
		$CurrDir = $FOLDERS[$#FOLDERS];
#
		foreach $i (@NodeNeigh) {
			$BFSVSTD{"$CurrDir/$i"} = 1;
		}
		foreach $i (@NodeNeigh) {
			if ($BFSVSTD{"$CurrDir/$i"}) {
				push(@BFSFIFO,"$CurrDir/$i");	$BFSVSTD{"$CurrDir/$i"} = 0;
			}
		}
	}
	chdir("$CURRENT_DIR");
##	splice(@FOLDERS,0,1);
}
#
#
# Help Messaage
# -------------
sub ExploHelp {
$HelpMsg=<<_BOT_;

  Perl script 'explo'
  -------------------
  This is a very simple, Perl script that will unzip/untar the file given,
  change permissions for files and sub-directories and finally it will run some extras.

  USAGE
    explo <Explorer_file> [<Explorer_folder>] [<Options>]

  ARGUMENTS
    <Snapshot_folder> : Snapshot folder (or multiple folders can be given).
    [<Options>] : see OPTIONS.

  OPTIONS
    -h
      Print this help message.

    -n
      Do not copy Explorer *.tar.gz file to the ProActive folder
 
    -p
      Run only permissions on the folder given, without "extras".

    -r
      Set all files with permissions == 0666.

    -s
      Set all files with permissions == 0755.

    -t
      Set all files with permissions == 0777.

    -x
      Set all directories with permissions == 0755.

  REMARKS
    - Any comments, bugs - please send them on the email: Rafal.Czarny\@sun.com
      Many thanks! :-)

  ------------------------
  2010/03/30, v0.90
  (c) 2009-2010 by Rafal Czarny
_BOT_
	print $HelpMsg;
}
#
#=====================================================================#
#
# (c) 2009-2010 by Rafal Czarny