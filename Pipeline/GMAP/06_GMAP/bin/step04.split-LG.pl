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
my ($geno,$out,$dsh,$nchr,$popt,$lg);
GetOptions(
				"help|?" =>\&USAGE,
				"lg:s"=>\$lg,
				"geno:s"=>\$geno,
				"popt:s"=>\$popt,
				"out:s"=>\$out,
				"dsh:s"=>\$dsh,
				) or &USAGE;
&USAGE unless ($geno and $out and $dsh and $lg);
$popt||="CP";
$geno=ABSOLUTE_DIR($geno);
$lg=ABSOLUTE_DIR($lg);
mkdir $out if (!-d $out);
mkdir $dsh if (!-d $dsh);
$out=ABSOLUTE_DIR($out);
$dsh=ABSOLUTE_DIR($dsh);
open SH,">$dsh/step04.split-LG.sh";
if ($popt eq "CP") {
	print SH "perl $Bin/bin/splitbyLG-CP.pl -i $geno -l $lg -o $out \n";
}else{
	print SH "perl $Bin/bin/splitbyLG-NOCP.pl -i $geno -l $lg -d $out -t $popt\n";
}
close SH;
my $job="perl /mnt/ilustre/users/dna/.env/bin/qsub-sge.pl  --Resource mem=3G --CPU 1 $dsh/step04.split-LG.sh";
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
	-lg	<file>	input lg list
	-geno	<file>	geno file
	-popt	<str>	popt default F2
	-out	<out>	output dir
	-dsh	<dir>	output work shell file
USAGE
	print $usage;
	exit;
}
