#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;
use Cwd;


sub GenCommitMessage;


if (@ARGV != 1 && @ARGV != 2) {
	die "\n  USAGE:  ./PushSite.pl [path/to/site] {OPTIONAL:\"Commit Message\"}\n\n";
}


my $site_dir_name = $ARGV[0];
if (!(-d $site_dir_name)) {
	die "\n  ERROR:  Failed to locate site directory '$site_dir_name' (PushSite.pl)\n\n";
}


my $commit_message;
if (scalar(@ARGV) == 2) { $commit_message = $ARGV[1];           }
else                    { $commit_message = GenCommitMessage(); }


chdir "$site_dir_name";
my $push_cmd = "git add -A && git commit -m \"$commit_message\" && git push origin main";
if (system($push_cmd)) {
	die "\n  ERROR:  Push command '$push_cmd' failed (PushSite.pl)\n\n";
}


1;





###################################################################
#
#  Function:  GenCommitMessage
#
sub GenCommitMessage
{

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
	$year += 1900;
	$mon++;
	$mon = '0'.$mon if ($mon < 10);
	$mday = '0'.$mday if ($mday < 10);
	my $commit_date = $year.'-'.$mon.'-'.$mday;

	return "PostMaster: Automated commit ($commit_date)";
}


