#!/usr/bin/perl
#=====================================================================#
#                              RCzBackup
#                       ----------------------
#  Date       : 2009/11/07, v0.30
#  Copyright  : (c) 2009 by Rafal Czarny
#  Email      : Rafal.Czarny@sun.com
#---------------------------------------------------------------------#
#
#  This is a script for creating the "general" backup of the folder given
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
# This is used mainly to create switches and other global variables
	$USE_HELP    = 0;  # should we print a quick 'help' messages?
	$EMPTYARGS   = 0;  # it will be "1" if there is no email numbers are given at all
#
	$BKSOURCEF   = ''; # Table for source directories
	$BKTEMPF     = ''; # Temp folder, where we copy all files
	$BKBACKUPF   = ''; # Backup folder
	$BKFILENAME  = ''; # Filename for the removal/replacement operations
	$BKNAMEBAC   = ''; # Name of the Backup, to add into Filename
# 
#
# The core of the script
# -----------------------
#
# Read and proceed all defined options, all these options will be removed from the @ARGV table
	GetOptions("b=s" => \$BKBACKUPF,
             "f=s" => \$BKFILENAME,
             "h"   => \$USE_HELP,
             "n=s" => \$BKNAMEBAC,
             "s=s" => \$BKSOURCEF,
             "t=s" => \$BKTEMPF,
						);
#
#
# If the -h option is used, then we will print small help and quit the script
	if ($USE_HELP) {
		BKHelp();	exit(0);
	}
#
# 
# Addtional variables and tables used
# -----------------------------------
	
	@BKSOURCETab = ();
	$BKEMPTYFILE = '/home/Temp/empty.txt';     # Empty file with "644" permissions  # <-- TBC on Solaris!!!
	$BKEMPTYRWFILE = '/home/Temp/emptyrw.txt'; # Empty file with "600" permissions  # <-- TBC on Solaris!!!
#
	$BKBACKUPFMAX_DIRS = 3;
	$BKACTUALDATE = `date '+20%y-%m-%d'`;
	$BKACTUALDATETIME = `date '+20%y-%m-%d_T%H-%M'`;
	chomp($BKACTUALDATE);
	chomp($BKACTUALDATETIME);
#
	$BKSOURCEF_N = 0;
	$BKBAC_ARCHN = $BKNAMEBAC."_".$BKACTUALDATETIME;  # Name of the archive *.tar.gz file
	$BKBAC_ARCHF = $BKNAMEBAC."_".$BKACTUALDATETIME;  # Relative path to the archive folder in TEMPF
	$BKBAC_TEMPF = "$BKTEMPF/$BKBAC_ARCHF";   # Full path to the archive folder in TEMPF
	$BKBAC_BACKF = "$BKBACKUPF/$BKACTUALDATETIME"; # Full path to the archive folder in BACKUPF
#
# 
# First verifications
# -------------------
	@BKSOURCETab = split(/\|/,$BKSOURCEF);
	$BKSOURCEF_N = $#BKSOURCETab+1;
#
	foreach $dir (@BKSOURCETab) {
		if (!-e $dir) {
			BKErrorAndExit("The directory: $dir doesn't exist!");
		}
	}
	if (!-e $BKTEMPF) {
		BKWarning("The folder $BKTEMPF doesn't exit and it will be created");
		system("mkdir $BKTEMPF");
	}
	if (!-e $BKBACKUPF) {
		BKWarning("The folder $BKBACKUPF doesn't exit and it will be created");
		system("mkdir $BKBACKUPF");
	}

	if ($BKNAMEBAC eq '')	{
		BKErrorAndExit("The backup name has not been provided!");
	}
#
# 
# [1]: Copying the files to the TEMPF
# -----------------------------------
	print "[1]: Copying the files to the temp location...\n";
	system("mkdir $BKBAC_TEMPF");
	if ($BKSOURCEF_N > 1) {
		BKWarning("Multiple source directories used. Please add last dir from each source into mod file.");
		foreach $dir (@BKSOURCETab) {	
			$BKSourceLastF = BKReturnSingleFolder($dir,'l');
			system("mkdir \"$BKBAC_TEMPF/$BKSourceLastF\"");
			system("cp -R \"$dir\"/* \"$BKBAC_TEMPF/$BKSourceLastF\"/");
		}
	}
	else {
		system("cp -R \"$BKSOURCETab[0]\"/* $BKBAC_TEMPF/");
	}
