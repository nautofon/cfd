#! /usr/bin/env perl

use v5.36;

use Path::Tiny qw( path );

my $TARGET_BASE = path('old');
my $DEFAULT_TARGET = '1.49';

# Regex pieces
my $TOKEN = qr/[0-9a-z_]{1,12}/;
my $VERSION_SUBDIR = qr/\d\.\d\d/a;
my $BRACES = qr/\{( (?:[^{}]++|\{(?-1)\})*+ )\}/x;
my $LOCATION_CMD = qr/\\Location$BRACES/;
my $OLD_CMD = qr/\\Old\b([^{]*)$BRACES/;
my $OLD_VERSION = qr/\[($VERSION_SUBDIR.*?)\]/;

# CLI args
my $TARGET_VERSION = shift @ARGV || $DEFAULT_TARGET;
my @STATE_DIRS = @ARGV
  ? map { path($_) } @ARGV
  : sort grep { $_->is_dir } path('cities')->children(qr/\A$TOKEN\z/);

# Sanity checks
$TARGET_VERSION =~ m/\A$VERSION_SUBDIR(?!\d)/a
  or die "$0: Can't use '$TARGET_VERSION' as target version\n";
$TARGET_VERSION ge '1.45'
  or warn "$0: Warning: using target versions earlier than 1.45 may produce incomplete or incorrect content\n";
  # 1.45: gas station rebranding Chemron -> Aron, Heart's -> Phoenix etc.
  # 1.44: California rework phase 2
  # 1.38: changes to El Centro, Las Vegas
  # 1.36: changes to Flagstaff, Santa Cruz


sub old_variant ($path) {
  $path =~ m/\Acities\// ? old_locations($path) : old_outside_matter($path)
}


sub old_outside_matter ($path) {
  local $_ = $path->slurp_raw;
  return $_ if $path =~ m/\.cls\z/;
  s{\\OldVersionNumber(\\|\s*)}{$TARGET_VERSION}gn;
  s{\\MinVersion$BRACES$BRACES(\n?)}{
    $TARGET_VERSION ge $1 ? "$2$3" : "%$2% $1+\n"
  }eg;
  return $_;
}


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

    $loc =~ m/$LOCATION_CMD/ or die "$path: Can't parse \\Location";
    my %names = ( 'latest version' => $1 );

    # Discover any potential \Old names for this location
    while ( $loc =~ m/$OLD_CMD/g ) {
      my ($version, $name) = ($1, $2);
      $version ||= '[1.52]';  # default for \Old, see TeX class file
      $version =~ s/$OLD_VERSION/$1/ or die "$path: Can't parse \\Old version $version";
      $names{$version} = $name;
    }

    # Pick the oldest available name for each location newer than
    # or equal to the target ATS version
    my @versions =
      grep { $_ ge $TARGET_VERSION }
      sort keys %names;
    my $name = $names{ $versions[0] };

    $loc =~ s/$LOCATION_CMD/\\Location{$name}/;
    $loc =~ s/(?:\n?\h*$OLD_CMD)+//;  # tidy

    # Instead of applying text replacement macros like \TruckStop,
    # we simply remove the leading backslash to get the sort key.
    # Thsi works because currently, all such macros have the same
    # alphabetical sort positions as their replacement strings.
    my $sort_key = fc $name =~ s/^\\|\s\K\\//gr;

    $locs{$sort_key} = $loc;
  }

  return join '', map { $locs{$_} } sort keys %locs;
}


sub add_to_files_from_dir ($files, $dir) {
  # Consider only subdirs newer than or equal to the target ATS version
  my @version_subdirs =
    grep { $_->basename ge $TARGET_VERSION }
    sort $dir->children(qr/\A$VERSION_SUBDIR/);

  # Assemble list of files to work on, picking for each file the oldest
  # version that is open for consideration
  for my $version_dir ( @version_subdirs, $dir ) {
    for my $source_file ( $version_dir->children(qr/\.(tex|eps)\z/n) ) {

      # Determine the "clean" current version file path. That file
      # might not necessarily exist, but we still need the path to
      # create a file in the equivalent location in the "old" tree.
      my $file = $source_file->parent->basename =~ m/\A$VERSION_SUBDIR/
        ? $source_file->parent(2)->child( $source_file->basename )
        : $source_file;

      $files->{ $file } //= $source_file;
    }
  }
}


