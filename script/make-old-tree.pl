#! /usr/bin/env perl

use v5.36;

use List::Util qw( uniqstr );
use Path::Tiny qw( path );

my $OLD_VERSION = '1.49';
my $TARGET_BASE = path('old');

my $TOKEN = qr/[0-9a-z_]{1,12}/;
my $BRACES = qr/\{( (?:[^{}]++|\{(?-1)\})*+ )\}/x;
my $LOCATION_CMD = qr/\\Location$BRACES/;
my $OLD_CMD = qr/\\Old\b([^{]*)$BRACES/;


sub old_locations ($path) {
  my $input = $path->slurp_raw;

  # Remove TeX comments to keep our regex from finding commands inside them
  # (unescaped %, up to and including the next line break and indent)
  my $tex = $input =~ s/(?<!\\)%\K.*//gr;

  # The TeX source files for cities should all include a location list.
  # We're only interested in the list here, so separate its contents
  # from whatever comes before and after it.
  my ($intro, $location_list, $outro) = $tex =~ m/
    (.*\\begin\{LocationList\}\s*)
    (.*)
    (\\end\{LocationList\}.*)
  /sx or do {
    # No location list: Probably not a city file, so copy it verbatim
    return $input;
  };

  # Include intro/outro in return value. These special hash keys will
  # automatically sort correctly.
  my %locs = (
    ' ' => $intro,
    '~' => $outro,
  );

  while (length $location_list) {

    # Get a single location item
    my $length = index $location_list, '\Location{', 1;
    $length = length $location_list if $length < 0;
    my $loc = substr $location_list, 0, $length, '';

    # Find the location's "old" name and use as the regular name
    my ($version, $name) = $loc =~ m/$OLD_CMD/;
    if ($name) {
      $loc =~ s/$LOCATION_CMD/\\Location{$name}/ or die "$path: Can't parse \\Location";
      $loc =~ s/\n?\h*$OLD_CMD//;
      $loc =~ m/$OLD_CMD/ and die "$path: Mulitple \\Old unimplemented";
      $version and warn "$path: \\Old $version unimplemented";
    }
    else {
      # No "old" name, so use the location's regular name
      ($name) = $loc =~ m/$LOCATION_CMD/ or die "$path: Can't parse \\Location";
    }

    # Instead of applying text replacement macros like \TruckStop,
    # we simply remove the leading backslash to get the sort key.
    # Thsi works because currently, all such macros have the same
    # alphabetical sort positions as their replacement strings.
    my $sort_key = fc $name =~ s/^\\|\s\K\\//gr;

    $locs{$sort_key} = $loc;
  }

  return join '', map { $locs{$_} } sort keys %locs;
}


sub new_path :prototype(_) ($path) {
  my $name = $path->basename;
  $name =~ m/\.(?:tex|eps)\z/ or return;
  $path->parent->basename eq $OLD_VERSION or return;
  return $path->parent->parent->child($name);
}


sub old_path ($path) {
  my $name = $path->basename;
  $name =~ m/\.(?:tex|eps)\z/ or return;
  return $path->parent->child($OLD_VERSION)->child($name);
}


sub make_old_for_state :prototype(_) ($dir) {
  $dir = path($dir);

  my @files = grep { $_->is_file } $dir->children(qr/\A$TOKEN\.(?:tex|eps)\z/);

  # Cities that only exist in old versions don't have a file for the
  # newer current version, so we need to artificially re-create the
  # path names of those non-existing files and add them to the list.
  # This works because old_locations() won't look at the newer files
  # anyway when it finds an old file. Another way to solve this (not
  # implemented here) would be to get the city list from _all.tex.
  if (( my $old_dir = $dir->child($OLD_VERSION) )->is_dir) {
    push @files, new_path for
      grep { $_->is_file } $old_dir->children(qr/\A$TOKEN\.(?:tex|eps)\z/);
  }

  path($TARGET_BASE)->child("$dir")->mkdir;
  for my $file ( uniqstr sort @files ) {
    my $source_file = (old_path $file)->exists ? old_path $file : $file;
    my $target_file = path($TARGET_BASE)->child("$file");
    my $target_data = old_locations( $source_file );

    # Don't overwrite unchanged files (helps saving resources)
    my $target_unchanged = eval { $target_file->slurp_raw eq $target_data };
    $target_file->spew_raw( $target_data ) unless $target_unchanged;
  }
}


# This script expects to be located in the script subdir of the main dir
chdir path($0)->parent->parent or die $!;
path('locdescs.tex')->is_file or die
  "$0: Can't find locdescs.tex; script may have been moved";

my @state_dirs = grep { $_->is_dir } path('cities')->children(qr/\A$TOKEN\z/);
make_old_for_state for @ARGV ? @ARGV : sort @state_dirs;

# Link non-city files
path($TARGET_BASE)->child('cfd')->mkdir;
link "cfd/$OLD_VERSION/$_", "$TARGET_BASE/cfd/$_" for qw(
  backmatter-single.tex
  frontmatter-preview.tex
  preview.tex
);
link "$_", "$TARGET_BASE/$_" for qw(
  locdescs.cls
  locdescs.tex
);


__END__

=head1 SYNOPSIS

  script/make-old-tree.pl [state dirs]

=head1 DESCRIPTION

Create a subdir named C<old> containing a modified copy of the
TeX files needed for typesetting the C/FD. The modifications are
intended to make the C/FD fit an older version of ATS.

One or more individual state directories to work on may be given
as arguments. If none are given, this tool works on all states.

At time of this writing the target version for the "old" copy is
S<ATS 1.49>, but this is subject to change.

=head1 MOTIVATION

Unfortunately SCS is forcing me to play an older version of the
game, if I want to play at all. This presents a problem for the
C/FD, as companies and facilities available to players vary between
ATS versions.

I still want to let the regular C/FD target the most recent game
version, to the extent that's possible. But I also want to use the
C/FD myself, even when I play an older ATS version. Thus I'll be
needing separate versions of the C/FD until further notice.

Further complicating the situation is the fact that the specific
version / configuration of ATS that I play may change over time.
Older ATS versions may perform better, but lack features and content
of newer versions, so third-party game mods may be desirable to
improve the experience on some versions. At the moment, the
following versions / configurations seem to be the most relevant:

=over

=item *

ATS latest version, vanilla (i.e. no mods modifying the game world)

=item *

ATS 1.53, vanilla

=item *

ATS 1.49 + ProMods + Reforma (at minimum Sierra Nevada, possibly more)

=back

At time of this writing I'm playing 1.49 with several map mods to
make the game world feel less outdated, but I'll probably switch to
1.53 eventually. Will likely give the vanilla game world another try
at that point, but might decide to keep using some map mods.

=head1 SOLUTION

Instead of forking the C/FD and having to maintain two entirely
separate branches with a lot of duplication, my goal is to include
the content for older ATS versions in the primary repository branch.
This should hopefully allow me to maintain all versions of the C/FD
from a single source, so that they all can benefit from any
improvements I make.

The challenges, then, are threefold.

=head2 Simple name changes: The C<\Old> command

Firstly, the economy refresh in updates 1.51 and 1.53 changed the
branding / naming of many company locations. The majority of cities
underwent at least one such change. At the most basic level, only
this company name needs to be changed in the C/FD. This is typically
a one-line change: Only the line with the C<\Location> command has
content that is actually wrong in another version.

I chose to implement this by adding a command named C<\Old> in a
separate line. C<\Old> takes an optional version hint (always
defaulting to 1.49 when missing) and is meant to simply replace
the C<\Location> value where present.

Just changing the company name like this isn't sufficient though,
as doing so will usually mess up the sort order. As a result, this
tool must re-sort the location list in all affected cities.

Additionally, in a few cases, a prose description refers to other
companies by name; these descriptions may need to be amended to use
less specific language (e.g. El Paso, Texas). Locations using
C<\Multiple> may need to be split apart, too (e.g. Wichita Falls,
Texas). These changes have already been committed to the repository.
The result isn't always optimal, but should be quite decent in
almost all cases.

=head2 Major content changes: Versioned subdirs

Secondly, simple name changes of individual locations aren't always
enough to represent changes to a city in the ATS game world. This is
obviously primarily a problem for cities affected by the base map
rework: The different versions of these cities bear no resemblance
to each other at all.

I chose to implement this by adding subdirs to the state directories
that contain replacement files for older game versions. Where such a
file exists for a particular city in the subdir for the respective
game version, this tool must prefer the subdir version. The subdir
name itself is a match for the targeted older game version; to begin
with, all subdirs are named "1.49".

Note that some cities I<only> exist in older game versions, and that
the "_all" file itself may need to be versioned, too (e.g. for
Ehrenberg, Arizona).

This approach is also suited for changes that are not a complete
rework, but still larger than what can be covered by the C<\Old>
command. However, if used for such cases, there will inevitably be a
certain amount of duplication. Care must be taken to check if future
edits need to be applied to all file versions, or just one version.
Avoiding this situation by changing the wording is probably a better
solution where possible.

=head2 Use of game mods

Lastly, I'm not sure which mod combinations I'll ultimately spend a
lot of time with yet. It might change over time.

Some mods change or even entirely replace game content, which would
need to be reflected in the C/FD. The version subdirs could in
principle be used to cover different combinations of mods as well.
The challenge is primarily production of content: Writing
descriptions for locations in old versions of map mods might not
be the best use of my time. And it might take a lot of time.

Still, having a technically separate C/FD version for mod content
might be useful, if only to avoid confusion. For example, the
Reforma Sierra Nevada mod for 1.49 replaces some cities in Nevada
with Reforma versions. A version of the C/FD meant to cover use of
that mod should indicate that there is no content available for
those cities rather than just using the vanilla descriptions.

At time of this writing map mods are not implemented, but this will
probably change sooner rather than later.
For Nevada in particular, my view is that the vanilla 1.49 version
is I<so> worthless that the 1.49 version of the C/FD should probably
treat Reforma Sierra Nevada as a prerequisite. Similarly, ProMods is
a small but high-quality expansion to the game world that doesn't
make sense I<not> to use if you're stuck playing 1.49 anyway.
On the other hand, the situation for 1.53 is less clear.

=head1 PREREQUISITE

L<Path::Tiny>

=head1 SEE ALSO

L<https://forum.scssoft.com/viewtopic.php?p=2134646#p2134646>
