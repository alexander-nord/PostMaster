#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;
use Cwd;


sub GetCpanelUsername;
sub GitAddAndBuildYML;
sub GenCommitMessage;



if (@ARGV != 2 && @ARGV != 3) {
	die "\n  USAGE:  ./PushSite.pl [path/to/site] {OPTIONAL: Commit Message}\n\n";
}


my $site_dir_name = $ARGV[0];
if (!(-d $site_dir_name)) {
	die "\n  ERROR:  Failed to locate site directory '$site_dir_name' (PushSite.pl)\n\n";
}
$site_dir_name = $site_dir_name.'/' if ($site_dir_name !~ /\/$/);


my $cpanel_username = GetCpanelUsername($site_dir_name.'.metadata');


my $cpanel_root = '/home/'.$cpanel_username;
$cpanel_root =~ s/\/$//;


my $commit_message;
if (scalar(@ARGV) == 3) { $commit_message = $ARGV[2];           }
else                    { $commit_message = GenCommitMessage(); }


GitAddAndBuildYML($site_dir_name,$cpanel_root,$commit_message);


1;







###################################################################
#
#  Function:  GetCpanelUsername
#
sub GetCpanelUsername
{

	my $metadata_file_name = shift;

	if (!(-e $metadata_file_name)) {
		die "\n  ERROR:  Failed to locate metadata file '$metadata_file_name' (PushSite.pl)\n\n";
	}
	open(my $MetadataFile,'<',$metadata_file_name)
		|| die "\n  ERROR:  Failed to open metadata file '$metadata_file_name' (PushSite.pl)\n\n";

	my $cpanel_username;
	while (my $line <$MetadataFile>) {
		next if (!$line !~ /^\s*CPANELUSER\s*:\s*(\S+)\s*$/);
		$cpanel_username = $1;
		last;
	}
	close($MetadataFile);

	if (!$cpanel_username) {
		die "\n  ERROR:  Metadata file '$metadata_file_name' does not have required field 'CPANELURL' (PushSite.pl)\n\n";
	}

	return $cpanel_username;

}







###################################################################
#
#  Function:  GitAddAndBuildYML
#
sub GitAddAndBuildYML
{

	my $site_dir_name  = shift;
	my $cpanel_root    = shift;
	my $commit_message = shift;


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
	my $local_site_name = getcwd();
	$local_site_name =~ s/^.+\/([^\/]+)\/?$/$1/;
	$local_site_name = $local_site_name.'/';


	my $yml_file_name = '.cpanel.yml';
	open (my $YML,'>',$yml_file_name)
		|| die "\n  ERROR:  Failed to open YAML file '$yml_file_name' (PushSite.pl)\n\n";


	print $YML "---\n";
	print $YML "deployment:\n";
	print $YML "  tasks:\n";
	print $YML "    - /bin/rm -rf $cpanel_root/public_html/\n";
	print $YML "    - /bin/rm -rf $cpanel_root/www/\n";
	print $YML "    - /bin/mkdir  $cpanel_root/public_html/\n";
	print $YML "    - /bin/mkdir  $cpanel_root/www/\n";


	my @SubdirList = ('');
	foreach my $subdir_name (@SubdirList) {

		opendir(my $Subdir,"./$subdir_name")
			|| die "\n  ERROR:  Failed to open subdirectory '$site_dir_name$subdir_name' (PushSite.pl)\n\n";
		
		while (my $fname = readdir($Subdir)) {

			$fname =~ s/\/$//;
			next if ($BlockedDirs{$fname});

			if (-d "$subdir_name$fname") {
				push(@SubdirList,$subdir_name.$fname.'/');
				print $YML "    - /bin/mkdir $cpanel_root/public_html/$subdir_name$fname\n";
				print $YML "    - /bin/mkdir $cpanel_root/www/$subdir_name$fname\n";
			} else {
				if (system("git add $subdir_name$fname")) {
					die "\n  ERROR:  Failed to git add file '$subdir_name$fname' (PushSite.pl)\n\n";
				}
				if (!$DoNotPublish{$fname}) {
					print $YML "    - /bin/cp $cpanel_root/$local_site_name$subdir_name$fname $cpanel_root/public_html/$subdir_name\n";
					print $YML "    - /bin/cp $cpanel_root/$local_site_name$subdir_name$fname $cpanel_root/www/$subdir_name\n";
				}
			}

		}
		closedir($Subdir);

	}
	close($YML);
	
	
	# Now that we're done walking the directories, we can add the cpanel YML!
	if (system("git add .cpanel.yml")) {
		die "\n  ERROR:  Failed to git add cpanel YML file (PushSite.pl)\n\n";
	}

	if (system("git commit -m \"$commit_message\" && git push -u origin HEAD")) {
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







