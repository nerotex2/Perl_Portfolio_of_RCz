#! /usr/bin/perl
#======================================================================#
#                           GridExpSlave.pl
#                         --------------------
#   date        : 30/09/2004,  ver. 1.00
#   copyright   : (c) 2004 by Rafal Czarny
#   university  : Universite de Technologie de Compiegne
#   email       : Rafal.Czarny@utc.fr
#----------------------------------------------------------------------#
# 
#  Script esclave, qui est lancé par le script maître GridExp 
#  sur les machines cibles (version généralisé)
#
#======================================================================#

# Arguments d'entrée:

$Node    = $ARGV[0];   # nom du noud de calcul sur lequel on exécute l'expérience
$Exper   = $ARGV[1];   # numéro d'expérience
$LineDOE = "$ARGV[2] $ARGV[3] $ARGV[4]";  # des valeurs de chargements
$Flaga   = $ARGV[5];   # string racine de fichier marquant le noued disponible
$MainStr = $ARGV[6];   # string indiquant des fichiers output
$DirHome = $ARGV[7];   # repertoire pour fichier scripts et autres
$DirDOE = $ARGV[8];    # répertoire de fichiers résultats
$MainExe = $ARGV[9];   # executable pour le program 'feap'
$FileTmp = $ARGV[10];  # Fichier paramétré des données (fichier modèle)
$MAX_POINTS = $ARGV[11]; # nombres des points du maillage
$MAX_ELEM = $ARGV[12]; # nombres des elements dans un modele

$NameFileRaport = $DirDOE.$MainStr."Raport.dat";        # nom du fichier avec rapport
$NameFileInput=$MainStr."N".$Node;                      # nom du fichier de données local sur le noeud
$NameFileOutDepl=$DirDOE.$MainStr."_".$Exper."_U.dat";  # fichier out pour l'expérience courante (deplacement)
$NameFileOutStres=$DirDOE.$MainStr."_".$Exper."_S.dat"; # fichier out pour l'expérience courante (stress)
&FeapNewFileForce($LineDOE,$DirHome."I".$NameFileInput,$DirHome.$FileTmp); # on creer fichier-model avec chargements
print  "Start experiment no  ".$Exper."   noeud: ".$Node."\n"; # message sur la console
system("cd $DirHome; $MainExe >trash < $NameFileInput"); # on lance l'expérience
$NameFileFeap=$DirHome."O".$MainStr."N".$Node;           # fichier pour résultats filtrés

# filtrage du fichier résultats
print "     Fin experiment no: ".$Exper."  noeud no ".$Node."\n";  # message sur la console
$ActualConv = &FeapReadDeplacement($NameFileFeap,$NameFileOutDepl,"N o d a l   D i s p l a c e m e n t s","5 6 7","",$MAX_POINTS);
#  &FeapReadDeplacement($NameFileFeap,$NameFileOutStres,"Element Stresses","3 4 5 6 7 8","1 2 3",$MAX_ELEM);
print "     Enregistre experiment no ".$Exper."\n";
&FeapSaveLineRaport($NameFileRaport,$Exper,$ActualConv);
system("cd $DirHome; touch $DirHome.$Flaga");                     # marquage du noud comme disponible

#----------------#
#  Filtrage de fichier output de FEAP - extraction des déplacements des nouds
#  Input: (fichier output de FEAP,
#          nom de fichier a créer,
#          chaîne a chercher,
#          numéros des éléments à sauver entre une ligne ($WhatToWrite),
#          nombre d'éléments à sauver)

sub FeapReadDeplacement
{
    my($FileIn,$FileOut,$String,$WhatToWrite,$WhatToWriteII,$MaxElements) = @_;
    my $CntLines=1;
    my $Convergence=1;
    my @INDEX = split(/\s+/,$WhatToWrite);
    my @INDEXII = split(/\s+/,$WhatToWriteII);
    open(FILE_IN,$FileIn);
		open(FILE_OUT,">".$FileOut);
    while ($ReadLine = <FILE_IN>)           # on lit des lignes du fichier input
    { if ($ReadLine =~ m/.*$String.*/)      # si ligne contient le string qu'on cherche
      { while ($ReadLineII = <FILE_IN>)     # on lit des lignes suivantes...
        { chomp($ReadLineII);
	        if ($ReadLineII)
    	    { @ReadLineTemp = split(/\s+/,$ReadLineII); # on divise sur des blancs
    	      if (($ReadLineTemp[1] =~ m/[0-9]+/) && ($ReadLineTemp[1] !~ m/[a-z]+/))
	          { if ($ReadLineTemp[1] == $CntLines && $ReadLineTemp[1] <= $MaxElements)
     	        { foreach $local_ind (@INDEX)  # on ecrit dans le fichier de donnes selon "$WhatToWrite"
		            { print FILE_OUT $ReadLineTemp[$local_ind],"    "; }
		            $ReadLineIII = <FILE_IN>;   chomp($ReadLineIII);
							  if ($ReadLineIII)
                { @ReadLineTempII = split(/\s+/,$ReadLineIII); # on divise sur des blancs
		              if ($ReadLineTempII[1] =~ m/[0-9]+[E]/)
              	  { foreach $local_indII (@INDEXII)
		                { print FILE_OUT $ReadLineTempII[$local_indII],"    "; }
										print FILE_OUT "\n";   $CntLines++;
 	                } else { print FILE_OUT "\n";   $CntLines++; }
    	          } else { print FILE_OUT "\n";   $CntLines++; }
	            }
            }
          }
        }
      }
      if ($ReadLine =~ /.*NO CONVERGENCE.*/)  { $Convergence = 0; }
    }
    close(FILE_OUT);
    close(FILE_IN);
    return $Convergence;
}

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
#  Procédure pour remplacer dans le fichier modèle des strings des type $$[<i>]$$, <i>=1,2,3
#  Input: Ligne d'un file

sub FeapSaveLineRaport
{
  my($NameFileRaport,$Experiment,$Convergence) = @_;
  open(FILE_RAPORT,">>$NameFileRaport");
  print FILE_RAPORT "=== Experiment:  $Experiment, Convergence:  ";
  if ($Convergence)
  { print FILE_RAPORT " OK\n"; }
  else
  { print FILE_RAPORT " !ERROR!\n"; }
  close(FILE_RAPORT);
}

#======================================================================#
# Rafal CZARNY
# (c) 2004