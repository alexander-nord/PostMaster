#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;
use Cwd;


if (@ARGV != 2 && @ARGV != 3) {
	die "\n  USAGE:  ./PushSite.pl [path/to/site] [cpanel/deploy/dir] {OPTIONAL: Commit Message}\n\n";
}


my $site_dir_name = $ARGV[0];
if (!(-d $site_dir_name)) {
	die "\n  ERROR:  Failed to locate site directory '$site_dir_name' (PushSite.pl)\n\n";
}
$site_dir_name = $site_dir_name.'/' if ($site_dir_name !~ /\/$/);


my $base_deploy_path = $ARGV[1];
$base_deploy_path = $base_deploy_path.'/' if ($base_deploy_path !~ /\/$/);


my $commit_message;
if (scalar(@ARGV) == 3) { $commit_message = $ARGV[2];           }
else                    { $commit_message = GenCommitMessage(); }


GitAddAndBuildYML($site_dir_name,$base_deploy_path,$commit_message);


1;





###################################################################
#
#  Function:  GitAddAndBuildYML
#
sub GitAddAndBuildYML
{

	my $site_dir_name    = shift;
	my $base_deploy_path = shift;
	my $commit_message   = shift;


	my %BlockedDirs;
	$BlockedDirs{'.'}    = 1;
	$BlockedDirs{'..'}   = 1;
	$BlockedDirs{'.git'} = 1;

	my %DoNotPublish;
	$DoNotPublish{'.cpanel.yml'} = 1;
	$DoNotPublish{'.blog.md'}    = 1;
	$DoNotPublish{'.blog.html'}  = 1;
	$DoNotPublish{'.metadata'}   = 1;

	
	chdir $site_dir_name;


	my $yml_file_name = '.cpanel.yml';
	open (my $YML,'>',$yml_file_name)
		|| die "\n  ERROR:  Failed to open YAML file '$yml_file_name' (PushSite.pl)\n\n";


	print $YML "---\n";
	print $YML "deployment:\n";
	print $YML "  tasks:\n";
	print $YML "    - /bin/rm -rf $base_deploy_path\n";

	my @SubdirList = ('');
	foreach my $subdir_name (@SubdirList) {

		print $YML "    - /bin/mkdir $base_deploy_path$subdir_name\n";

		my $Subdir;
		if ($subdir_name) {
			opendir($Subdir,$subdir_name)
				|| die "\n  ERROR:  Failed to open subdirectory '$subdir_name' (PushSite.pl)\n\n";
		} else {
			opendir($Subdir,'.')
				|| die "\n  ERROR:  Failed to open directory '$site_dir_name' (PushSite.pl)\n\n";
		}
		
		while (my $fname = readdir($Subdir)) {

			$fname =~ s/\/$//;
			next if ($BlockedDirs{$fname});
			$fname = $subdir_name.$fname;

			if (-d $site_dir_name.$fname) {
				push(@SubdirList,$fname.'/');
			} else {
				if (system("git add $fname")) {
					die "\n  ERROR:  Failed to git add file '$fname' (PushSite.pl)\n\n";
				}
				print $YML "    - /bin/cp $fname $base_deploy_path$subdir_name\n" unless ($DoNotPublish{$fname});
			}

		}
		closedir($Subdir);

	}
	close($YML);
	
	
	if (system("git add .cpanel.yml")) {
		die "\n  ERROR:  Failed to git add cpanel YML file (PushSite.pl)\n\n";
	}

	if (system("git commit -m \"$commit_message\" && git push origin main")) {
		die "\n  ERROR:  Failed to commit or push to main (PushSite.pl)\n\n";
	}

}






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







