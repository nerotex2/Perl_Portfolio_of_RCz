#!/usr/bin/perl
#=====================================================================#
#                               SCalls
#                       ----------------------
#  Date       : 2010/12/14, v1.21
#  Copyright  : (c) 2009-2010 by Rafal Czarny
#  Email      : rafal.czarny@oracle.com
#---------------------------------------------------------------------#
#
#  This is a script for displaying all emails in the row, using 'less'
#  or similar command.
#  (That is simply putting all emails with their headers and some fancy
#   dashed lines, numbers, etc.)
#  Any comments, bugs - please send them on the above email.
#=====================================================================#
#
# We use standard 'Getopt' module to handle all options
  use Getopt::Long;
  Getopt::Long::Configure ('bundling','ignore_case','pass_through');
#
# Module for usage of the time function 'timelocal_nocheck'
        use Time::Local 'timelocal_nocheck';
#
#
# Default flags and switches
# --------------------------
#
# This is used mainly to create switches and other global variables
        $DISPLAY    = 1;  # should we display the file with some command (ie. 'less')
        $DISPLAYHEA = 1;  # show the headers of emails
        $DISPLAYBOD = 1;  # show the bodies of emails
        $LINESALL   = 1;  # by default, all lines are printed
        $LINESEMPTY = 0;  # if it's true we will try to remove empty lines from the body
        $LINESSMART = 0;  # some smarter way of removing empty lines
        $LAST       = 0;  # how many last emails we will print by default
        $FROMEND    = 0;  # print single email counting from the end
        $SORT       = 0;  # the sorting method of elements in table (1-ascending, 2-descending)
        $REVERSE    = 0;  # should we use reverse order from the table
        $CLIPBOARD  = 0;  # do we copy the file conent using "xclip"
        $DONOTREM   = 0;  # should we remove the temp file that holds all copied emails
        $OLDALL     = 0;  # should we search in all subfolders of the given case folder
        $EXTRACT    = 0;  # do we extract and copy all text attachments to the temp folder
        $UTCTIMES   = 0;  # use the UTC timezone for all times in headers
        $UTCSHIFTH  = 0;  # number of hours shifted from the UTC time
        $EmptyArgs  = 0;  # it will be "1" if there is no email numbers are given at all
        $GOPTFILEN  = ''; # the file name given when using the option 'g'
#
        $SINGLEFILE = ''; # the name of the single file to provide a different file's operations
        $SNG_HELP   = 0;  # should we print a quick 'help' messages?
        $SNG_SMART  = 0;  # activates the '-k' option
        $SNG_MESSAG = 0;  # activates the '-m' option
        $SNG_MESSSP = 0;  # activates the '-p' option
        $SNG_QUOTES = 0;  # activates the '-q' option
        $ADDLASTLINE= 0;  # additional switch to allow printing the last line from messages file
#
        $DISPLAY_COMMAND = 'less';  # what is the command used for displaying all emails
#
# Some arrays for dates manipulations
        @MonthsName = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
        %MonthsMaps = ('Jan',1,'Feb',2,'Mar',3,'Apr',4,'May',5,'Jun',6,
                 'Jul',7,'Aug',8,'Sep',9,'Oct',10,'Nov',11,'Dec',12);
        @WeekDays   = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat','Sun');
#
        @FirstINDEX = ();   # Auxiliary table
        @INDEX = ();        # Main index to store numbers for the emails to be displayed
        @ListOfEMails = (); # List of emails in SCalls that match the Mail folder
#
#
# The core of the script
# -----------------------
#
# Read and proceed all defined options, all these options will be removed from the @ARGV table
        GetOptions('a|asc'        => sub { $SORT = 1; },
             'b|body'       => sub { $DISPLAYHEA = 0; $DISPLAYBOD = 1; },
             'c|clip'       => sub { $CLIPBOARD = 1; $DISPLAY = 0; },
             'd|desc'       => sub { $SORT = 2; },
             'e|empty'      => sub { $LINESALL = 0; $LINESEMPTY = 1; $LINESSMART = 0; },
             'f|fend:1'     => sub { $LAST = 0; $FROMEND = $_[1]; },
             'g|generate:s' => sub { $DISPLAY = 0; $DONOTREM = 1; $GOPTFILEN = $_[1]; },
             'h|help'       => \$SNG_HELP,
             'i|header'     => sub { $DISPLAYHEA = 1; $DISPLAYBOD = 0; },
             'k|file=s'     => sub { $SNG_SMART = 1; $SINGLEFILE = $_[1]; },
             'l|last:1'     => sub { $FROMEND = 0; $LAST = $_[1]; },
             'm|messages=s' => sub { $SNG_MESSAG = 1; $SINGLEFILE = $_[1]; },
             'n|notrem'     => \$DONOTREM,
             'o|old'        => \$OLDALL,
             'p|messagsp=s' => sub { $SNG_MESSSP = 1; $SINGLEFILE = $_[1]; },
             'q|rmquotes=s' => sub { $SNG_QUOTES = 1; $SINGLEFILE = $_[1]; },
             'r|reverse'    => \$REVERSE,
             's|smart'      => sub { $LINESALL = 0; $LINESEMPTY = 0; $LINESSMART = 1; },
             'u|utc:f'      => sub { $UTCTIMES = 1; $UTCSHIFTH = $_[1]; },
             'x|extract'    => \$EXTRACT,
             'lastline'     => \$ADDLASTLINE
                                                );
#
#
# Running 'single-option'
# ------------------------
# We start by checking if any of the 'single-option' is present, this is just to run the scipt this way:
#   SCalls -<x> <File_Name>
# so to perform some operations on the file '<File_Name>', ie. to create another '<File_Name>_fix' file and then to exit.
#
#
# '-h' : If the -h option is used, then we will print small help and quit the script
        if ($SNG_HELP) {
                SCallsHelp();   exit(0);
        }
