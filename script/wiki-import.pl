#! /usr/bin/env perl

use v5.36;
use utf8;
binmode STDOUT, ':utf8';
no warnings 'experimental::builtin';

use Path::Tiny;
use XXX;

sub rsign_to_tex;

my $filename = $ARGV[0] or die "Missing filename arg";
my $fh = path($filename)->openr_utf8;

my $data = {};

my $comment;
my $city;
my $loc;
LINE:
while ( my $line = <$fh> ) {   
	$line = builtin::trim $line;
	next LINE unless length $line;
	
	do { $comment = 0; next LINE } if $line =~ m{^-->$|^</gallery>$};
	do { $comment = 1; next LINE } if $line =~ m{^<!--$|^<gallery>$};
	next LINE if $comment;
	
	do { $city = $1; $loc = undef } if $line =~ m/^= (.+) =$/;
	next LINE unless $city;
	do { $loc = undef; next LINE } if $line =~ m/^== .+ ==$/;
	
	do { $loc = $1; next LINE } if $line =~ m/^;\s*(.+)$/;
	next LINE unless $loc;
	
	do {
		push $data->{$city}{_}->@*, $line;
		next LINE;
	} unless my ($desc) = $line =~ m/^:\s*(.*)$/;
	die "Duplicate location" if exists $data->{$city}{$loc};
	
	$loc =~ s<\Q{{$_}}\E><\\$_> for qw( Dealer Garage Gas Recruitment Rest Service Weigh );
	$loc =~ s<\Q{{ST jobs}}\E><\\SpecialTransport>;
	
	$loc =~ s<\QGarage \Garage\E><\\GarageHQ \\Garage>;
	$loc =~ s<\QGas station \Gas\E><\\GasStation \\Gas>;
	$loc =~ s<\QRecruitment agency \Recruitment\E><\\RecruitmentAgency \\Recruitment>;
	$loc =~ s<\QRest area \Rest\E><\\RestArea \\Rest>;
	$loc =~ s<\QTruck service \Service\E><\\TruckService \\Service>;
	$loc =~ s<\QTruck stop \Gas\E><\\TruckStop \\Gas>;
	$loc =~ s<\Q truck dealer \Dealer\E>< \\TruckDealer \\Dealer>;
	$loc =~ s<\Q underground tank\E\b>< \\UndergroundTank>;
	$loc =~ s< & >< \\& >g;
	$desc =~ s< & >< \\& >g;
	$desc =~ s<\Q Offers [[Special Transport]] jobs.\E><>i;
	
	$desc =~ s< exit ([0-9]+)([ .,;:])>< \\Exit{$1}$2>g;  # exits
	$desc =~ s< exit ([0-9]+)/([0-9]+)([ .,;:])>< \\Exits{$1}{$2}$3>g;  # exit with multiple numbers
	$desc =~ s< exit ([0-9]+)([A-Z])([ .,;:])>< \\Exit{$1}[$2]$3>g;  # lettered exits
	
	$data->{$city}{$loc} = rsign_to_tex $desc;
}

close $fh;

sub rsign_to_tex :prototype(_) {
	my ($desc) = @_;
	$desc =~ s<\Q{{RSIGN|US|IS|\E([^|]+)(?:\|[^|]*)?(?:\|SIZE=2.)?\Q}}\E><\\I{$1}>g;  # interstates
	$desc =~ s<\Q{{RSIGN|US|BU|\E([^|]+)(?:\|SIZE=2.)?\Q}}\E><\\I{$1}[Bus]>g;  # business interstates
	$desc =~ s<\Q{{RSIGN|US|US|\E([^|]+)(?:\|SIZE=2.)?\Q}}\E><\\US{$1}>g;  # US highways
	$desc =~ s<\Q{{RSIGN|US|USBUS|\E([^|]+)(?:\|SIZE=2.)?\Q}}\E><\\US{$1}[Bus]>g;  # business US highways
	$desc =~ s<\Q{{RSIGN|US|\E([A-Z]{2})\|([^|]+)(?:\|SIZE=2.)?\Q}}\E><\\$1\{$2}>g;  # state highways
	$desc =~ s<\Q{{RSIGN|US|TXFM|\E([^|]+)(?:\|SIZE=2.)?\Q}}\E><\\TX[FM]{$1}>g;  # Texas farm roads
	return $desc;
}

for $city (sort keys $data->%*) {
	say "\n\\City{$city}\n";
	say "\\begin{LocationList}";
	my @locs = sort { fc $a =~ s/^\\//r cmp fc $b =~ s/^\\//r }
	           grep { $_ ne '_' } keys $data->{$city}->%*;
	for $loc (@locs) {
		say "\n\\Location{$loc}";
		say $data->{$city}{$loc};
	}
	say "\n\\end{LocationList}";
	say "\n$_" for map {rsign_to_tex} $data->{$city}{_}->@*;
	
}



__END__

Before the C/FD got started, in the year 2022, I (nautofon) wrote what
I then called "city location descriptions" and released them under
CC BY-SA to the Fandom wiki. Since I wrote that content myself, I'm
perfectly within my rights to reuse it for the C/FD.

This script is only to be used for those city location descriptions that
I actually wrote myself. A few cities in northwest Texas have location
descriptions written by someone else. Because I run this script on local
files containing drafts of what I wrote before submitting it to the
wiki, there is zero risk of accidentally including any content I don't
own in the C/FD here.

Warning: Does not handle cities with identical names!
Those must be kept in separate files for this script.
