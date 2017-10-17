#! C:\Strawberry\perl\bin\perl.exe
#=====================================================================#
#                            RemoveSMS.pl
#                       ----------------------
#  date       : 2016/11/29,  ver. 0.22
#  copyright  : (c) 2014-2016 by Rafal Czarny
#  email      : rafal_czarny@tlen.pl
#---------------------------------------------------------------------#
#  
#=====================================================================#

	print "Cleaning SMS...\n\n";

	$NoOfSMS  = -1;
	$File_IN  = $ARGV[0];
	$NoOfSMS  = $ARGV[1];
#	
	if (($NoOfSMS > 0) && ($#ARGV > 0)) {
		$SMSMAXNumber = $NoOfSMS;	}
	else {
		$SMSMAXNumber = 1000;
	}
	print "No of SMS to be skipped: $NoOfSMS\n";
	$SMSi = 0;
	$SMSJovi = 0;
#	
	@FileTemp = split(/\.xml$/,$File_IN);
	$File_OUT = $FileTemp[0]."_FIX.xml";
	$File_LOG = $FileTemp[0]."_LOG.xml";
#
	if (-e $File_IN) {
		open(FILE_IN,$File_IN); }
	else {
		print "=== This file doesn't exist!!! BYE!! ===\n\n";
		exit 0;
	}
	open(FILE_OUT,">$File_OUT");
	open(FILE_LOG,">$File_LOG");	

# Loop through the file
# ----------------------
# We are looking for the following lines like:
# that contains:
#    address="+48660390312"
# 
#

	while ($linia = <FILE_IN>) {
		if ($linia =~ m/^.*48660390312.*$/) {
			if ($SMSJovi < $SMSMAXNumber) {
				$SMSi++;
				$SMSJovi++;
				print FILE_LOG "SMS No. $SMSi (Jovi: $SMSJovi) skipped!\n"; }
			else {
				$SMSi++;
				$SMSJovi++;
				print FILE_OUT "$linia";
				print FILE_LOG "SMS No. $SMSi (Jovi: $SMSJovi) saved!\n"; } }
		else {
			$SMSi++;
			print FILE_OUT "$linia"; 
			print FILE_LOG "SMS No. $SMSi saved!\n"; }
	}
	close(FILE_OUT);
	close(FILE_LOG);
	close(FILE_IN);
	print "Done. Bye!\n\n";


#---------------------------------------------------------------------#
#=====================================================================#
# Rafal CZARNY
# (c) 2013-2016