# Quick checking if the file given exists and also to define the name for an output file
        if ($SNG_SMART || $SNG_MESSAG || $SNG_MESSSP || $SNG_QUOTES) {
                if (!-e $SINGLEFILE || !-T $SINGLEFILE) {
                        print "The file $SINGLEFILE doesn't exit or it's not a text file! Exiting the script...\n";
                        exit(0);
                }
                if ($GOPTFILEN eq '') {
                        $SINGLEFILE_FIX = "$SINGLEFILE"."_fix"; }
                else {
                        $SINGLEFILE_FIX = $GOPTFILEN; }
        }
# 
# '-k' : run 'SCallsSmartLines' function on the file given and then exit the script
        if ($SNG_SMART) {
                open(SINGLE_IN,$SINGLEFILE);
                open(SINGLE_OUT,">$SINGLEFILE_FIX");
                SCallsSmartLines(SINGLE_IN,SINGLE_OUT);
                close(SINGLE_OUT);
                close(SINGLE_IN);
                exit(0);
        }
#
# '-m' & '-p' : run 'SCallsFixMessages' function on the file given and then exit the script
        if ($SNG_MESSAG || $SNG_MESSSP) {
                SCallsFixMessages($SINGLEFILE,$SINGLEFILE_FIX);
                exit(0);
        }
#
# '-q' : run 'SCallsRemoveQuotes' function on the file given and then exit the script
        if ($SNG_QUOTES) {
                SCallsRemoveQuotes($SINGLEFILE,$SINGLEFILE_FIX);
                exit(0);
        }
