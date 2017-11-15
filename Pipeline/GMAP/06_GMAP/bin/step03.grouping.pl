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
my ($mlod,$pos,$chrlist,$out,$dsh,$nchr);
GetOptions(
				"help|?" =>\&USAGE,
				"mlod:s"=>\$mlod,
				"pos:s"=>\$pos,
				"lchr:s"=>\$chrlist,
				"nchr:s"=>\$nchr,
				"out:s"=>\$out,
				"dsh:s"=>\$dsh,
				) or &USAGE;
&USAGE unless ($mlod and $out and $dsh);
$mlod=ABSOLUTE_DIR($mlod);
$pos=ABSOLUTE_DIR($pos);
$chrlist=ABSOLUTE_DIR($chrlist);
mkdir $out if (!-d $out);
mkdir $dsh if (!-d $dsh);
$out=ABSOLUTE_DIR($out);
$dsh=ABSOLUTE_DIR($dsh);
open SH,">$dsh/step03.grouping.sh";
if ($pos && $chrlist) {
	print SH "perl $Bin/bin/linkage_by_ref.pl -i $mlod -2 $pos -l $chrlist -o $out -k Total\n";
}else{
	print SH "perl $Bin/bin/linkage_by_mlod.pl -i $mlod -k Total -d $out -n $nchr\n";
}
close SH;
my $mem=`du $mlod`;
chomp $mem;
$mem=(split(/\s+/,$mem))[0];
$mem=int($mem/1000000)+3;
my $job="perl /mnt/ilustre/users/dna/.env/bin/qsub-sge.pl --Resource mem=$mem\G --CPU 1 $dsh/step03.grouping.sh";
print $job;
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
	-mlod	<file>	input vcf list
	-pos	<file>	pos file
	-lchr	<file>	chrlist
	-nchr	<num>	chr num
	-out	<out>	output dir
	-dsh	<dir>	output work shell file
USAGE
	print $usage;
	exit;
}
