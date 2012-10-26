#!/usr/bin/perl

# Script (c) Stuart Hickinbottom 2012 (stuart@hickinbottom.com). You
# are free to use and modify this script as you like, but please leave
# in my credit. Thank you.

# Pick up more errors
use warnings;
use strict;

# Import some facilities
use Getopt::Long;
use Pod::Usage;
use File::Find;
use File::Basename;
use LockFile::Simple;

# Exit more cleanly from signals (ensure destructors/atexits called)
use sigtrap qw(die INT QUIT);
use sigtrap qw(die untrapped normal-signals stack-trace any error-signals);

# Global definitions
use constant DEFAULT_ROOT => '/mnt/media/Music';

# The audio file suffixes we're interested in processing.
my %suffixes = ('.flac', 1,
		'.mp3', 1,
		'.m4a', 1,
		'.aac', 1);

# Set the umask - we create files with full owner and group settings, but leave
# everyone else out.
umask(0027);

# Process command-line arguments
my $verbose = "";
my $root = DEFAULT_ROOT;
GetOptions("verbose" => \$verbose,
	   "root=s" => \$root,
	   "help|?" => sub { pod2usage(1) })
  or die "Failed to understand command options";

# Output options in use
print "Music root directory: $root\n" if $verbose;
print "\n" if $verbose;

# Make sure the output directory exists, and is empty.
( -d "$root" ) || die "Root directory '$root' does not exist. Exiting.\n";

# Only one of these processes can run.
my $lockMgr = LockFile::Simple->make(-stale => 1);
$lockMgr->lock($root);

# Recursively process all directories under the root.
find({wanted => \&doFile, preprocess => \&preprocess}, $root);

# We've finished, so unlock and exit.
$lockMgr->unlock($root);
print "Done.\n" if $verbose;
exit 0;

#############################

# Process a single directory, producing all of the moodbar files
# within it.
sub doFile {
  my $pathname = $File::Find::name;

  # Ignore the directories.
  return if (-d $pathname);

  # Parse the filename so it's easier to deal with.
  my($basename, $directory, $suffix) = fileparse($pathname, qr/\.[^.]*/);

  # If the suffix is one of the music filetypes we recognise then
  # we're interested.
  return if (!exists($suffixes{$suffix}));

  my $moodpath = "$directory$basename.mood";

  # We've only got to make a moodbar file if it doesn't exist or the
  # music file has been updated since the moodbar file was created.
  return if (-f $moodpath && ((stat($moodpath))[9] > (stat($pathname))[9]));

  # OK, this is it. Create the moodbar file.
  system("moodbar", "-o", $moodpath, $pathname);
}

# Filtering function used for the Find::File traversal; this filters
# all files or subdirectories beginning with a full-stop. ie this
# filters hidden files/directories.
sub preprocess {
  grep { $_ !~ /^\./ } @_
}

# The help text
__END__

=head1 SYNOPSIS

moodbar-updater.pl [options]

 Options:
   -help           Show this help description
   -verbose        Output progress messages

   -root           Root directory of music to scan

=cut
