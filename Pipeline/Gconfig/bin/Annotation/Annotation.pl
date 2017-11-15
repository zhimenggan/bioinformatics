#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fIn,$dOut,$Split,$fType,$Database,$Key);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
my ($NR,$NT,$KEGG,$GO,$EggNOG,$Swissprot);
GetOptions(
	"help|?" =>\&USAGE,
	"i:s"=>\$fIn,
	"t:s"=>\$fType,
	"o:s"=>\$dOut,
	"k:s"=>\$Key,
	"n:s"=>\$Split,
	"NR"=>\$NR,
	"NT"=>\$NT,
	"KEGG"=>\$KEGG,
	"GO"=>\$GO,
	"EggNOG"=>\$EggNOG,
	"Swissprot"=>\$Swissprot,
			) or &USAGE;
&USAGE unless ($fIn and $dOut and $Key);
$Split||=50;
$NR||=1;
$NT||=0;
$KEGG||=1;
$GO||=1;
$EggNOG||=1;
$Swissprot||=1;
$Database||="";
$fType||="nuc";
my $dNR=" /mnt/ilustre/users/long.huang/DataBase/NR/2017-8-30/nr";
my $dNT="/mnt/ilustre/users/long.huang/DataBase/NT/nt";
my $dKEGG="/mnt/ilustre/users/dna/Environment/biotools/kobas-3.0/seq_pep/ko.pep.fasta ";
my $dGO="/mnt/ilustre/users/long.huang/DataBase/GO/go_weekly-seqdb.fasta";
my $dEggNOG="/mnt/ilustre/users/long.huang/DataBase/EggNOG/new/eggnog4.proteins.all.fa";
my $dSwissprot="/mnt/ilustre/users/long.huang/DataBase/Swissprot/uniref90.fasta";
my $blastp="/mnt/ilustre/users/dna/.env//bin/diamond blastp ";
my $blastx="/mnt/ilustre/users/dna/.env//bin/diamond blastx ";

