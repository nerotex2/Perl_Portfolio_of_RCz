#! /usr/bin/perl
#======================================================================#
#                              GridExp.pl
#                         --------------------
#   date        : 30/09/2004,  ver. 1.00
#   copyright   : (c) 2004 by Rafal Czarny
#   university  : Universite de Technologie de Compiegne
#   email       : Rafal.Czarny@utc.fr
#----------------------------------------------------------------------#
#
#  Calcul parallèle d'un plan d'expériences sur une machine virtuelle
#
#======================================================================#


print "============== Campagne experimentale, executable: FEAP, plan: DOETemp ==============\n";

#  On lit des constants pour deux scripts

$CntLine=0;
open(FILE_DEF,'GridInput.pl');
while ($LineInput = <FILE_DEF>)
{  if ($LineInput =~ m/.*\#\(.*/)
   {  $CntLine++;
      @TabInput = split(/\s+/,$LineInput);
      if ($CntLine == 1) { $FileDOE = $TabInput[0]; }
      if ($CntLine == 2) { $FileTmp = $TabInput[0]; }
      if ($CntLine == 3) { $FileHosts = $TabInput[0]; }
      if ($CntLine == 4) { $StrFlag = $TabInput[0]; }
      if ($CntLine == 5) { $MainStr = $TabInput[0]; }
      if ($CntLine == 6) { $MainExe = $TabInput[0]; }
      if ($CntLine == 7) { $DirHome = $TabInput[0]; }
      if ($CntLine == 8) { $DirDOE = $TabInput[0]; }
      if ($CntLine == 9) { $MaxPoints = $TabInput[0]; }
      if ($CntLine == 10) { $MaxElem = $TabInput[0]; }
   }
}

close(FILE_DEF);

#
#  on place les noms des nouds constituant la machine virtuelle dans un tableau
#
open(FILE_HOSTS,$FileHosts);
while ($HostLine = <FILE_HOSTS>)
{
  chomp($HostLine);
  push(@TABHOSTS,$HostLine);
}
close(FILE_HOSTS);

# Definitions et declarations des tableaux

$MAX_IND_NODES=$#TABHOSTS;  # nombre des noeuds maximal
$#NAMES  = $MAX_IND_NODES;  # nomes des fichiers d'entrée passés à l'exécutable
$#FLAG   = $MAX_IND_NODES;  # fichiers dont la présence définit la disponibilité d'un noeud de calcul
$#FLAGIND = $MAX_IND_NODES;
$CntExp=0;

for ($i=0; $i<=$MAX_IND_NODES; $i++)
{
    $NAMES[$i] = $MainStr.'N'.$i;
    $FLAG[$i]  = $StrFlag.$i;
    $FLAGIND[$i] = 1;
}

#  Cree des fichiers d'entrée de nom doeN<i> avec noms des fichiers input, output, log etc.
#  Tous ces fichiers sont passés à l'exécutable (<i>  numéro du noud dans $FileHosts).

foreach $node (@NAMES)
{
    &FeapInputFile($node,$node);
}

# Boucle sur les expériences du plan, on lance le script esclave sur chaque noud de calcul

$not_lines=1;
$NameFileRaport = $DirDOE.$MainStr."Raport.dat";  # nom du fichier avec rapport
open(FILE_RAPORT,">>$NameFileRaport");
open(FILE_DOE,$FileDOE);  # ouverture du plan d'expériences

foreach $flag (@FLAG)
{
    system("touch $DirHome.$flag"); # on marque les nouds comme disponibles
}

$node=0;
print FILE_RAPORT "====== RAPPORT de CALCULS sur PILACD  ======\n\n";
$DateCalcul = `date`;
print FILE_RAPORT "Start calculs:  ".$DateCalcul."\n";

while ($LineDOE = <FILE_DOE>)   # boucle pour toutes les expériences
{   
  $CntExp++;
  $ExitWhile=1;
  chomp($LineDOE);
  while ($ExitWhile)
  {  $i=$node+1;
     $node = ($i % ($MAX_IND_NODES+1));    # on avance le numéro du noud
     if (-e "$DirHome.$FLAG[$node]")       # si le fichier-indicateur existe on lance des calculs
     { system("rm $DirHome.$FLAG[$node]"); # on marque le noud occupé
       $rshNode='rsh -n node'.$node;
# lancement du script esclave
       $NameScriptSlave="$DirHome"."GridExpSlave.pl";
       @TAB_ARGV = ($node,$CntExp,$LineDOE,$FLAG[$node],$MainStr,$DirHome,$DirDOE,$MainExe,$FileTmp,$MaxPoints,$MaxElem);
       system("$rshNode perl $NameScriptSlave @TAB_ARGV &");
       $ExitWhile=0;
     }
  }
}
close(FILE_DOE);    # fermeture du fichier du plan d'expériences
close(FILE_RAPORT);
print "                 ==============  F I N  ==============\n\n";

#----------------#
#  Procédure pour remplacer dans le fichier modèle des strings des type $$[<i>]$$, <i>=1,2,3
#  Input: (ligne d'un fichier avec des paramètres,
#          nom de fichier sortie,
#          nom de fichier modèle)

sub FeapNewFileForce
{
  my($LineForce,$NameFile,$FileTemplate) = @_;
  my $Localfx=0.0;
  my $Localfy=0.0;
  my $Localfz=0.0;

   ($Localfx,$Localfy,$Localfz) = split(/\s+/,$LineForce);
   open(FILE_TEMP,$FileTemplate);
   open(FILE_OUT,">".$NameFile);
   while ($OneLineFile = <FILE_TEMP>)
   { if ($OneLineFile =~ m/.*\$\$\[1\]\$\$/)
     { $OneLineFile = "fx = ".$Localfx."\n"; }
     if ($OneLineFile =~ m/.*\$\$\[2\]\$\$/)
     { $OneLineFile = "fy = ".$Localfy."\n"; }
     if ($OneLineFile =~ m/.*\$\$\[3\]\$\$/)
     { $OneLineFile = "fz = ".$Localfz."\n"; }
     print FILE_OUT $OneLineFile;
   }
   close(FILE_OUT);
   close(FILE_TEMP);
}

#----------------#
#  Procedure ou on cree un fichier d'entrée pour le logiciel FEAP
#  Input: (nom de fichier-input qu'on cree,
#          partie commune pour deux parties des ces fichiers)
#          I<...>, O<...>, L<...>, P<...>

sub FeapInputFile
{
    my($NameFileInput,$NameFile) = @_;
    my $NameFileOutLocal = ">".$NameFileInput;
    open(FILE_SCRIPT,$NameFileOutLocal);
    print FILE_SCRIPT "n\n";
    print FILE_SCRIPT "I",$NameFile,"\n";
    print FILE_SCRIPT "O",$NameFile,"\n";
    print FILE_SCRIPT "R",$NameFile,"\n";
    print FILE_SCRIPT "R",$NameFile,"\n";
    print FILE_SCRIPT "P",$NameFile,"\n";
    print FILE_SCRIPT "y\n";
    close(FILE_SCRIPT);
}

#----------------#
#  On lit des nombre qui est dernier dans une chaine contenant "$String"
#   Input: $InputFile : fichier-input
#          $String : quel chaine on cherche

sub FeapReadNumbers
{
    my($InputFile,$String) = @_;
    open(FILE_IN,$InputFile);
    while ($ReadLine = <FILE_IN>)
    { if ($ReadLine =~ /.*$String.*/)
      { chomp($ReadLine);
        @LineTemp = split(/\s+/,$ReadLine);
      }
    }
    close(FILE_IN);
    return $LineTemp[$#LineTemp];
}

#======================================================================#
# Rafal CZARNY
# (c) 2004