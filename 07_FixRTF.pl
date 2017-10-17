#! C:/TeXLive/bin/win32/perl.exe
#=====================================================================#
#                               FixRTF
#                       ----------------------
#  date       : 00/00/2013, v0.00
#  copyright  : (c) 2013 by Rafal Czarny
#  email      : rafal_czarny@tlen.pl
#---------------------------------------------------------------------#
#  
#=====================================================================#

	print "Removing single pages numbers from the RTF file\n\n";

	$File_IN  = $ARGV[0];
	$File_OUT = $ARGV[1];
	
	if ($#ARGV == 0) {
		@FileTemp = split(/\.rtf$/,$File_IN);
		$File_OUT = $FileTemp[0]."_FIX.rtf";
	}
	if (-e $File_IN) {
		open(FILE_IN,$File_IN); }
	else {
		print "=== This file doesn't exist!!! BYE!! ===\n\n";
		exit 0;
	}
	open(FILE_OUT,">$File_OUT");

# Loop through the file
# ----------------------
# We are looking for the following lines like:
# 
# \par \hich\af0\dbch\af11\loch\f0 8
# \par \hich\af0\dbch\af11\loch\f0 f
#   m/^\\par\s*(\\.+)*\s+\d+$/ 


	while ($linia = <FILE_IN>) {
		if ($linia !~ m/^\\par\s*(\\.+)*\s+\w{1,3}\s*$/) {
			print FILE_OUT "$linia";
		}
	}
	close(FILE_OUT);
	close(FILE_IN);
	print "Done. Bye!\n\n";




#---------------------------------------------------------------------#
#=====================================================================#
# Rafal CZARNY
# (c) 2013