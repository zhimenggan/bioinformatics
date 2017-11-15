#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($vcf,$out,$dsh,$maf,$mis,$dep,$gro);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"vcf:s"=>\$vcf,
	"out:s"=>\$out,
	"dsh:s"=>\$dsh,
	"gro:s"=>\$gro,
	"maf:s"=>\$maf,
	"mis:s"=>\$mis,
	"dep:s"=>\$dep,
			) or &USAGE;
&USAGE unless ($vcf and $out and $dsh );
mkdir $out if (!-d $out);
mkdir $dsh if (!-d $dsh);
$out=ABSOLUTE_DIR($out);
$dsh=ABSOLUTE_DIR($dsh);
$vcf=ABSOLUTE_DIR($vcf);
$mis||=0.3;
$maf||=0.05;
$dep||=2;
$mis=1-$mis;
my %group;
if ($gro) {
	my %group;
	open In,$gro;
	while (<In>) {
		chomp;
		next if ($_ eq ""||/^$/);
		if (/^#/) {
			(undef,@gro)=split(/\s+/,$_);
		}else{
			my ($id,@groinfo)=split(/\s+/,$_);
			for (my $i=0;$i<@gro;$i++) {
				if (!exists $group{$gro[$i]}{$groinfo[$i]}) {
					open $group{$gro[$i]}{$groinfo[$i]},">$out/$gro[$i].$groinfo[$i].glist";
				}
				print {$group{$gro[$i]}{$groinfo[$i]}} $id,"\n";
			}
		}
	}
	close In;
}
open SH,">$dsh/step00.vcf-filter.sh";
open List,">$out/vcf.list";
print SH "/mnt/ilustre/users/dna/.env/bin/vcftools  --remove-filtered-all --remove-indels --minDP $dep  --max-missing $mis --vcf $vcf --recode --vcf $vcf --out $out/pop.filtered --maf $maf ";
print List "pop $out/pop.filtered.recode.vcf";
close List;
close SH;
my $job="perl /mnt/ilustre/users/dna/.env/bin/qsub-sge.pl  $dsh/step00.vcf-filter.sh";
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
  -vcf	<file>	input vcf files
  -out	<dir>	output dir
  -dsh	<dir>	output work shell
  -gro	<str>	group list
  -maf	<num>	maf filter default 0.05
  -mis	<num>	mis filter default 0.3
  -dep	<num>	dep filter default 2

  -h         Help

USAGE
        print $usage;
        exit;
}
