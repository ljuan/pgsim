#!/usr/bin/perl -w
use List::Util qw(sum);

if($ARGV[0]=~/gz$/){
	open(INN,"gzip -dc $ARGV[0]|");
}
else{
	open(INN,"<$ARGV[0]") || die;
}
open(OUTT,">$ARGV[0].stat") || die;

my %indel_length_num1;
my %indel_length_num2;

$varnum = 0;
$evarnum = 0;

$info_tag = "AF";
#$info_tag = "EUR_AF";
$chr = "chr";
print OUTT "#CHR\tVar_Num\tExpected_Var_Num\n";
while(<INN>){
	next if(/^#/);
	chomp;
	@temp=split(/\t/);

	if($temp[0] ne $chr){
		print OUTT "$chr\t$varnum\t$evarnum\n" if($chr ne "chr");
		$chr = $temp[0];
		$varnum = 0;
		$evarnum = 0;
	}

	$varnum++;
	@temp7=split(/;/,$temp[7]);
	@temp4=split(/,/,$temp[4]);
	foreach $temp4 (@temp4){
		$indel_length_num1{length($temp4)-length($temp[3])}++;
	}
	foreach $info (@temp7) {
		if($info=~/^$info_tag=/){
			$info=~s/,\./,0/g;
			@afs = split(/[=,]/,$info);
			for($i=@afs-@temp4;$i<@afs;$i++){
				$evarnum+=$afs[$i];
				$indel_length_num2{length($temp4[$i-@afs+@temp4])-length($temp[3])}{int($afs[$i]*100)}++;
			}
		}
	}
}
print OUTT "$chr\t$varnum\t$evarnum\n";

foreach $lengthh (keys %indel_length_num1){
	print OUTT "$lengthh\t$indel_length_num1{$lengthh}\n";
}
foreach $lengthh (keys %indel_length_num2){
	foreach $aff (keys %{$indel_length_num2{$lengthh}}){
		print OUTT "$lengthh\t$aff\t$indel_length_num2{$lengthh}{$aff}\n";
	}
}
close(INN);
close(OUTT);
