#! /usr/bin/env perl

use v5.40;

use LaTeX::TOM;
use Path::Tiny 0.054;
use Test::More 0.94;

my $tex = LaTeX::TOM->new(2);  # 2 = silent on error
# Not too convinced that using LaTeX::TOM is really better than slurp + a bunch of regexes

chdir path($0)->parent->parent or die $!;

# Get a list of text replacement macros used in \Location commands
my $class = path('locdescs.cls')->slurp_raw;
my %replacements;
for my $node ($tex->parse($class)->getCommandNodesByName('newcommand*')->@*) {
  my $text = trim $node->getNextSibling->getNodeText =~ s/^\{|\}$//gr;
  $text =~ /^[\w\s]+$/ or next;
  $replacements{ $node->getFirstChild->getNodeText } = $text;
}

my @dirs = grep { $_->is_dir } path('cities')->children( qr/^ [^- .]+ $/x );
for my $dir ( sort @dirs ) {
  subtest $dir->basename => sub {

    my @files = grep { $_->is_file } $dir->children( qr/^[^_] .* \.tex$/x );
    for my $file ( sort @files ) {
      my $city = $file->basename =~ s/\.tex$//r;

      my @locs = map { $_->getFirstChild->getNodeText }
        $tex->parseFile($file)->getCommandNodesByName('Location')->@*;

      # Apply text replacement macros like \TruckStop
      for my $loc (@locs) {
        $loc =~ s{\Q$_\E\b}{ $replacements{$_} }eg for keys %replacements;
      }

      my @unsorted = grep { fc $locs[$_] lt fc $locs[$_ - 1] } 1 .. $#locs;

      ok ! @unsorted, $city;
      @unsorted and
        diag 'Unsorted at: ' . join ', ', map { $locs[$_] } @unsorted;
    }
  }
}

done_testing;
