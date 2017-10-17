#! /usr/bin/perl
#======================================================================#
#                             GridInput.pl
#                         --------------------
#   date        : 30/09/2004,  ver. 1.00
#   copyright   : (c) 2004 by Rafal Czarny
#   university  : Universite de Technologie de Compiegne
#   email       : Rafal.Czarny@utc.fr
#----------------------------------------------------------------------#
#   Noms des fichiers et des chaînes utilises dans les scripts (Exp et ExpSlave)
#   Dans toutes les lignes on n'enleve pas des chaines #(  !!!
#
#======================================================================#

DOETemp_5x5x5 #(1) Plan d'expériences
I3DoeTmp      #(2) Fichier paramétré des données (fichier modèle)
NodesConfig   #(3) Configuration de la machine virtuelle
Flag          #(4) string racine du nom de fichier indiquant disponibilite du noeud <i>
doe           #(5) string pour générer les noms de fichiers
/home/czarnyra/bin/feap       #(6) executable pour le program 'feap'
/home/czarnyra/FEAP/          #(7) repertoire pour fichier scripts et autres
/home/czarnyra/FEAP/DeplPom/  #(8) répertoire de fichiers résultats
275           #(9) nombres des points du maillage
160           #(10) nombres des elements

#======================================================================#
# Rafal CZARNY
# (c) 2004