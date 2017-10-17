#! D:/TeXLive/bin/win32/perl.exe
#======================================================================#
#                            WordCounter.pl
#                         --------------------
#   date        : 08/12/2004,  ver. 0.30
#   copyright   : (c) 2004 by Rafal Czarny
#   email       : rafal@czarny.biz
#----------------------------------------------------------------------#
#	  This is a simply script in Perl. 
#   It counts the words in file, so... piece of cake! :)
#
#======================================================================#

	print "I will count words in your file!!!\n\n";

	$FILE_NAME = $ARGV[0];
	
	$Sum = 0;
	$File_Out = "Temp.log";
	
	if (-e $FILE_NAME)
	{	open(FILE_IN,$FILE_NAME); }
	else 
	{ print "=== This file doesn't exist!!! BYE!! ===\n\n";
		exit 0; }

#  Loop through the file
# -----------------------
	
	while (<FILE_IN>)
	{	chomp($_);
    @LineTemp = split(/\s+/,$_);
##		$Sum += ($#LineTemp+1);   or in shorter way...
		$Sum += @LineTemp;
	}

	print "The numer of words is -->  $Sum\n\n";

	open(FILE_OUT,">$File_Out");
	print FILE_OUT "The numer of words is -->  $Sum";
	close(FILE_OUT);


#
# -------------------
#--------[  ]--------#
#======================================================================#
# Rafal CZARNY
# (c) 2004