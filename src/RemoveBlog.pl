#!/usr/bin/env perl
#
#  RemoveBlog.pl - Alex Nord, 2022
#
use warnings;
use strict;
use POSIX;


sub LocateScript { return './' if ($0 !~ /\//); $0 =~ /^(.*\/)[^\/]+$/; return $1; }
use lib LocateScript();
use bureaucracy;


sub TmpRemoveFromRecentsList;


if (@ARGV != 1) { die "\n  USAGE:  ./RemoveBlog.pl [File-Path]\n\n"; }


my $target_filename = $ARGV[0];
if (!FileExists($target_filename)) {
	die "\n  ERROR:  Failed to locate file '$target_filename'\n\n";
}

my $genre_dir_name = $target_filename;
$genre_dir_name =~ s/\/[^\/]+$/\//;
ConfirmDirectory($genre_dir_name);

my $site_dir_name = $genre_dir_name;
$genre_dir_name =~ s/\/[^\/]+$/\//;


# We'll do everything with temporary files so that if something goes wrong
# nothing is lost
my $site_list_filename = $site_dir_name.'recent-posts';
my $genre_list_filename = $genre_dir_name.'recent-posts';

my $tmp_site_list_filename = $site_list_filename.'.tmp';
my $tmp_genre_list_filename = $genre_list_filename.'.tmp';

TmpRemoveFromRecentsList($target_filename,$site_list_filename,$tmp_site_list_filename);
TmpRemoveFromRecentsList($target_filename,$genre_list_filename,$tmp_genre_list_filename);

RunSystemCommand("mv \"$tmp_site_list_filename\" \"$site_list_filename\"");
RunSystemCommand("mv \"$tmp_genre_list_filename\" \"$genre_list_filename\"");

RunSystemCommand("rm \"$target_filename\"");

1;







#######################################################################
#
#  Function:  TmpRemoveFromRecentsList
#
sub TmpRemoveFromRecentsList
{
	my $target_filename = shift;
	my $input_list_filename = shift;
	my $output_list_filename = shift;

	$target_filename =~ /\/([^\/]+)$/;
	my $reduced_target_filename = $1;

	my $InputList = OpenInputFile($input_list_filename);
	my $OutputList = OpenOutputFile($output_list_filename);

	while (my $line = <$InputList>) {

		$line =~ s/\n|\r//g;
		next if (!$line);

		$line =~ /^\s*\"[^\"]+\"\s+(\S+)/;
		my $listed_filename = $1;

		if ($listed_filename !~ /\/$reduced_target_filename$/) {
			print $OutputList "$line\n";
		}


	}

	close($InputList);
	close($OutputList);

}