$fIn=Cwd::abs_path($fIn);
mkdir $dOut if (!-d $dOut);
$dOut=Cwd::abs_path($dOut);
mkdir "$dOut/split" if (!-d "$dOut/split");
mkdir "$dOut/worksh" if (!-d "$dOut/worksh");
mkdir "$dOut/blast" if (!-d "$dOut/blast");
mkdir "$dOut/result"if (!-d "$dOut/result");
# export  LD_LIBRARY_PATH=/mnt/ilustre/app/pub/lib/:/mnt/ilustre/app/pub/lib64/   
open Log,">$dOut/$Key.Annotation.log";
my $STEP=0;
if ($STEP == 0) {
	print Log "step1: split fasta into $Split sub files";
	my $job="perl $Bin/bin/splitFasta.pl -i $fIn -o $dOut/split -k $Key -n $Split";
	open SH,">$dOut/worksh/step1.sh";
	print SH $job," &&\n";
	close SH;
	$job="perl /mnt/ilustre/users/dna/.env//bin/qsub-sge.pl  $dOut/worksh/step1.sh";
	print Log "$job\n";
	my $return=`$job`;die "$job" if ($return !~ /Done/);
	print Log "$job\tdone!\n";
	$STEP++;
}
if ($STEP == 1) {
	print Log "step2: blast fasta to All Database";
	my @fasta=glob("$dOut/split/*.fa");
	open BLAST,">$dOut/worksh/step2.blast.sh";
	open NR,">$dOut/worksh/step2.nr.sh";
	foreach my $fa (@fasta) {
		my $fname=basename($fa);
		if ($NR) {
			my $blast;
			if ($fType eq "nuc") {
				$blast=$blastx;	
			}else{
				$blast=$blastp;
			}
#			print NR "export  LD_LIBRARY_PATH=/mnt/ilustre/app/pub/lib/:/mnt/ilustre/app/pub/lib64/:\$LD_LIBRARY_PATH && ";
			print NR "$blast --db $dNR --query $fa --evalue 10e-10 --outfmt 5 --threads 8 --out $dOut/blast/$fname.nr.blast && ";
			print NR "perl $Bin/bin/blast_result.pl -i $dOut/blast/$fname.nr.blast -o $dOut/blast/$fname.nr.blast.best && \n";
		}
		if ($KEGG) {
			my $blast;
			if ($fType eq "nuc") {
				$blast=$blastx;	
			}else{
				$blast=$blastp;
			}
#			print BLAST "export  LD_LIBRARY_PATH=/mnt/ilustre/app/pub/lib/:/mnt/ilustre/app/pub/lib64/:/mnt/ilustre/app/pub/python-2.7.10-new/lib/:\$LD_LIBRARY_PATH && ";
			print BLAST "$blast --query $fa --db $dKEGG --out $dOut/blast/$fname.kegg.blast --evalue 10e-10 --outfmt 6 --threads 8 && ";
#			print BLAST "export PYTHONPATH=\$PYTHONPATH:/mnt/ilustre/app/rna/sequence_tool/RSeQC-2.6.3/lib:/mnt/ilustre/app/zhuohao/software/kobas2.0/20150126/src:/mnt/ilustre/users/bingxu.liu/workspace/annotation/kobas/kobas2/src:/mnt/ilustre/app/rna/function_enrichment/goatools-master/build/lib/goatools && ";
			print BLAST "export PYTHONPATH=/mnt/ilustre/users/dna/.env/lib/python2.7/site-packages:/mnt/ilustre/users/dna/Environment/biotools/kobas-3.0/src/ && cp ~dna/.kobasrc ~/ && /mnt/ilustre/users/dna/.env/bin/python /mnt/ilustre/users/dna/Environment/biotools/kobas-3.0/scripts/annotate.py -i $dOut/blast/$fname.kegg.blast -t blastout:tab -s ko -o $dOut/blast/$fname.kegg.kobas &&\n";
		}
		if ($Swissprot) {
			my $blast;
			if ($fType eq "nuc") {
				$blast=$blastx;	
			}else{
				$blast=$blastp;
			}

#			print BLAST "export  LD_LIBRARY_PATH=/mnt/ilustre/app/pub/lib/:/mnt/ilustre/app/pub/lib64/:\$LD_LIBRARY_PATH && ";
			#print BLAST "$blast -query $fa -db $dSwissprot -out $dOut/blast/$fname.swissprot.blast -evalue 10e-10 -outfmt 5 -num_threads 8 && ";
			print BLAST "$blast --query $fa --db $dSwissprot --out $dOut/blast/$fname.swissprot.blast --evalue 10e-10 --outfmt 5 --threads 8 &&";
			print BLAST "perl $Bin/bin/blast_result.pl -i $dOut/blast/$fname.swissprot.blast -o $dOut/blast/$fname.swissprot.blast.best &&\n";
		}
		if ($EggNOG) {
			my $blast;
			if ($fType eq "nuc") {
				$blast=$blastx;	
			}else{
				$blast=$blastp;
			}
#			print BLAST "export  LD_LIBRARY_PATH=/mnt/ilustre/app/pub/lib/:/mnt/ilustre/app/pub/lib64/:\$LD_LIBRARY_PATH && ";
#			print BLAST "$blast -query $fa -db $dEggNOG -out $dOut/blast/$fname.eggNog.blast -evalue 10e-10 -outfmt 5 -num_threads 8 && ";
			print BLAST "$blast --query $fa --db $dEggNOG --out $dOut/blast/$fname.eggNog.blast --evalue 10e-10 --outfmt 5 --threads 8 && ";
			print BLAST "perl $Bin/bin/blast_result.pl -i $dOut/blast/$fname.eggNog.blast -o $dOut/blast/$fname.eggNog.blast.best &&\n";
		}
		if ($GO) {
			my $blast;
			if ($fType eq "nuc") {
				$blast=$blastx; 
			}else{
				$blast=$blastp;
			}
#			print BLAST "export  LD_LIBRARY_PATH=/mnt/ilustre/app/pub/lib/:/mnt/ilustre/app/pub/lib64/:\$LD_LIBRARY_PATH && ";
			print BLAST "$blast --query $fa --db $dGO --out $dOut/blast/$fname.GO.blast --evalue 10e-10 --outfmt 5 --threads 8 && ";
			print BLAST "perl $Bin/bin/blast_result.pl -i $dOut/blast/$fname.GO.blast -o $dOut/blast/$fname.GO.blast.best &&\n";
        }           
	}
	close BLAST;
		print Log "NT database Start!";
		my	$job="perl /mnt/ilustre/users/dna/.env//bin/qsub-sge.pl $dOut/worksh/step2.blast.sh --Resource mem=20G --CPU 8&";
		print Log "$job\n";
		my $return=`$job`;	die "$job" if ($return !~ /Done/);
		print Log "$job\tdone!\n\n";

		print Log "NT database Start!";
		$job="perl /mnt/ilustre/users/dna/.env//bin/qsub-sge.pl  $dOut/worksh/step2.nr.sh --Resource mem=30G --CPU 8&";
		print Log "$job\n";
		$return=`$job`;	die "$job" if ($return !~ /Done/);
		print Log "$job\tdone!\n\n";

	$STEP++;
}
if ($STEP == 2) {
	my @go=glob("$dOut/blast/*.GO.*.best");
	my @nr=glob("$dOut/blast/*.nr.*.best");
	my @kegg=glob("$dOut/blast/*.kegg.*.best");
	my @eggnog=glob("$dOut/blast/*.eggNog.*.best");
	my @swissprot=glob("$dOut/blast/*.swissprot.*.best");
	open SH,">$dOut/worksh/step3.sh";
	print SH "cat ".join(" ",@nr)." > $dOut/result/$Key.nr.blast && perl $Bin/bin/NRanno.pl -i $dOut/result/$Key.nr.blast -o $dOut/result/$Key.nr.anno\n" if($NR);
   	print SH "perl $Bin/bin/KEGGanno.pl -i $dOut/blast/ -o $dOut/result/$Key.kegg.anno\n" if ($KEGG);
	print SH "cat ".join(" ",@eggnog)." > $dOut/result/$Key.eggnog.blast && perl $Bin/bin/EggNogAnno.pl -i $dOut/result/$Key.eggnog.blast -o $dOut/result/$Key.eggnog.anno\n" if ($EggNOG);
	print SH "cat ".join(" ",@swissprot)." > $dOut/result/$Key.swissprot.blast && perl $Bin/bin/UniprotAnno.pl -i $dOut/result/$Key.swissprot.blast -o $dOut/result/$Key.swissprot.anno\n" if ($Swissprot);
	print SH "cat ".join(" ",@go)." > $dOut/result/$Key.go.blast && perl $Bin/bin/GOanno.pl -i $dOut/result/$Key.go.blast -o $dOut/result/$Key.go.anno\n" if ($GO);
	close SH;
	my $job="perl /mnt/ilustre/users/dna/.env//bin/qsub-sge.pl  $dOut/worksh/step3.sh";
	print Log "$job\n";
	my $return=`$job`;	die "$job" if ($return !~ /Done/);
	print Log "$job\tdone!\n";
	$STEP++;
}
if ($STEP == 3) {
	open SH,">$dOut/worksh/step4.sh";
	print SH "perl $Bin/bin/merge_result.pl -i $dOut/result/ -o $dOut/$Key.summary.result -g $fIn";
	close SH;
	my $job="perl /mnt/ilustre/users/dna/.env//bin/qsub-sge.pl  $dOut/worksh/step4.sh";
	print Log "$job\n";
	my $return=`$job`;	die "$job" if ($return !~ /Done/);
	print Log "$job\tdone!\n";
}

close Log;

#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub USAGE {#
        my $usage=<<"USAGE";
Contact:        long.huang\@majorbio.com;
Script:			$Script
Description:
	this Script will split fasta file as 2000 sequence in a file and make a shell for qsub
	
	if you give a new database,this script will only blast to your annotation

	note: diamond instead of blast

	eg:
	perl $Script -i demo.fa -d Nr -o ./ -k demo

Usage:
  Options:
  -i	<file>	input fa file name
  -t	<str>	fasta file type [nuc] or [pro],default nuc
  -d	<file>	intput a database file name instead of "Nr:Nt:Kegg:Go:Swissprot:EggNOG";
	-NR
	-KEGG
	-GO
	-EggNOG
	-Swissprot
  -o	<dir>	output dir 
  -k	<str>	output keys of filename
  -n	<num>	split number default 50
  -h         Help

USAGE
        print $usage;
        exit;
}