#
#
# Gathering data
# ---------------
# Find the main string that denotes the list of emails, 
# for now, it will find only the last match.
# But, we'll decode this notation later, after the max number of emails is found
        if ($#ARGV == -1) {     $EmptyArgs = 1; }
        else {
                foreach $RCzArg (@ARGV) {
                        if ($RCzArg =~ m/(((\d*,)*(\d*-\d*,)*)*((\d*-\d*)|\d*))/) #  replacing + by *
                        { $MainIndexFull = $1; }
                }
                @TabSplitNbsExt = split(/,/,$MainIndexFull); # splitting on commas
        }
#
# That's all for the options passed to this script, the next step is to get the list of all emails
# in the actual folder.
#
#
# The email folders to be gathered from actual folder
        $CURRENT_DIR = `pwd`;   chomp($CURRENT_DIR);
#
# The local timezone, used for displaying
        $LOCAL_TZONE = `date '+%Z'`; chomp($LOCAL_TZONE);
#
# Are we in /net/cores.uk/exports/calls/<Case> ?
#   if not, then we need to go back to this folder
        @CurrentDirLevels = split(/\//,$CURRENT_DIR);
        @CurrentDirLevelsNew = (); $CDLi = -1; $CaseNoIndex = -1; $CaseNoFound = 0;
        foreach $Level (@CurrentDirLevels) {
                $CDLi++;
                if ((($Level =~ m/^\d{8}$/) || ($Level =~ m/^\d{1}-\d{10}$/) || ($Level =~ m/^\d{1}-\d{7}$/)) && ($CaseNoFound == 0))
                        { $CaseNoIndex = $CDLi; $CaseNoFound = 1; }
        }
        if ($CaseNoIndex == -1) {  # this is if we are in the wrong SCalls folder without case number
                $CaseNoIndex = $#CurrentDirLevels;
        }
        for ($i=0; $i<=$CaseNoIndex; $i++) {
                push(@CurrentDirLevelsNew,$CurrentDirLevels[$i]);
        }
        $CURRENT_DIR_NEW = join('/',@CurrentDirLevelsNew);
        $CASE_NO = $CurrentDirLevelsNew[$#CurrentDirLevelsNew]; # case number for further ref.
        chdir("$CURRENT_DIR_NEW");
#
        if (!$OLDALL) {
                opendir(SCallsDIR,".") || die "Can't open case directory.\n";
                @DIRandFILES = grep {!/^\.+$/} readdir(SCallsDIR);
                closedir(SCallsDIR);
                foreach $entry (@DIRandFILES) {
                        if ((-d $entry) && ($entry =~ /Mail-\d{4}_\d{2}_\d{2}_\d{2}.{1}\d{2}.{1}\d{2}/)) {
                                push(@ListOfEMails,$entry);
                        }
                }
                @ListOfEMails_Save = @ListOfEMails;
                @ListOfEMails = sort @ListOfEMails_Save;
        }
        else {
                @ListOfEMails = SCallsSearchAllEmails();
        }
        $MAX_EMAIL = @ListOfEMails;
#
# Get the files in the folder and the next free no
        $MaxFirstNumber = 0; # the last max number of the files of type "<Number>_<Rest-of-the-name>"
        if ($DONOTREM) {
                opendir(SCallsDIR,".") || die "Can't open case directory.\n";
                @DIRandFILES = grep {!/^\.+$/} readdir(SCallsDIR);
                closedir(SCallsDIR);
                foreach $entry (@DIRandFILES) {
                        if ($entry =~ m/\d+_.*/) {
                                @SplitFileName = split(/_/,$entry);
                                if ($SplitFileName[0] > $MaxFirstNumber) {
                                        $MaxFirstNumber = $SplitFileName[0]; }
                        }
                }
        }
        $MaxFirstNumber += 1;
#
# We set the standard list of emails, 1,..,$MAX_EMAIL (by default)
        @INDEX = (1..$MAX_EMAIL);
#
# When we sucessfuly stored the argument for list of messages in $MainIndexFull
# we need to store ALL numbers, one by one in @INDEX table, that is ie. 1-5 should 
# be stored as 1,2,3,4,5 etc. This needs check also if the interval denotes:
#   - ascending order (1-3, 5-8),
#   - descending order (8-5, 3-1),
#   - from the given to the last (1-, 3-),
#   - from the first to the last given (-3, -5)
        if (!$EmptyArgs) {
                foreach $RCzArg (@TabSplitNbsExt) {
#
# we have some general interval '[i]-[j]' that we will examinate on 3 cases above
                        if (($RCzArg =~ m/^\d*-\d*$/) && ($RCzArg !~ m/^-$/)) {
                                if ($RCzArg =~ m/^\d+-\d+$/) {  # (1) we have some standard interval 'i-j' (like 2-5)
                                        @TabSplitNbsInt = split(/-/,$RCzArg);
                                }       else {
                                                if ($RCzArg =~ m/^\d+-$/) { # (2) we have the interval of type 'i-' (ie 2-)
                                                        @TabSplitNbsInt = split(/-/,$RCzArg);
                                                        if ($TabSplitNbsInt[0] <= $MAX_EMAIL) { push(@TabSplitNbsInt,$MAX_EMAIL); }
                                                        else { push(@TabSplitNbsInt,$TabSplitNbsInt[0]); }
                                                }
                                                if ($RCzArg =~ m/^-\d+$/) { # (3) we have the interval of type '-j' (ie -5)
                                                        @TabSplitNbsInt = split(/-/,$RCzArg);
                                                        push(@TabSplitNbsInt,$TabSplitNbsInt[0]); $TabSplitNbsInt[0] = 1;
                                                }
                                        }
                                if ($TabSplitNbsInt[1]-$TabSplitNbsInt[0] >= 0) { # we're going up...
                                        for ($i=0; $i<=($TabSplitNbsInt[1]-$TabSplitNbsInt[0]); $i++) {
                                                push(@FirstINDEX,$TabSplitNbsInt[0]+$i);
                                        }
                                }
                                else { # we're going down with numbers
                                        for ($i=0; $i<=($TabSplitNbsInt[0]-$TabSplitNbsInt[1]); $i++) {
                                                push(@FirstINDEX,$TabSplitNbsInt[0]-$i);
                                        }
                                }
                        }
                        else { 
                                if ($RCzArg =~ m/^\d+$/) { # add other numbers that are just a single numbers
                                        push(@FirstINDEX,$RCzArg);
                                } else {
                                                if ($RCzArg =~ m/^-$/) { # and what if we have just a single '-' (I know, some people will try that... ;-))
                                                        @FirstINDEX = @INDEX;
                                                }
                                        }
                        }
                }
                @INDEX = @FirstINDEX;
        }
#
# Projection of actual number of emails found in the SCalls folder on 
#       the actual @INDEX table (that is removing emails that are out of the real range of emails)
        @INDEXSave = ();
        for ($i=0; $i<=$#INDEX; $i++) {
                if (($INDEX[$i] > 0) && ($INDEX[$i] <= $MAX_EMAIL)) {
                        push(@INDEXSave,$INDEX[$i]);
                }
        }
        @INDEX = @INDEXSave;
#
# Now, let's see if there are any request for "last"
        if ($LAST > 0 && $LAST <= $MAX_EMAIL) {
                @INDEXSave = @INDEX;
                @INDEX = ();
                for ($i=$#INDEXSave-$LAST+1; $i<=$#INDEXSave; $i++) {
                        push(@INDEX,$INDEXSave[$i]);
                }
                $SORT = 2;  # together with "last" option, we will sort descending last emails chosen
        }
#
# Now, let's see if there is a "from end" email (only one to be printed in this option)
        if ($FROMEND > 0 && $FROMEND <= $MAX_EMAIL) {
                @INDEXSave = @INDEX;
                @INDEX = ();
                push(@INDEX,$INDEXSave[$MAX_EMAIL-$FROMEND]);
        }
#
# Then, let's see if we need to sort the table (by default ascending) and also
# if the reverse order (this will be used later, after the table is sorted)
# 
        if ($SORT == 1) {
                @INDEX = sort {$a <=> $b} @INDEX;
        }
        if ($SORT == 2) {
                @INDEX = sort {$b <=> $a} @INDEX;
        }
        if ($REVERSE) {
                @INDEX = reverse(@INDEX);
        }
#
# Do we try to extract and copy the files
        if ($EXTRACT) {
                SCallsExtractAndCopyFiles();
                exit(0);
        }
#
#
# Searching for Explorer / Building the Main file 
# ------------------------------------------------
#
# Some values for email printing
        $EMAILHEADER = 'HeaderDetails.txt';
#
# If we decide not to remove the temp file, I will add the "timestamp" to the file name.
        if ($DONOTREM) {
                $SCActualDateTime = `date '+20%y-%m-%d_T%H-%M-%S'`;
                chomp($SCActualDateTime);
                if ($GOPTFILEN ne '') {
                        $MAINFILE = $GOPTFILEN; }
                else {
                $MAINFILE = "$MaxFirstNumber"."_"."$CASE_NO"."_Emails-Temp_"."$SCActualDateTime".".txt"; }
        }
        else {
                $MAINFILE = "$CASE_NO"."_Emails-Temp.txt"; }
        $DASHEDLINE = '============================================';
#
# quick check if the temp file is existing, if so, then we will remove them
        if (-e $MAINFILE) { system("rm -f $MAINFILE"); }
#
        open(MAINFILE_OUT,">>$MAINFILE");
        foreach $EMailNo (@INDEX) {
                SCallsAddOneEmail($ListOfEMails[$EMailNo-1],$EMailNo);
        }
        close(MAINFILE_OUT);
        if ($DISPLAY) {
                system("$DISPLAY_COMMAND $MAINFILE");
        }
        if ($CLIPBOARD) {
                system("xclip -selection clipboard $MAINFILE");
        }
        if (!$DONOTREM) {
                system("rm -f $MAINFILE");
        }
#
#
#
#---------------------------------------------------------------------#
#
# "Smart" removing of empty lines
# --------------------------------
# We will try to represent here the "smart" removing of the empty lines, that means removing some of the empty lines 
# depends of how many of them is located together. The plan is to remove lines as per the following rules:
# (Here A,B means non-empty lines and 1 represents line consists of white charactes only. Also, "left to right" means: 
#  from the beginnig to the end of the file)
#  1) [A 1 B] -> [A B]  (one empty line is removed)
#  2) [A 1 1 B] -> [A 1 B]  (two empty lines next to each other are compressed to one)
#  3) [A 1 1 1 ... 1 B] -> [A 1 1 B] (three or more empty lines next to each other are compressed to two)
#
#  OK, so the "tricky" ;-) algoritm here is to:
#  1) parse the file given and create the "boolean" matrix of [0,1], 0: non-empty line, 1: empty line (-> @SmFirst),
#  2) parse the @SmFirst matrix and create a matrix of sums (@SmAuxSum, for the group of ones), ie.:
#     [0 1 0] -> [0 1 0], 0 1 1 0 -> [0 2 0], [0 1 1 ... 1 0] -> [0 n 0].
#  3) create the final matrix @SmEnd, that will use the @SmAuxSum, and to expand it this way:
#     * if (1) -> 1
#     * if (2) -> 0 1
#     * if (>=3) -> 0 0 1 ... 1
#  4) print the lines to the new file: $SmEnd[i] == 0 -> print the line
# 
sub SCallsSmartLines {
        my ($FileHIn,$FileHOut) = @_;
#
# Matrices used for manipulating the indexes
        my @SmFirst = ();
        my @SmAuxSum = ();
        my @SmEnd = ();
        my $NoLines = 0;
        my $i = 0;
        my $SmAuxEl = 0;
#
# Step 1)
        while (<$FileHIn>) {
                if ($_ =~ /^\s*$/) { push(@SmFirst,1); }
                else { push(@SmFirst,0); }
        }
#
#       Step 2)
        while ($i <= $#SmFirst) {
                if ($SmFirst[$i] == 1) {
                        $SmOnes = 1;
                        $i++;
                        while ($SmFirst[$i] == 1) {
                                $SmOnes++;
                                $i++;
                        }
                        push(@SmAuxSum,$SmOnes);
                }
                else {
                        push(@SmAuxSum,$SmFirst[$i]);
                        $i++;
                }
        }
#
# Step 3)
        foreach $SmAuxEl (@SmAuxSum) {
                if (($SmAuxEl == 0) || ($SmAuxEl == 1)) {
                        push(@SmEnd,$SmAuxEl);
                }
                if ($SmAuxEl == 2) {
                        push(@SmEnd,0); push(@SmEnd,1);
                }
                if ($SmAuxEl >= 3) {
                        push(@SmEnd,0); push(@SmEnd,0);
                        for ($i=0; $i<$SmAuxEl-2; $i++) {
                                push(@SmEnd,1); }
                }
        }
#
# Step 4)
        $i = 0;
        sysseek($FileHIn,0,SEEK_SET);
        while (<$FileHIn>) {
                if ($SmEnd[$i] == 0) { 
                        $_ =~ s/\015//; # removes ^M, added in v1.03
                        print $FileHOut $_; }
                $i++;
        }
}
#
# Filtering the messages from text
# ---------------------------------
# This idea and also the code has been taken from Doug Baker's 'fixmail' script.
# For both options '-m' and '-p' -- it searches all lines in the file given that match the pattern 
# '<Month> ...', then the rest of the message line is unwrapped.
# The algorithm used below will not print the last line that matches the date pattern, to print this line
# additional option '--lastline' can be used.
#
sub SCallsFixMessages {
        my ($FileIn,$FileOut) = @_;
        my $FoundL = 0;
        my $StartL;  my $Line;  my $Mon;
        my $i = 0;
        open(SINGLE_IN,$SINGLEFILE);
        open(SINGLE_OUT,">$SINGLEFILE_FIX");
        while ($Line = <SINGLE_IN>) {
                chomp($Line);
                $Line =~ s/\015//;      # removes ^M
                if ($FoundL == 1) {
                        $i = 0;
                        foreach $Mon (@MonthsName) {
                                if ($Line =~ m/^$Mon/) {
                                        $i = 1; }
                        }
                        if ($i == 1) {
                                print SINGLE_OUT "$StartL\n";
                                $StartL = $Line; }
                        else {
                                if ($SNG_MESSSP) {
                                        $StartL = "$StartL $Line"; }
                                else {
                                        $StartL = "$StartL$Line"; }
                        }
                }
                if ($FoundL == 0) {
                        foreach $Mon (@MonthsName) {
                                if ($Line =~ m/^$Mon/) {
                                        $StartL = $Line;
                                        $FoundL = 1; }
                        }
                }
        }
        if ($ADDLASTLINE) {
                print SINGLE_OUT "$StartL\n";
        }
        close(SINGLE_OUT);
        close(SINGLE_IN);
}
#
# Removing the quote and timestamps signs 
# ----------------------------------------
# This will remove the quote signs '>' from the begins of the lines.
# Also it will remove timestamps like '<(Date)>' that are added by some terminal servers or console loggers.
#
sub SCallsRemoveQuotes {
        my ($FileIn,$FileOut) = @_;
        my $Line;
        open(SINGLE_IN,$SINGLEFILE);
        open(SINGLE_OUT,">$SINGLEFILE_FIX");
        while ($Line = <SINGLE_IN>) {
                $Line =~ s/^\s*(>\s*)+//;
                $Line =~ s/^\s*<.*>\s*//;
                $Line =~ s/\015//;      # removes ^M
                print SINGLE_OUT $Line;
        }
        close(SINGLE_OUT);
        close(SINGLE_IN);
}
#
# Searching for all emails in all subfolders
# -------------------------------------------
# This function will search for all emails folders in all subfolders
# (only '*explorer*' and '*guds*' folders are skipped).
# To implement this search we use the graph search algorithm - BFS Algorithm (Breadth-first search).
#
sub SCallsSearchAllEmails {
        my @BFSFIFO = ();  # BFS - table for BFS queue
        my %BFSVSTD = ();  # BFS - table for visited/nonvisited nodes
        my @FullFol = ();  # Array with full folders
        my @NameFol = ();  # Array with names of folders itself
        my @IndFold = ();  # Array with index of emails folders
        my @SortFol = ();  # Array with names of folders itself, sorted
        my @ReturnF = ();  # Array with full names of folders and sorted
#
        my $node = '';     my $CurrDir = '';     my @CurrDirTab = ();  my $i = '';
        my $EMailTmp = ''; my @EMailTmpTab = (); my @NodeNeigh = ();   my $j = 0;
#
# BFS Algorithm (Breadth-first search)
        push(@BFSFIFO,".");
        $BFSVSTD{"."} = 0;
        while ($#BFSFIFO >= 0) {
        # part for "visiting" the node
                $node = splice(@BFSFIFO,0,1);
                chdir("$CURRENT_DIR_NEW/$node/");
                $CurrDir = `pwd`;       chomp($CurrDir);
                @CurrDirTab = split(/$CASE_NO\//,$CurrDir);
                if ($#CurrDirTab == 1) {
                        push(@FullFol,$CurrDirTab[1]);
                } else {
                        push(@FullFol,".");
                }
                $CurrDir = $FullFol[$#FullFol];
                opendir(LocDIR,".") || die "Can't open $CurrDir directory.\n";
                @EMailTmpTab = grep {!/^\.+$/} readdir(LocDIR);
                closedir(LocDIR);
                @NodeNeigh = ();
                foreach $i (@EMailTmpTab) {
                        if ((-d $i) && ($i !~ /.*explorer.*/) && ($i !~ /.*guds.*/)) {
                                push(@NodeNeigh,$i);
                                $BFSVSTD{"$CurrDir/$i"} = 1;
                        }
                }
                foreach $i (@NodeNeigh) {
                        if ($BFSVSTD{"$CurrDir/$i"}) {
                                push(@BFSFIFO,"$CurrDir/$i");   $BFSVSTD{"$CurrDir/$i"} = 0;
                        }
                }
        }
# end of BFS
#
# Removing the beginnig of the path until the last '/'
        for ($i=0; $i<=$#FullFol; $i++) {
                if ($FullFol[$i] =~ /.*Mail-\d{4}_\d{2}_\d{2}_\d{2}.{1}\d{2}.{1}\d{2}$/) {
                        @EMailTmpTab = split(/\//,$FullFol[$i]);
                        push(@NameFol,$EMailTmpTab[$#EMailTmpTab]);
                        push(@IndFold,$i);
                }
        }
#
# Sorting and building the return array
        @SortFol = sort @NameFol;
        my $Found = 0;
        for ($i=0; $i<=$#SortFol; $i++) {
                $Found = 0;
                $j = -1;
                while (!$Found) {
                        $j++;
                        if ($SortFol[$i] eq $NameFol[$j]) {
                                push(@ReturnF,$FullFol[$IndFold[$j]]);
                                $Found = 1;
                        }
                }
        }
        chdir("$CURRENT_DIR_NEW");
        return @ReturnF;
}
#
# TimeStamp for emails
# ---------------------
# This will format the timestamp for emails headers, here we will convert the time to localzone
#
sub SCallsConvertAndReturnTime {
        my($EmailDateInput) = @_;
        my $ReturnDatePrint = '';
#
# Spliting the input string for the time calculation
        my @EMailDateParts = split(/,\s+|\s+|\:/,$EmailDateInput);
        my $WDay   = $EMailDateParts[0];
        my $Day    = $EMailDateParts[1];
        my $Month  = $MonthsMaps{"$EMailDateParts[2]"};
        my $Year   = $EMailDateParts[3];
        my $Hour   = $EMailDateParts[4];
        my $Minute = $EMailDateParts[5];
        my $Sec    = $EMailDateParts[6];
        my $LocShift = $EMailDateParts[7];
#
# Decomposing the timezone shifted time
        my @LocShiftTab = split(//,$LocShift);
        my $TZHour = ($LocShiftTab[1]*10)+$LocShiftTab[2];
        my $TZMin  = ($LocShiftTab[3]*10)+$LocShiftTab[4];
#
# Calculating the shift of the timezone in case if we want to calculate all to the localtime zone (ie. UTC on Cores2)
        if ($UTCTIMES) {
                my $LocShiftSec = ($TZHour*3600) + ($TZMin*60);
                $LocShiftSec *= "$LocShiftTab[0]1";
                my $TimeLocal = timelocal_nocheck($Sec,$Minute,$Hour,$Day,$Month-1,$Year);
                my $TimeShifted = $TimeLocal - $LocShiftSec + ($UTCSHIFTH*3600);
                my ($ShSec,$ShMinute,$ShHour,$ShDay,$ShMonth,$ShYear,$ShWDay,$ShYDay,$ShIsDST) = localtime($TimeShifted);
                $ShYear += 1900;
                if ($ShSec < 10)  { $ShSec = "0".$ShSec; }        if ($ShMinute < 10) { $ShMinute = "0".$ShMinute; }
                if ($ShHour < 10) { $ShHour = "0".$ShHour; }    if ($ShDay < 10)    { $ShDay = "0".$ShDay; }
                $ReturnDatePrint = "$WeekDays[$ShWDay], $ShDay-$MonthsName[$ShMonth]-$ShYear $ShHour:$ShMinute:$ShSec";
        }
        else {
#
# Otherwise we will leave the default values
                if ($Day =~ /^\d{1}$/) { $Day = "0".$Day; }
                $UTCSHIFTH = "$LocShiftTab[0]1" * ($TZHour + ($TZMin/60));
                $ReturnDatePrint = "$WDay, $Day-$MonthsName[$Month-1]-$Year $Hour:$Minute:$Sec";
        }
        my $TimeZoneName = '';
        if ($UTCSHIFTH == 0) { $TimeZoneName = "(UTC)"; }
        if ($UTCSHIFTH < 0)  { $TimeZoneName = "(UTC$UTCSHIFTH)"; }
        if ($UTCSHIFTH > 0)  { $TimeZoneName = "(UTC+$UTCSHIFTH)"; }
        $ReturnDatePrint .= "  $TimeZoneName";
        return $ReturnDatePrint;
}
#
# Adding one email
# -----------------
# This will add one email to the body of the "main", temporary file
#
sub SCallsAddOneEmail {
        my($SCallsNameEmail,$SCallsNoEmail) = @_;
        my $INTERLINE = '--------------------------------------------';
        my @EMAILTEXT = ();
        my $EMAILDATE = '';
        my $EMAILBODY = '';
        my $EMailDatePrint = '';  my $file = '';  my $i = 0;
        chdir("$CURRENT_DIR_NEW/$SCallsNameEmail");
#
# Gathering content of the folder
        opendir(LocDIR,".") || die "Can't open $SCallsNameEmail directory.\n";
        my @EMailFilesTmpTab = grep {!/^\.+$/} readdir(LocDIR);
        closedir(LocDIR);
#
# Searching for the Email body...       
        foreach $file (@EMailFilesTmpTab) {
                if ((-T $file) && ($file =~ /^MailBody-.*\.txt$/)) {
                        push(@EMAILTEXT,$file);
                }
        }
#
# Get the time - for now the entire, last line from 'HeaderDetails.txt'
        $EMAILDATE = `tail -1 $EMAILHEADER`;
        chomp($EMAILDATE);
#
# Now, let's try to clean the date and reprint that in different way
        if ($EMAILDATE =~ /^Date.*$/) { # very simple check if the line is correct, that is contains a data
                my @EMailDateTemp = split(/\s+\:\s+/,$EMAILDATE);
                $EMailDatePrint = SCallsConvertAndReturnTime($EMailDateTemp[1]);
        }
        else {
                $EMailDatePrint = "No correct date found in the header, see below";
        }
#
# Part for Mail header starts here...
        if ((-e $EMAILHEADER) && (-T $EMAILHEADER)) {
                open(EMAILHEADER_H,"$EMAILHEADER");
#
# Two different fancy headers, depends if we create the file for clipboard or for displaying
                if ($CLIPBOARD) {
                        print MAINFILE_OUT "$DASHEDLINE\n"; }
                else {
                        print MAINFILE_OUT "ooo$SCallsNoEmail *** ShareCalls for SR# $CASE_NO : Email# $SCallsNoEmail ***\n";
                        print MAINFILE_OUT "$DASHEDLINE\n";
                        print MAINFILE_OUT "     $EMailDatePrint\n";
                        print MAINFILE_OUT "$DASHEDLINE\n";
                }
#
# Building the Mail header
                if ($DISPLAYHEA) {
                        while (<EMAILHEADER_H>) { # we will print all lines from the header, without the empty Cc... line
                                if ($_ !~ /^Cc.*:\s*$/) {
                                        print MAINFILE_OUT $_; 
                                }
                        }
                        close(EMAILHEADER_H);
                }
        }
        else {
                print MAINFILE_OUT "$DASHEDLINE\n";
                print MAINFILE_OUT "Couldn't find necessary file or file are not valid for Header,\n in the folder: $SCallsNameEmail\n";
                print MAINFILE_OUT "$DASHEDLINE\n";
                print MAINFILE_OUT "\n\n";
        }
#
# Space between headers and bodies
        if ($DISPLAYHEA && $DISPLAYBOD) {
                print MAINFILE_OUT "\n\n";
        }
#
# Building the Mail body(-ies)
        if ($DISPLAYBOD) {
        foreach $file (@EMAILTEXT) {
                open(EMAILBODY_H,"$file");
                if ($LINESALL) {
                        while (<EMAILBODY_H>)
                                { $_ =~ s/\015//; # removes ^M, added in v1.03
                                        print MAINFILE_OUT $_; }
                }
                if ($LINESEMPTY) {
                        while (<EMAILBODY_H>) {
                                if ($_ !~ /^\s*$/) {
                                        $_ =~ s/\015//; # removes ^M, added in v1.03
                                        print MAINFILE_OUT $_; }
                        }
                }
                if ($LINESSMART) {
                        SCallsSmartLines(EMAILBODY_H,MAINFILE_OUT);
                }
                if ($i<$#EMAILTEXT) {
                        print MAINFILE_OUT "\n$INTERLINE\n\n";
                }
                close(EMAILBODY_H);
                $i++;
        }
        }
        print MAINFILE_OUT "\n$DASHEDLINE\n\n";
        chdir("$CURRENT_DIR_NEW");
}
#
# Searching for text files and copy them
# --------------------------------------
# This function will search for any extra text files and it will copy them to the auxiliary folder on SCalls
# This is kind of experimental function
#
sub SCallsExtractAndCopyFiles {
        chdir("$CURRENT_DIR_NEW");
        my $NAMEOFFOLDER = "Text-files";
        my $FolderCreated = 0; # just a why to check if the folder has been created
        my %ListOfFiles = ();  # this is for store the counters for each filenames (in case we have more files named the same)
        my $EMailFilesTmp = '';
        my @EMailFilesTmpTab = ();
        my $file = '';  my $file_copy = '';  my $i = '';
#
# Now we iterate through the INDEX table
        foreach $i (@INDEX) {
                chdir("$CURRENT_DIR_NEW/$ListOfEMails[$i-1]");
                opendir(LocDIR,".") || die "Can't open email directory no $i.\n";
                @EMailFilesTmpTab = grep {!/^\.+$/} readdir(LocDIR);
                closedir(LocDIR);
#
# searching for the text files...       
                foreach $file (@EMailFilesTmpTab) {
                        if ((-e $file) && (-T $file) && ($file !~ /^MailBody-.*\.txt$/) &&
          ($file !~ /^HeaderDetails.txt$/) && ($file !~ /^MailBody-.*\.html$/)) {
                                $file_copy = $file;
                                $file_copy =~ s/\s+/\_/g;  # replacing whitespace with '_'
                                if (exists $ListOfFiles{$file}) { $ListOfFiles{$file} += 1;     }
                                else { $ListOfFiles{$file} = 1; }
                                if (!$FolderCreated) { # we create the folder if this doesn't exisits
                                        if (!-e "$CURRENT_DIR_NEW/$NAMEOFFOLDER") {
                                                system("mkdir $CURRENT_DIR_NEW/$NAMEOFFOLDER"); }
                                        $FolderCreated = 1;
                                }
                                if ($ListOfFiles{$file} > 1) {
                                        system("cp \"$file\" $CURRENT_DIR_NEW/$NAMEOFFOLDER/$file_copy-$ListOfFiles{$file}");
                                }
                                else {
                                        system("cp \"$file\" $CURRENT_DIR_NEW/$NAMEOFFOLDER/$file_copy");
                                }
                        }
                }
        }
        chdir("$CURRENT_DIR_NEW");
}
#
# SCallsHelp - Help Messaage
# ---------------------------
#
sub SCallsHelp {
$HelpMsg=<<_BOT_;
    Perl script 'SCalls'
  ------------------------
  This is a simple, Perl script for displaying all emails from case's folder on Cores2 in the row, using 'less'
  or similar command.
  The script simply puts all emails with their headers and adds some fancy dashed lines, numbers, etc.
  The script can work also on single file given to perform some simple, text based operations.
  Please check the description below for all options available so far.

  USAGE
    SCalls [<Options>] [<Emails_range>]
    SCalls <Option_for_singlefile> <File_name> [-g <Output_name>]

  ARGUMENTS
    <Emails_range> : The range of emails to be displayed, to be given by emails' numbers in comma-separated list.
                     Email no 1 is the first, oldest email sent to sharecalls. Emails numbers can be given this way:
                     - by single integers (ie. 1,2,5),
                     - by interval with both borders 'i-j' (ie. 2-5  - this means 2,3,4,5),
                     - by interval with right border given '-j' (ie. -4  - this means 1,2,3,4),
                     - by interval with left border given 'i-' (ie. 2-  - this means 2,3,...,<Last_email_no>).
                     If no <Emails range> is given, then the default range is:  1,2,...,<Last_email_no>.
                     If there are more then one <Emails_range> given (they are separated by white spaces) only LAST is used.
                     Any emails' numbers that are out of the emails max count will be removed from the list.

    <Options>      : Options available are described below. Options and Emails range can be mixed in any order.
    <Option_for_singlefile> : The script can work also on single file '<File_name>' to perform some simple,
                              text based operations. See the section 'OPTIONS FOR SINGLE FILE' for the full list.
    <File_name>    : The name of the file given as argument for any of options from 'OPTIONS FOR SINGLE FILE' list.
    <Output_name>  : Optional output file name that can be added here.

  OPTIONS
    -a, --asc
      Sort and display all emails in ascending order (the oldest emails first). This is the default sort order.

    -b, --body
      Display only the bodies of all emails (negation of the '-i' option).

    -c, --clip
      *Experimental option*. Build a temp file with emails from the Emails range requested, but instead of displaying it,
      it will copy the file's content to the clipboard using the command 'xclip'
      (The command 'xclip' can be found as source package:
        http://sourceforge.net/projects/xclip/
      and compile with 'gcc' (simply './configure', 'make', 'make install')).
      !!! It will NOT work on Cores2 server, as when running 'ssh' session there is no simple access to the clipboard. !!!

    -d, --desc
      Sort and display all emails in descending order (the newest emails first).

    -e, --empty
      Do not display 'empty' lines (that contain only whitespaces) from the email bodies.
      This can be useful to clear some outputs pasted into mail body. But, please be careful with this option -
      it can disturb emails' sense and reading. If you would like to filter just messages pasted to the email's body,
      then it's better to use 'fixmail' script of Doug Baker.

    -f [<n>], --fend [<n>]
      Print only one email with the number <n> but counting from the end (from the newest email).
      The default value is 1 (so only last email - the same effect as '-l' option).

    -g [<Output_name>], --generate [<Output_name>]
      Generate only the file '<Case_number>_Email-Temp_<Date_and_Time>.txt' without displaying it using 'less' command.
      This file name can be changed by giving the optional string '<Output_name>'.

    -h, --help
      Print this short help messages.

    -i, --header
      Display only the headers of all emails (negation of the '-b' option).

    -l [<n>], --last [<n>]
      Display last <n> emails in descending order, by default.
      The <n> is optional, the default value is 1 (so only one last email).

    -n, --notrem
      Do not remove the temporary text file with emails, it will be available as:
      '<Case number>_Email-Temp_<Date and Time>.txt'.

    -o, --old
      Search for emails in all subfolders (of all levels of depth) of the case folder.
      Only folders that contain 'explorer' or 'guds' in their names are omitted.
      The script will sort all folders with emails found (by default, only the emails found in <Case number>
      directory are taken into consideration).

    -r, --reverse
      Reverse the given emails' order.

    -s, --smart
      Remove some empty lines in email bodies, exactly the same, "smart" way as in the option '-k' described below.

    -u [<Value_of_UTC_offset>], --utc [<Value_of_UTC_offset>]
      Print the timestamps for each lines using the converted time to 'UTC+<Value_of_UTC_offset>'.
      The default value of '<Value_of_UTC_offset>' is 0 and can be a real number (so it will print time converted to UTC+0).
      Without this option (so by default) the timestamp is taken from the header file without any conversion.

    -x, --extract
      *Experimental option*. It will check all emails' folders from the [<Emails_range>] given and will copy
      all text files found to the folder called '<Cores2_folder>/Text-files/'. Perl is trying to perform
      some heuristic guess to find ASCII text files, so the result may by inaccurate as well. If there are more then
      one files found with the same name, the next will have '-<counter>' added the its names (ie. -2, -3).
      Whitespaces in filenames are replaced by '_' in the copy files.


  OPTIONS FOR SINGLE FILE
    -k <File_name>, --file <File_name>
      *Additional option*. This will not display any emails, it takes just one file '<File_name>' (mandatory here) and
      it will generate the file: '<File_name>_fix', where empty lines are removed but in some "smart" way.
      This will remove some of empty lines depends how many of there are in one group (next to each other).
      There are following rules:
      - one empty line is removed,
      - two empty lines next to each other are compressed to one,
      - three or more empty lines next to each other are compressed to two.
      This is the slowest option for removing empty lines.
      The option '-g <Output_name>' will work as expected - so, the output file will have the name: <Output_name>.
      (The empty line means the lines consists of whitespaces only.)

    --lastline
      Extra option that can be combined with '-m, --messages' or with '-p, --messagsp'.
      By default the above options will not print the last line that match the messages' line pattern.
      To print such line this options needs to be added.

    -m <File_name>, --messages <File_name>
      This option will extract and unwrap messages lines from the file '<File_name>' given and it will save the output
      under the name '<File_name>_fix'.
      The algorithm and functionality is taken from the script 'fixmail' of Doug Baker. The effect of this option will be
      the same as for 'fixmail -n' (note the option '-n' here).
      The option '-g <Output_name>' if present, will generate the output file '<Output_name>' instead of '<File_name>_fix'.
      Remark: The method used in this script will not print the last line that match the messages' line. To print such line
      the option '--lastline' should be added. See also the option '-p, --messagsp'.

    -p <File_name>, --messagsp <File_name>
      The option similar to '-m, --messages', so it will extract and unwrap messages lines from the file given as argument.
      But, the extra space will be added to the end of each part of messages' line. This is the same as when using 'fixmail'
      of Doug Baker (with no extra options).
      The option '-g <Output_name>' can be used to change the output file to '<Output_name>' instead of '<File_name>_fix'.
      Remark: The method used in this script will not print the last line that match the messages' line. To print such line
      the option '--lastline' should be added.

    -q <File_name>, --rmquotes <File_name>
       This will remove the quote chars '>' from the begins of the lines (one or multiple, also separated by whitespaces).
       Also it will remove timestamps like '<Date>' that are added by some terminal servers or console loggers.
       The option '-g <Output_name>' can be used to change the output file to '<Output_name>' instead of '<File_name>_fix'.


  REMARKS
    - The script's name can be changed to something shorter and placed in the folder from your \$PATH variable
      (or you can create some symbolic link to that file),
    - The script uses 'less' by default, if you want to use any other command (like 'more' or 'cat').
      you need to change that in the script by yourself ;-) (line no 56, value of '\$DISPLAY_COMMAND').
    - When displaying all emails using 'less' command, you can run search for the string 'ooo' (using [/] key).
      Then by pressing [n]/[Shift-n] keys you can move quickly to the next/previous email (simple workaround... ;-)).
    - Any comments, bugs - please send them on the email: rafal.czarny\@oracle.com
      Many thanks! :-)

  -----------------------------
  2010/12/14, v1.21
  (c) 2009-2010 by Rafal Czarny
_BOT_
        print $HelpMsg;
}
#
#
#
#---------------------------------------------------------------------#
#                               CHANGES
#---------------------------------------------------------------------#
# *** 2010/12/14, v1.21 ***
#   - Adapted the script to the ISP/MOS case numbers ('d-dddddddddd' or 'd-ddddddd')
#
#
# *** 2010/09/26, v1.20 ***
#   - added options '-m', '-p', '--lastline' (same functionality as 'fixmail' of Doug Baker) and '-q',
#   - option '-g <Output_name>' will work also with the above options as expected,
#   - some code and help documentation changes made due to the new options added.
#
# *** 2010/05/12, v1.11 ***
#   - added timezone stamp for all emails, even if the option '-u' is not used.
#
# *** 2010/05/11, v1.10 ***
#   - added option '-u <time_offset>' for converting the time to the given timezone.
#
# *** 2010/05/09, v1.06 ***
#   - added two extra options, '-b' and '-i' to display respectively bodies and headers of the emails.
#
# *** 2010/02/14, v1.05 ***
#   - added the optional string for the option '-g', that allows to provide file name of generated file.
#
# *** 2010/01/10, v1.04 ***
#   - changed the name of file (adding current number on the beginnig) generated when it's not removed.
#
# *** 2010/01/06, v1.03 ***
#   - added removing of '^M' signs to emails' displaying ($_ =~ s/\015//;).
#
# *** 2009/12/21, v1.02 ***
#   - changed gathering folders' content to sequence 'opendir/readdir/closedir'
#     (to allow gathering folders names with whitespaces).
#
# *** 2009/12/14, v1.00 ***
#   - added the option '-o, --old'
#     (official changes' tracking starts here).
#
#
#---------------------------------------------------------------------#
#=====================================================================#
#
# (c) 2009-2010 by Rafal Czarny
