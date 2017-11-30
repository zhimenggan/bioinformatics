#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fIn,$fOut,$fPos,$PID,$MID,$ParentDepth,$OffDepth);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"i:s"=>\$fIn,
	"o:s"=>\$fOut,
	"p:s"=>\$fPos,
	"PID:s"=>\$PID,
	"MID:s"=>\$MID,
	"Pdep:s"=>\$ParentDepth,
	"Odep:s"=>\$OffDepth,
			) or &USAGE;
&USAGE unless ($fIn and $fOut and $PID and $MID);
$ParentDepth||=10;
$OffDepth||=10;
open In,$fIn;
open Out,">$fOut";
open Pos,">$fPos";
my @indi;
my $n=0;
while (<In>) {
	chomp;
	next if ($_ eq "" || /^$/ || /^##/);
	if (/^#/) {
		(undef,undef,undef,undef,undef,undef,undef,undef,undef,@indi)=split(/\t/,$_);
		my @outid;
		for (my $i=0;$i<@indi;$i++) {
			if ($indi[$i] eq $PID) {
				next;
			}
			if ($indi[$i] eq $MID) {
				next;
			}
			push @outid,$indi[$i];
		}
		die "error input PID or MID" if (!defined $PID || !defined $MID);
		print Out join("\t","#MarkerID","type",@outid),"\n";
	}else{
		my ($chr,$pos,$id,$ref,$alt,$qual,$filter,$info,$format,@geno)=split(/\t/,$_);
		my @format=split(/:/,$format);
		my %info;
		for (my $i=0;$i<@indi;$i++) {
			if ($geno[$i] eq "./.") {
				$info{$indi[$i]}{gt}="./.";
				$info{$indi[$i]}{ad}="0";
				$info{$indi[$i]}{dp}="0";
				next;
			}
			my @info=split(/:/,$geno[$i]);
			for (my $j=0;$j<@info;$j++) {
				$info{$indi[$i]}{gt}=$info[$j] if ($format[$j] eq "GT");
				$info{$indi[$i]}{ad}=$info[$j] if ($format[$j] eq "AD");
				$info{$indi[$i]}{dp}=$info[$j] if ($format[$j] eq "DP");
			}
			if (!exists $info{$indi[$i]}{ad} && $info{$indi[$i]}{gt} ne "./.") {
				my @ad=split(/\//,$info{$indi[$i]}{gt});
				my $max=(sort{$a<=>$b} @ad)[-1];
				my @out;
				push @out,$info{$indi[$i]}{dp};
				for (my $i=0;$i<$max;$i++) {
					push @out,0;
				}
				$info{$indi[$i]}{ad}=join(",",@out);
			}
		}
		next if ($info{$PID}{gt} eq "./." ||$info{$MID}{gt} eq "./." );#missing parent
		my ($p1,$p2)=split(/\//,$info{$PID}{gt});
		my ($m1,$m2)=split(/\//,$info{$MID}{gt});
		next if ($p1 eq $p2 && $m1 eq $m2 && $m1 eq $m2);#aaxaa
		my @pd=split(/\,/,$info{$PID}{ad});
		my @md=split(/\,/,$info{$MID}{ad});
		my $sum1=$pd[$p1];$sum1+=$pd[$p2] if($p1 ne $p2);
		my $sum2=$pd[$p1];$sum2+=$md[$p2] if($m1 ne $m2);
		next if ($sum1 < $ParentDepth || $sum2 < $ParentDepth);
		my %geno;
		$geno{$p1}++;
		$geno{$p2}++;
		$geno{$m1}++;
		$geno{$m2}++;
		my %ale;
		$n++;
		my @out;
		push @out,"Marker$n";
		if (scalar keys %geno == 4) { #abxcd
			 %ale=(
				$p1=>"a",
				$p2=>"b",
				$m1=>"c",
				$m2=>"d",
			);
			push @out,"abxcd";
		}elsif (scalar keys %geno == 3 && $p1 eq $p2 && $m1 ne $m2) {#ccxab
			 %ale=(
				$p1=>"c",
				$m1=>"a",
				$m2=>"b",
			);
			push @out,"ccxab";
		}elsif (scalar keys %geno == 3 && $p1 ne $p2 && $m1 eq $m2) {#abxcc
			 %ale=(
				$p1=>"a",
				$p2=>"b",
				$m1=>"c",
			);
			push @out,"abxcc";
		}elsif (scalar keys %geno == 3 && $p1 ne $p2 && $m1 ne $m2) {#efxeg
			my @ale=sort {$geno{$a}<=>$geno{$b}} keys %geno;
			 %ale=(
				$ale[0]=>"f",
				$ale[1]=>"g",
				$ale[2]=>"e",
			);
			push @out,"efxeg";
		}elsif (scalar keys %geno == 2 && $info{$PID}{gt} eq $info{$MID}{gt}) {#hkxhk
			%ale=(
				$p1=>"h",
				$p2=>"k",
			);
			push @out,"hkxhk";
		}elsif (scalar keys %geno == 2 && $p1 eq $p2 && $m1 ne $m2) {#nnxnp
			my @ale=sort {$geno{$a}<=>$geno{$b}} keys %geno;
			 %ale=(
				$ale[0]=>"p",
				$ale[1]=>"n",
			);
			push @out,"nnxnp";
		}elsif (scalar keys %geno == 2 && $p1 ne $p2 && $m1 eq $m2) {#lmxll
			my @ale=sort {$geno{$a}<=>$geno{$b}} keys %geno;
			 %ale=(
				$ale[0]=>"m",
				$ale[1]=>"l",
			);
			push @out,"lmxll";
		}elsif (scalar keys %geno == 2 && $p1 eq $p2 && $m1 eq $m2) {#aaxbb
			 %ale=(
				$p1=>"a",
				$m1=>"b",
			);
			push @out,"aaxbb";
		}
		for (my $i=0;$i<@indi;$i++) {
			next if ($indi[$i] eq $PID || $indi[$i] eq $MID);
			if ($info{$indi[$i]}{gt} eq "./.") {
				push @out,"--";
				next;
			}
			my ($g1,$g2)=split(/\//,$info{$indi[$i]}{gt});
			my @dp=split(/\,/,$info{$indi[$i]}{ad});
			my $sum=$dp[$g1];
			$sum+=$dp[$g2] if($g1 ne $g2);
			if ($sum < $OffDepth) {
				push @out,"--";
			}else{
				my ($g1,$g2)=split(/\//,$info{$indi[$i]}{gt});
				if (!exists $ale{$g1} || !exists $ale{$g2}) {
					push @out,"--";
				}else{
					my $geno=join("",sort ($ale{$g1},$ale{$g2}));
					push @out,"$geno";
				}
			}
		}
		print Out join("\t",@out),"\n";
		print Pos join("\t",$out[0],$chr,$pos),"\n";
	}
	#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT,@INDI)=split;
}
close Out;
close In;

#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub USAGE {#
        my $usage=<<"USAGE";
Contact:        long.huang\@majorbio.com;
Script:			$Script
Description:

Usage:
  Options:
  -i	<file>	input file vcf file
  -o	<file>	output marker file name
  -p	<file>	output pos file name
  -PID	<str>	paternal ID
  -MID	<str>	maternale ID
  -Pdep	<num>	parentDepth to filter
  -Odep	<num>	offspringDepth to filter
  -h         Help

USAGE
        print $usage;
        exit;
}
