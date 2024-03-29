#!/usr/bin/perl -w

if(@ARGV<2){
	print STDERR "\nUsage:\nperl PG_generator.pl Reference_genome Personal_genome_vcf\n";
}

print STDERR "Loading reference...\n";

if($ARGV[0]=~/gz$/){
	open(REF,"gzip -dc $Genome|") || die "No such file or directory $Genome\n";
}else{
	open(REF,"<$Genome") || die "No such file or directory $Genome\n";
}
my %ref;
our @chrs;
$chr='chr0';
while(<REF>){
	chomp;
	if (/^>/){
		$chrs[$#chrs][1]=length($ref{$chr}) if($chr ne 'chr0');
		$chr=substr $_,1;
		push(@chrs,[$chr,0]);
	}
	else{
		$ref{$chr}.=$_;
	}
}
$chrs[$#chrs][1]=length($ref{$chr});
close(REF);

open(VCF,"<$ARGV[1]") || die "No such file: $ARGV[1]\n";
open($FAOUT1,">$ARGV[1]_1.fa") || die;
open($FAOUT2,">$ARGV[1]_2.fa") || die;
open(MAP1,">$ARGV[1]_1.fa.map") || die;
open(MAP2,">$ARGV[1]_2.fa.map") || die;

$chr='chr0';
$pointer[0]=0;
$pointer[1]=0;
$shift[0]=0;
$shift[1]=0;

$buffer[0]='';
$buffer[1]='';
sub print_to_pos {
	$hom=shift;
	$pos=shift;
	$out=shift;
	$rest=50-length($buffer[$hom])%50;
	if($pos-$pointer[$hom]>$rest){
		$buffer[$hom].=substr($ref{$chr},$pointer[$hom],$rest);
		$pointer[$hom]+=$rest;
	}
	while(length($buffer[$hom])>=50){
		print $out substr($buffer[$hom],0,50)."\n";
		$buffer[$hom]=substr($buffer[$hom],50);
	}
	while($pos-$pointer[$hom]>50){
		print $out substr($ref{$chr},$pointer[$hom],50)."\n";
		$pointer[$hom]+=50;
	}
	$buffer[$hom].=substr($ref{$chr},$pointer[$hom],$pos-$pointer[$hom]);
	$pointer[$hom]=$pos;
}

while(<VCF>){
	next if (/^#/);
	chomp;
	@vcfline=split(/\t/);
	if($chr ne $vcfline[0]){
		if($chr ne 'chr0'){
			print_to_pos(0,length($ref{$chr}),$FAOUT1);
			print_to_pos(1,length($ref{$chr}),$FAOUT2);
			print $FAOUT1 $buffer[0]."\n";
			print $FAOUT2 $buffer[1]."\n";
		}
		$chr=$vcfline[0];
		$pointer[0]=0;
		$pointer[1]=0;
		$shift[0]=0;
		$shift[1]=0;
		$buffer[0]='';
		$buffer[1]='';
		print MAP1 ">$chr\n";
		print MAP2 ">$chr\n";
		print $FAOUT1 ">$chr\n";
		print $FAOUT2 ">$chr\n";
	}
	if($pointer[0]<$vcfline[1] && $pointer[1]<$vcfline[1]){
		print_to_pos(0,$vcfline[1]-1,$FAOUT1);
		print_to_pos(1,$vcfline[1]-1,$FAOUT2);
	}
	else{
		next;
	}
	next if($vcfline[7]=~/SVTYPE=/);
	$vcfline[4]=~s/\./$vcfline[3]/g;
	if($vcfline[9] eq '0|1'){
		print MAP2 ($pointer[1]+1)."\t".($pointer[1]+1-$shift[1])."\n" if(length($vcfline[3])-length($vcfline[4])!=0);
		$shift[1]+=length($vcfline[3])-length($vcfline[4]);
		$pointer[1]+=length($vcfline[3]);
		$buffer[1].=$vcfline[4];
		print MAP2 ($pointer[1]+1)."\t".($pointer[1]+1-$shift[1])."\n" if(length($vcfline[3])-length($vcfline[4])!=0);
	}
	elsif($vcfline[9] eq '1|0'){
		print MAP1 ($pointer[0]+1)."\t".($pointer[0]+1-$shift[0])."\n" if(length($vcfline[3])-length($vcfline[4])!=0);
		$shift[0]+=length($vcfline[3])-length($vcfline[4]);
		$pointer[0]+=length($vcfline[3]);
		$buffer[0].=$vcfline[4];
		print MAP1 ($pointer[0]+1)."\t".($pointer[0]+1-$shift[0])."\n" if(length($vcfline[3])-length($vcfline[4])!=0);
	}
	elsif($vcfline[9] eq '1|1'){
		print MAP1 ($pointer[0]+1)."\t".($pointer[0]+1-$shift[0])."\n" if(length($vcfline[3])-length($vcfline[4])!=0);
		print MAP2 ($pointer[1]+1)."\t".($pointer[1]+1-$shift[1])."\n" if(length($vcfline[3])-length($vcfline[4])!=0);
		$shift[0]+=length($vcfline[3])-length($vcfline[4]);
		$pointer[0]+=length($vcfline[3]);
		$buffer[0].=$vcfline[4];
		$shift[1]+=length($vcfline[3])-length($vcfline[4]);
		$pointer[1]+=length($vcfline[3]);
		$buffer[1].=$vcfline[4];
		print MAP1 ($pointer[0]+1)."\t".($pointer[0]+1-$shift[0])."\n" if(length($vcfline[3])-length($vcfline[4])!=0);
		print MAP2 ($pointer[1]+1)."\t".($pointer[1]+1-$shift[1])."\n" if(length($vcfline[3])-length($vcfline[4])!=0);
	}
	elsif($vcfline[9] eq '1|2'){
		@alt_temp=split(/,/,$vcfline[4]);
		print MAP1 ($pointer[0]+1)."\t".($pointer[0]+1-$shift[0])."\n" if(length($vcfline[3])-length($alt_temp[0])!=0);
		print MAP2 ($pointer[1]+1)."\t".($pointer[1]+1-$shift[1])."\n" if(length($vcfline[3])-length($alt_temp[1])!=0);
		$shift[0]+=length($vcfline[3])-length($alt_temp[0]);
		$pointer[0]+=length($vcfline[3]);
		$buffer[0].=$alt_temp[0];
		$shift[1]+=length($vcfline[3])-length($alt_temp[1]);
		$pointer[1]+=length($vcfline[3]);
		$buffer[1].=$alt_temp[1];
		print MAP1 ($pointer[0]+1)."\t".($pointer[0]+1-$shift[0])."\n" if(length($vcfline[3])-length($alt_temp[0])!=0);
		print MAP2 ($pointer[1]+1)."\t".($pointer[1]+1-$shift[1])."\n" if(length($vcfline[3])-length($alt_temp[1])!=0);
	}
}
print_to_pos(0,length($ref{$chr}),$FAOUT1);
print_to_pos(1,length($ref{$chr}),$FAOUT2);
print $FAOUT1 $buffer[0]."\n";
print $FAOUT2 $buffer[1]."\n";

close(VCF);
close(FAOUT1);
close(FAOUT2);
close(MAP1);
close(MAP2);
