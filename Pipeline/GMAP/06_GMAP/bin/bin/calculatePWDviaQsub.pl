#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fIn,$dOut,$only,$dsh);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"i:s"=>\$fIn,
	"o:s"=>\$dOut,
	"d:s"=>\$dsh,
	"n:s"=>\$only,
			) or &USAGE;
&USAGE unless ($fIn and $dOut and $only);
open In,$fIn;
mkdir $dOut if (!-d $dOut);
$dOut=ABSOLUTE_DIR($dOut);
my $head;
$only||=200;
my @Marker;
while (<In>) {
	chomp;
	next if ($_ eq "" ||/^$/);
	if (/^#/) {
		$head =$_;
		next;
	}else{
		push @Marker,$_;
	}
}
close In;
my $split= int(scalar @Marker / $only);
open SH,">$dsh/calc-mlod.sh";
for (my $i=0;$i<$split;$i++) {
	open Out,">$dOut/sub.$i.genotype";
	print Out $head;
	for (my $j= $only*$i;$j<@Marker;$j++) {
		print Out $Marker[$j],"\n";
	}
	close Out;
	if ($i == $split-1) {
		print SH "perl $Bin/calculateMLOD.pl -i $dOut/sub.$i.genotype -k sub.$i -d $dOut \n";
	}else{
		print SH "perl $Bin/calculateMLOD.pl -i $dOut/sub.$i.genotype -k sub.$i -d $dOut -s $only\n";
	}
}
close SH;
my $job="perl $Bin/qsub-sge.pl --Resource mem=3G --CPU 1 $dsh/calc-mlod.sh";
print $job;
`$job`;
`cat $dOut/sub*.pwd > $dOut/Total.pwd`;
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
  -i	<file>	input file name
  -o	<dir>	output file dir
  -d	<dir>	output worksh dir
  -n	<num>	split number 
  -h         Help

USAGE
        print $usage;
        exit;
}