#
# 
# [2]: Modification of the files in the TEMPF
# -------------------------------------------
	print "[2]: Modification of the files in the temp location...\n";	
	chdir("$BKBAC_TEMPF");
	if (-e $BKFILENAME && -T $BKFILENAME)	{
		open(MODIFICATIONS,$BKFILENAME);
		while ($ModLine = <MODIFICATIONS>) {
			chomp($ModLine);
			if ($ModLine !~ /^#.*$/) {
				@ModLineTab = split(/::____/,$ModLine);
				$Modifier = $ModLineTab[0];
				$NameToBeMod = $ModLineTab[1];
				if (-e $NameToBeMod) {
					if ($Modifier eq 'C') { # Directory to be removed and created again
						$PermStat = (stat($NameToBeMod))[2];
						$PermSave = sprintf("%04o", $PermStat & 07777);
						system("rm -Rf \"$NameToBeMod\"");
						system("mkdir \"$NameToBeMod\"");
						system("chmod $PermSave \"$NameToBeMod\"");
						print "- [2]: Directory: $NameToBeMod removed and created back - OK.\n";
					}
					if ($Modifier eq 'D') { # Directory to be removed
						system("rm -Rf \"$NameToBeMod\"");
						print "- [2]: Directory: $NameToBeMod removed - OK.\n";
					}
					if ($Modifier eq 'R') { # File to be removed
						system("rm -f \"$NameToBeMod\"");
						print "- [2]: File: $NameToBeMod removed - OK.\n";
					}
					if ($Modifier eq 'E') { # File to be replaced by the empty file with "644" perm.
						system("cp -p $BKEMPTYFILE \"$NameToBeMod\"");
						print "- [2]: File: $NameToBeMod replaced with perm: -rw-r--r-- - OK.\n";
					}
					if ($Modifier eq 'W') { # File to be replaced by the empty file with "600" perm.
						system("cp -p $BKEMPTYRWFILE \"$NameToBeMod\"");
						print "- [2]: File: $NameToBeMod replaced with perm: -rw------- - OK.\n";
					}
				}
				else {
					BKWarning("Directory/File: $NameToBeMod doesn't exist");
				}
			}
		}
		close(MODIFICATIONS);
	}
	else {
		BKWarning("File for modifications: $BKFILENAME doesn't exist.");
	}

#
# 
# [3]: Creating and moving the archive 
# ---------------------------------------
	print "[3]: Creating and moving the archive...\n";	
	chdir("$BKTEMPF");
	system("tar cvf $BKBAC_ARCHN.tar $BKBAC_ARCHF/");
	system("gzip $BKBAC_ARCHN.tar");
#
	if (!-e $BKBAC_BACKF) {
		system("mkdir $BKBAC_BACKF");
	}
	system("mv $BKBAC_ARCHN.tar.gz $BKBAC_BACKF/");
#
# 
# [4]: Removing the the TEMPF folder
# ----------------------------------
	print "[4]: Removing the the temp location...\n";	
	system("rm -Rf $BKBAC_ARCHF/");
#
# 
# [5]: Cleaning the BACKUPF, to have only MAX_DIRS
# ------------------------------------------------
	print "[5]: Cleaning the backup folder, to have only $BKBACKUPFMAX_DIRS folders...\n";	
	chdir("$BKBACKUPF");
	$BKBACKUPF_DIRsTmp = `ls`;
	@BKBACKUPF_DIRs = split(/\s+/,$BKBACKUPF_DIRsTmp);
	if ($#BKBACKUPF_DIRs > $BKBACKUPFMAX_DIRS-1) {
		for ($i=0; $i<=$#BKBACKUPF_DIRs-$BKBACKUPFMAX_DIRS; $i++) {
			system("rm -Rf $BKBACKUPF_DIRs[$i]/");
		}
	}
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
sub BKWarning {
	my($WarningText) = @_;	
	print "WARNING: $WarningText\n";
}
#
sub BKErrorAndExit {
	my($ErrorText) = @_;	
	print "ERROR: $ErrorText\n";
	print "Exiting the script...\n";
	exit(0);
}
#
#
# Retrieve the folder name
# ------------------------
sub BKReturnSingleFolder {
	my($FullFolder,$Number) = @_;  # if ($Number eq 'l') --> this is the last
	my @CurrentDirLevels = split(/\//,$FullFolder);
	if ($Number =~ /\d/) {
		return $CurrentDirLevels[$Number];
	} else {
		if ($Number eq 'l') {
			return $CurrentDirLevels[$#CurrentDirLevels];
		}
	}
}
#
#
# Help Messaage
# -------------
#
sub BKHelp {
$HelpMsg=<<_BOT_;

  Perl script 'RCzBackup'
  -----------------------
  This is a simple, Perl script for generating Action Plans from the simple template file.
 
  
  USAGE
    RCzBackup -s <Source> -t <Temp> -b <Backup_Folder> -f [<File_with_changes>] -n <Name_of_backup>  [<Options>]

    Folder's names : Use full, absolute paths, add "" if the names contains spaces.
                     Multiple folders allowed using the syntax: "<Folder_1>|<Folder_2>|...|<Folder_n>"
    [<Options>] : no additional options created yet.

  ARGUMENTS
    -b <Backup_Folder>
      Where the backups are stored, main backup folder

    -f [<File_with_changes>]
      File with entries to be modifies, the following lines are allowed:
        #Comment...
        C::____<Directory to be removed and created (left as empty)>
        D::____<Directory to be removed>
        R::____<File to be removed>
        E::____<File to be replaced by the empty file with "644" perm.>
        W::____<File to be replaced by the empty file with "600" perm.>
 
    -n <Name_of_backup>
      What is the name of the archive

    -h, --help
      Print this help message.
             
    -s <Source>
      What needs to be backup-ed

    -t <Temp>
      Where the files will be copied, temp location

  OPTIONS


  REMARKS


  2009/11/07, v0.30
  (c) 2009 by Rafal Czarny

_BOT_
	print $HelpMsg;
}
#
#
#---------------------------------------------------------------------#
#=====================================================================#
#
# 2009/11/07, v0.30
# (c) 2009 by Rafal Czarny
