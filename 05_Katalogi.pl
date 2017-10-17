#!/usr/bin/perl
#======================================================================#
#                            Katalogi.pl
#                         --------------------
#   date        : 07/05/2007,  ver. 1.01
#   copyright   : (c) 2007 by Rafal Czarny
#   email       : rafal_czarny@tlen.pl
#----------------------------------------------------------------------#
#	 Script for executing some scripts in each directory given as an
#   argument of this script. 
#   
#
#======================================================================#

# Some variables for this script
# ------------------------------
	$SCRIPT = "";
	$FILE_Temp = 'RCz-Temp-Dir.out';
	$SCRIPT_True = 0;	
	
# Preliminaries
# --------------
	if( $#ARGV > 0 ) {	
		$SCRIPT_True = 1;	
		foreach (@ARGV)
	  	{ $SCRIPT .= "$_ "; }
	}
	else { $SCRIPT_True = 0;	}
	
#	Main script
# ------------
	$HOME_DIR_Main = `pwd`;
	chomp($HOME_DIR_Main);
	system("ls -lR > $FILE_Temp");
#	
	open(FILE_DIR,$FILE_Temp);
	DIR: while ($Line = <FILE_DIR>)
	{
		chomp($Line);
		if ($Line =~ m/^\..*:$/) { # this line is a directory
			$Curr_DIR_name = substr($Line,1,length($Line)-2); # name of the directory
			$Curr_DIR = $HOME_DIR_Main.$Curr_DIR_name; # full name of directory
			@Curr_FILES = ();  # actual files in this directory
			@Curr_SUBDIR = (); # actual subdirectories in this directory
			INDIR: while ($Line = <FILE_DIR>) {
				if ($Line =~ m/^$/) {	last; }
				else {
					# file
					if ((($Line =~ m/^-.*/) || ($Line =~ m/^l.*/)) && ($Line !~ m/^-.*$FILE_Temp/) ) {
						@TempSplitArray = split(/\s+/,$Line);
						if ($#TempSplitArray > 8) { # name file has spaces!
							$Curr_File = "";
							for ($i=8; $i<=$#TempSplitArray; $i++) {
								$Curr_File .= "$TempSplitArray[$i] "; }
							$Curr_File = substr($Curr_File,0,length($Curr_File)-1);
							push(@Curr_FILES,$Curr_File); }
						else {
							push(@Curr_FILES,$TempSplitArray[$#TempSplitArray]); }
						next INDIR;	
					}
					# directory
					if ($Line =~ m/^d.*/) {
						@TempSplitArray = split(/\s+/,$Line);
						if ($#TempSplitArray > 8) { # directory name has spaces!
							$Curr_D = "";
							for ($i=8; $i<=$#TempSplitArray; $i++) {
								$Curr_D .= "$TempSplitArray[$i] "; }
							$Curr_D = substr($Curr_D,0,length($Curr_D)-1);
							push(@Curr_SUBDIR,$Curr_D); }
						else {
							push(@Curr_SUBDIR,$TempSplitArray[$#TempSplitArray]); }
						next INDIR;	
					}
					# total line
					if (($Line =~ m/^razem.*/) || ($Line =~ m/^total.*/)) {
						next INDIR;	
					}
				}
			}
# we perform some operations
			chdir("$Curr_DIR");
			print "Current directory: $Curr_DIR\n";
			print "  --        Files: @Curr_FILES\n";
			print "  **  Directories: @Curr_SUBDIR\n\n"; 
			if ($SCRIPT_True) {
				system("$SCRIPT"); }
			else {
				chmod(0644, @Curr_FILES);
				chmod(0755, @Curr_SUBDIR);
			}
			chdir("$HOME_DIR_Main");
		}
	}
	close(FILE_DIR);
	chdir("$HOME_DIR_Main");
	system("rm -f $FILE_Temp");
	

# Chmod on files and subdir --> exists !!!
# ----------------------------------------
sub ChmodOnFiles 
{
	my (@DataFilesTable) = @_;
	my $CntTbl = scalar @DataFilesTable;
	if ($CntTbl > 0) {
		foreach (@DataFilesTable) {
			chmod(0644, $_); }
	}
}
sub ChmodOnSubdirs 
{
	my (@DataSubDirsTable) = @_;
	my $CntTbl = scalar @DataSubDirsTable;
	if ($CntTbl > 0) {
		foreach (@DataSubDirsTable)	{
		system("chmod 755 $_"); }
	}
}


#
# -------------------
#======================================================================#
# Rafal CZARNY
# (c) 2007