sub make_old_for_files ($files) {
  my %files = $files->%*;
  for my $file ( sort keys %files ) {
    my $source_file = $files{ $file };
    my $target_file = $TARGET_BASE->child( $file );

    my $target_data = old_variant( $source_file );
    $target_file->parent->mkdir;

    # Don't overwrite unchanged files (helps saving resources)
    my $target_unchanged = eval { $target_file->slurp_raw eq $target_data };
    $target_file->spew_raw( $target_data ) unless $target_unchanged;
  }
}


# This script expects to be located in the script subdir of the main dir
chdir path($0)->parent->parent or die $!;
path('locdescs.tex')->is_file or die
  "$0: Can't find locdescs.tex; script may have been moved";

my %files;
$files{$_} = path($_) for qw(
  locdescs.cls
  locdescs.tex
);

add_to_files_from_dir(\%files, $_) for @STATE_DIRS, path('cfd');

make_old_for_files(\%files);


__END__

=head1 SYNOPSIS

  script/make-old-tree.pl [ targetversion [ statedirs ... ] ]

=head1 DESCRIPTION

Create a subdir named C<old> containing a modified copy of the
TeX files needed for typesetting the C/FD. The modifications are
intended to make the C/FD fit an older version of ATS.

The ATS version to target may be given as argument. If not given,
this tool currently defaults to ATS 1.49 (subject to change).

One or more individual state directories to work on may be given
as arguments after the target version. If none are given, this
tool works on all states.

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
of newer versions. Third-party modifications to the game world
(so-called "map mods") may be desirable to improve the experience
on some versions.
At the moment, the following versions / configurations seem to be
the most relevant:

=over

=item *

ATS latest version, vanilla (i.e. no mods modifying the game world)

=item *

ATS 1.53, vanilla

=item *

ATS 1.49 + ProMods + Reforma (at minimum Sierra Nevada, possibly more)

=back

At time of this writing I'm playing 1.49 with several map mods
enabled to make the game world feel less outdated, but I'll probably
switch to 1.53 eventually. Will likely give the regular SCS game
world ("vanilla") another try at that point, but might decide to
keep using some mods.

For example, my view is that the vanilla 1.49 version of Nevada is
I<so> worthless that the mod known as Reforma Sierra Nevada should
perhaps be treated as a prerequisite for 1.49. Similarly, ProMods is
a small but high-quality expansion to the game world that doesn't
make sense I<not> to use if you're stuck playing 1.49 anyway.
On the other hand, the situation for S<ATS 1.53> is less clear.

=head1 SOLUTION

Instead of forking the C/FD and having to maintain multiple entirely
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
separate line. The argument of C<\Old> is meant to simply replace
the C<\Location> value where present. C<\Old> takes an optional
argument that declares the I<last> ATS version number for which the
command is valid. The version always defaults to 1.52 when missing,
which is just before the big economy refresh happened.

  \Location{Driverse}  % is named Driverse since 1.53
  \Old{Haulett}        % was named Haulett before 1.53
  \Old[1.50]{Vortex}   % was named Vortex up to 1.50

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
that contain replacement files for older game versions. Just as for
the C<\Old> command, the subdir name is the last ATS version number
for which the contents are valid. When the target game version
matches one of the version subdirs or is even older than that, this
tool must prefer files from the oldest of these version subdirs.

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

=head2 Targeting map mods

Lastly, I'm not sure which mod combinations I'll ultimately spend a
lot of time with yet. It might change over time.

Many map mods change or even entirely replace a large number of
cities in the game, and of course many are continuously updated and
they can be combined in various ways.

Allowing the C/FD to target games with map mods implies a
proliferation of variants of cities. I believe it isn't really
realistic to expect the C/FD to offer complete and accurate
descriptions of all cities affected by such mods. That might not
be the best use of my time (and it might take a lot of time).
However, accounting for enabled mods is still useful: It allows
the C/FD to show placeholders for affected cities instead of
descriptions of the vanilla version of those cities, which would
only mislead and confuse players.

For example, the Reforma Sierra Nevada mod for 1.49 replaces some
cities in Nevada with Reforma versions. A version of the C/FD meant
to cover use of that mod should indicate that there is no content
available for those cities rather than just using the vanilla
descriptions.

At time of this writing map mods are not implemented here, but this
will probably change sooner rather than later.

=head1 PREREQUISITES

=over

=item * L<Path::Tiny>

=back

=head1 SEE ALSO

L<https://forum.scssoft.com/viewtopic.php?p=2134646#p2134646>
