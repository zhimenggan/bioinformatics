#!/usr/bin/perl 
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $BEGIN_TIME=time();
my $version="1.0.0";
#######################################################################################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($vcflist,$dOut,$dShell,$ref,$indilist,$PID,$MID,$Pdep,$Odep,$Popt,$miss,$chitest);
GetOptions(
				"help|?" =>\&USAGE,
				"vcflist:s"=>\$vcflist,
				"ref:s"=>\$ref,
				"PID:s"=>\$PID,
				"MID:s"=>\$MID,
				"Pdep:s"=>\$Pdep,
				"Odep:s"=>\$Odep,
				"Popt:s"=>\$Popt,
				"miss:s"=>\$miss,
				"chi:s"=>\$chitest,
				"out:s"=>\$dOut,
				"dsh:s"=>\$dShell,
				) or &USAGE;
&USAGE unless ($vcflist and $ref and $dOut and $Popt);
$vcflist=ABSOLUTE_DIR($vcflist);
mkdir $dOut if (!-d $dOut);
mkdir $dShell if (!-d $dShell);
$dOut=ABSOLUTE_DIR($dOut);
$dShell=ABSOLUTE_DIR($dShell);
$Pdep||=10;
$Odep||=2;
$chitest||=0.05;
$miss||=0.3;
open SH,">$dShell/step00.variant-merge.sh";
if ($ref) {
	print SH "java -Xmx10G -jar /mnt/ilustre/users/dna/.env/bin/GenomeAnalysisTK.jar  -nt 8 -T CombineVariants -R $ref -V $vcflist -o $dOut/Total.merge.vcf --genotypemergeoption UNSORTED && ";
}else{
	open In,$vcflist;
	my @vcf;
	while (<In>) {
		chomp;
		next if ($_ eq "" ||/^$/);
		my ($id,$vcf)=split;
		print SH "ln -s $vcf $dOut/pop.merge.vcf && ";
		push @vcf,$vcf;
	}
	close In;
	if (scalar @vcf > 1) {
		die "Error no ref vcf files! only one!";
	}
}
print SH "perl $Bin/bin/vcf2marker.pl -i $dOut/pop.merge.vcf -o $dOut/Total.primary.marker -p $dOut/Total.primary.pos -PID $PID -MID $MID -Pdep $Pdep -Odep $Odep &&";
print SH "perl $Bin/bin/markerfilter.pl -i $dOut/Total.primary.marker -s $dOut/Total.marker.info -f $dOut/Total.filter.stat -g $dOut/Total.filtered.marker -p $Popt -seg $chitest -mis $miss -pos $dOut/Total.primary.pos -opos $dOut/Total.filtered.pos\n";
close SH;

my $job="perl /mnt/ilustre/users/dna/.env/bin/qsub-sge.pl  $dShell/step00.variant-merge.sh --Resource mem=10G --CPU 8";
`$job`;

#######################################################################################
print "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub ABSOLUTE_DIR #$pavfile=&ABSOLUTE_DIR($pavfile);
{
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir \n$in";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

sub USAGE {#
	my $usage=<<"USAGE";
Description: 
Version:  $Script
Contact: long.huang

Usage:
  Options:
	-vcflist	<file>	input vcf list
	-ref	<file>	ref fasta file option
	-Pdep	<num>	P M depth,default 10
	-Odep	<num>	offspring depth,default 2
	-Popt	<str>	population type default F2
					RIL/BC1
	-PID	<str>	Paternal ID
	-MID	<str>	Maternal ID
	-miss	<num>	miss default 0.3
	-chitest	<num> default 0.01
	-out	<dir>	output file dir
	-dsh	<dir>	output shell dir
USAGE
	print $usage;
	exit;
}