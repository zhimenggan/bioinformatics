#!/usr/bin/env perl 
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($proc,$gvcflist,$dOut,$dShell,$ref,$dict);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"gvcf:s"=>\$gvcflist,
	"ref:s"=>\$ref,
	"dict:s"=>\$dict,
	"out:s"=>\$dOut,
	"proc:s"=>\$proc,
	"dsh:s"=>\$dShell
			) or &USAGE;
&USAGE unless ($gvcflist and $dOut and $dShell and $dict);
$proc||=20;
mkdir $dOut if (!-d $dOut);
$dOut=ABSOLUTE_DIR($dOut);
$gvcflist=ABSOLUTE_DIR($gvcflist);
$ref=ABSOLUTE_DIR($ref);
$dict=ABSOLUTE_DIR($dict);
mkdir $dShell if (!-d $dShell);
$dShell=ABSOLUTE_DIR($dShell);
open In,$gvcflist;
open Out,">$dOut/gvcf.list";
while (<In>) {
	chomp;
	next if ($_ eq ""||/^$/);
	my ($id,$vcf)=split(/\s+/,$_);
	if (!-f $vcf ||!-f "$vcf.idx") {
		die "check $vcf!";
	}else{
		print Out $vcf,"\n";
	}
}
close In;
close Out;
open SH,">$dShell/08-1.gvcf-typing.sh";
open List,">$dOut/sub.vcf.list";
open In,$dict;
my %hand;
my $nchr=0;
my  $vcfs;
while (<In>) {
	chomp;
	next if ($_ eq ""||/^$/ ||!/^\@SQ/);
	my $id=(split(/\t/,$_))[1];
	$nchr++;
	my $hand=$nchr % 25;
	if (!exists $hand{$hand}) {
		open $hand{$hand},">$dOut/$hand.intervals";
		print List "$dOut/$hand.vcf\n";
		$vcfs.=" $dOut/$hand.vcf ";
		open Out,">$dOut/$hand.gtyping.json\n";
		print Out "{\n";
		print Out "\"Gvcftyping.gvcftyping.inputVCFs\": \"$dOut/gvcf.list\",\n";
		print Out "\"Gvcftyping.gvcftyping.Refdict\": \"$dict\",\n";
		print Out "\"Gvcftyping.gvcftyping.Refindex\": \"$ref.fai\",\n";
		print Out "\"Gvcftyping.gvcftyping.workdir\": \"$dOut\",\n";
		print Out "\"Gvcftyping.gvcftyping.RefFasta\": \"$ref\",\n";
		print Out "\"Gvcftyping.gvcftyping.Internal\": \"$dOut/$hand.intervals\",\n";
		print Out "\"Gvcftyping.gvcftyping.Filename\": \"$hand\",\n";
		print Out "\"Gvcftyping.gvcftyping.NT\": \"16\"\n";
		print Out "}\n";
		close Out;
		print SH "cd $dOut/ && java -jar /mnt/ilustre/users/dna/.env//bin//cromwell-30.jar run $Bin/bin/GVCFtyping.wdl -i $dOut/$hand.gtyping.json \n";
	}
	$id =~ s/SN://g;
	print {$hand{$hand}} $id,"\n";
}
close In;
close SH;
close List;
my $job="perl /mnt/ilustre/users/dna/.env//bin/qsub-sge.pl  --Resource mem=120G --CPU 16 --maxjob $proc $dShell/08-1.gvcf-typing.sh";
`$job`;
open SH,">$dShell/08-2.mergeVCF.sh";
my $mem=`du -s ./*.vcf|awk \'\{a+=\$1\}END\{print a\}\'`;
$mem=$mem/1000000;
$mem=(int($mem/100)+1)*100;
print SH "cd $dOut/ && ";
print SH "bcftools concat $vcfs -o $dOut/pop.noid.vcf -O v && ";
print SH "bcftools annotate --set-id +\'\%CHROM\\_\%POS\' $dOut/pop.noid.vcf -o $dOut/pop.nosort.vcf && ";
print SH "bcftools sort -m $mem\G -T $dOut/temp/ -o $dOut/pop.variant.vcf $dOut/pop.nosort.vcf \n";
close SH;
$job="perl /mnt/ilustre/users/dna/.env//bin/qsub-sge.pl  --Resource mem=$mem\G --CPU 1 --maxjob $proc $dShell/08-2.mergeVCF.sh";
`$job`;

#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
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
Contact:        long.huang\@majorbio.com;
Script:			$Script
Description:
	fq thanslate to fa format
	eg:
	perl $Script -i -o -k -c

Usage:
  Options:
  -gvcf	<file>	input g vcf file
  -ref	<file>	input reference file
  -dict	<file>	input reference dict
  -out	<dir>	output dir
  -proc <num>	number of process for qsub,default
  -dsh	<dir>	output shell dir
  -h         Help

USAGE
        print $usage;
        exit;
}
