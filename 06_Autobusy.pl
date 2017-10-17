#!/usr/bin/perl
#======================================================================#
#                             Autobusy.pl
#                         --------------------
#   date        : 2010/04/27,  ver. 1.06
#   copyright   : (c) 2007-2010 by Rafal Czarny
#   email       : rafal_czarny@tlen.pl
#----------------------------------------------------------------------#
#  This script is taking a file with data for all buses, 
#  they are represented in separete line as follows:
#   <Code>	<Hour>	<Minute> <Comments-Option>
#   ......
#  The result should a file acceptable for LaTeX template
#  or this can be something else -- to be checked
# 
#======================================================================#


# Some tricky functions for time conversion etc.
# ----------------------------------------------

# T(h,m) --> t
sub CTIME
{ my($Hour,$Minute) = @_;
	return $Hour*60+$Minute;
}

# T^{-1}(t) --> (h,m)
sub CTIMEREV
{	my($Time) = @_;
	my $GetHour;
	my $GetMinute;
	$GetHour = int($Time/60);
	$GetMinute = $Time%60;
	return ($GetHour,$GetMinute);
}

# Finds an index for first occurence of value
sub FINDIND
{	local(*Array,$Value) = @_;
	my @RetInd = ();
	my $i = 0;
	foreach $val (@Array) {
		if ($val == $Value) {
			push(@RetInd,$i);
			++$i;
		  next; }
		else { ++$i; }
	}
	return @RetInd;
}

# Write one line to output file
sub WRITE_ONE_LINE
{	local($FILE_Handle,*Indexes) = @_;
	for ($i=0; $i<$#Indexes; $i++) {
		if ($Indexes[$i] != 9999) {
			print $FILE_Handle "\\Autobus$TRAN_Org[$Indexes[$i]]\{$HOUR_Org[$Indexes[$i]]\}\{$MIN_Org[$Indexes[$i]]\}\{$COMM_Org[$Indexes[$i]]\} \& "; }
		else {
			print $FILE_Handle " \& \&   \& "; }
	}
	if ($Indexes[$i] != 9999) {
		print $FILE_Handle "\\Autobus$TRAN_Org[$Indexes[$#Indexes]]\{$HOUR_Org[$Indexes[$#Indexes]]\}\{$MIN_Org[$Indexes[$#Indexes]]\}\{$COMM_Org[$Indexes[$#Indexes]]\} \\\\ \n"; }
	else {
		print $FILE_Handle " \& \&   \\\\ \n"; }
}


# Some global settings for this script
# ------------------------------------
# Constants
	$NBR_COLS = 4;

# Files	
	$File_IN = $ARGV[0];
	$File_OUT = $ARGV[1];
	if (!$File_OUT) { $File_OUT='Autobusy.txt'; }
	$FileTest = 'TestOut.txt';

# First range of entries
	@TRAN_Org = ();   # Orginal type of location
	@HOUR_Org = ();   # Orginal hour of a bus
	@MIN_Org = ();    # Orginal minute of a bus
	@COMM_Org = ();   # Orginal additional comments (if any)
	@TIME_Org = ();   # Orginal time after conversion
# Entries sorted:
	@TIME_Sort = ();  #
	@INDEX_Sort = (); # Index of orginal tables sorted acending


#	MAIN SCRIPT
# -------------------
	$CountLine = 0;

# Read the input file contains data for buses
	open(FILE_IN,$File_IN);
	while($Line = <FILE_IN>)
	{	if ($Line =~ /.*/)
		{ $CountLine += 1;
			@Tab_Temp = split(/\s+/,$Line);
# Trasport's code
			push(@TRAN_Org,$Tab_Temp[0]);
# Hours' and minutes' code
			push(@HOUR_Org,$Tab_Temp[1]);
			push(@MIN_Org,$Tab_Temp[2]);
# Comments if any
			if ($#Tab_Temp == 3) {
				push(@COMM_Org,$Tab_Temp[3]);
			} else {
				push(@COMM_Org,"");
			}
		}
	}
	close(FILE_IN);
#
# Conversion of all table in orginal sort
	for ($i=0; $i<$CountLine; $i++) {
		$TIME_Org[$i] = &CTIME($HOUR_Org[$i],$MIN_Org[$i]);
	}
	@TIME_Sort = sort {$a <=> $b} @TIME_Org;
# 
	for ($i=0; $i<$CountLine; $i++) {
		@IndexTemp = &FINDIND(*TIME_Org,$TIME_Sort[$i]);
		if ($i > 0) {
			@TempTab = @TIME_Sort[0..$i-1];
			@CheckIfUnique = &FINDIND(*TempTab,$TIME_Sort[$i]);
			if ( @CheckIfUnique ) {}
			else { push(@INDEX_Sort,@IndexTemp); }
		}
		else {
			push(@INDEX_Sort,@IndexTemp);
		}
	}
#
	for ($i =0; $i<$CountLine; $i++) {
		if ($MIN_Org[$i] < 10) {
			$MIN_Org[$i] = "0$MIN_Org[$i]"; }
	}
# Built a LaTeX file
	open(FILE_OUT,">$File_OUT");
	$MODULO = $CountLine % $NBR_COLS;
	if ($MODULO == 0) {
		$NBR_Lines = int($CountLine/$NBR_COLS); }
	else {
		$NBR_Lines = int($CountLine/$NBR_COLS)+1;
    # here we add in artificient way additional elements to @INDEX_Sort table to fill all colums
		for ($i=$MODULO; $i<$NBR_COLS; $i++) {
			push(@INDEX_Sort,9999); }
	}
#	print "$CountLine --> $NBR_Lines --> $MODULO\n";
	
	for ($j=0; $j<$NBR_Lines; $j++) {
		print "Writing the line no $j...\n";
			@Ind_Array = ();
			for ($k=0; $k<$NBR_COLS; $k++) {
				push(@Ind_Array,$INDEX_Sort[$j+$k*$NBR_Lines]); }
			&WRITE_ONE_LINE(FILE_OUT,*Ind_Array);
	}
	close(FILE_OUT);


#--------------------
#======================================================================#
# Rafal CZARNY
# (c) 2007-2010