#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;


my $WORKING_DIR = getcwd();
$WORKING_DIR = $WORKING_DIR.'/' if ($WORKING_DIR !~ /\/$/);

my $SCRIPT_DIR = $0;
$SCRIPT_DIR =~ s/\/?[^\/]+$//;
$SCRIPT_DIR = '.' if (!$SCRIPT_DIR);
$SCRIPT_DIR = $SCRIPT_DIR.'/';


sub CloneFromGitHub;
sub SetupBaseFiles;
sub SetupFail;
sub GetKeywords;



if (@ARGV != 1) {
	die "\n  USAGE:  ./BuildSiteShell.pl [temp-metadata]\n\n";
}



my $all_sites_dir_name = $SCRIPT_DIR.'../sites/';
if (!(-d $all_sites_dir_name)) {
	if (system("mkdir $all_sites_dir_name")) {
		die "\n  ERROR:  Failed to create umbrella directory '$all_sites_dir_name' (BuildSiteShell.pl)\n\n";
	}
}


my $keywords_ref = GetKeywords($ARGV[0]);
my %Keywords = %{$keywords_ref};


my $site_dir_name = $Keywords{'SITE'};
$site_dir_name =~ s/\W/_/g;
while ($site_dir_name =~ /__/) {
	$site_dir_name =~ s/__/_/g;
}
$site_dir_name = $site_dir_name.'/';


$site_dir_name = $all_sites_dir_name.$site_dir_name;
if (-d $site_dir_name) {
	die "\n  ERROR:  Site directory '$site_dir_name' already exists (BuildSiteShell.pl)\n\n";
}


CloneFromGitHub($site_dir_name,$Keywords{'GITUSER'},$Keywords{'GITREPO'});

SetupBaseFiles($site_dir_name,\%Keywords);


print "SITEDIR:$site_dir_name\n";


1;









###################################################################
#
#  Function:  SetupBaseFiles
#
sub CloneFromGitHub
{
	my $site_dir_name   = shift;
	my $github_username = shift;
	my $github_repo     = shift;

	my $clone_cmd = "git clone https://github.com/$github_username/$github_repo.github.io $site_dir_name";
	if (system($clone_cmd)) {
		die "\n  ERROR:  Site directory creation / GitHub cloning failed, command: '$clone_cmd' (BuildSiteShell.pl)\n\n";
	}

}






###################################################################
#
#  Function:  SetupBaseFiles
#
sub SetupBaseFiles
{
	
	my $site_dir_name = shift;
	my $keywords_ref  = shift;

	my %Keywords = %{$keywords_ref};


	my $template_dir_name = $SCRIPT_DIR.'templates/';
	if (!(-d $template_dir_name)) {
		SetupFail("Failed to locate template directory '$template_dir_name'",$site_dir_name);
	}


	my @FileNames = ("pm.blank.jpg", "pm.css", "pm.fontlinks.html", "navbar.js", "postlist.js");
	my @FileRoles = ("AUTOGRAPH"   , "CSS"   , "FONTS"            , "NAVBARJS" , "POSTLISTJS" );
	for (my $file_id=0; $file_id < scalar(@FileNames); $file_id++) {

		if (system("cp $template_dir_name$FileNames[$file_id] $site_dir_name")) {
			SetupFail("Failed to copy file '$FileNames[$file_id]' to '$site_dir_name'",$site_dir_name);
		}
		$Keywords{$FileRoles[$file_id]} = $FileNames[$file_id];

	}


	my $out_metadata_file_name = $site_dir_name.'.metadata';
	open(my $OutMetadataFile,'>',$out_metadata_file_name)
		|| SetupFail("Failed to create metadata file '$out_metadata_file_name'",$site_dir_name);
	foreach my $keyword (sort keys %Keywords) {
		print $OutMetadataFile "$keyword: $Keywords{$keyword}\n";
	}
	close($OutMetadataFile);

}






###################################################################
#
#  Function:  SetupFail
#
sub SetupFail
{
	my $error_message = shift;
	my $site_dir_name = shift;

	system("rm -rf $site_dir_name");
	die "\n  ERROR:  $error_message (BuildSiteShell.pl)\n\n";
}






###################################################################
#
#  Function:  GetKeywords
#
sub GetKeywords
{
	my $temp_metadata_filename = shift;

	if (!(-e $temp_metadata_filename)) {
		die "\n  ERROR:  Failed to locate temporary metadata file '$temp_metadata_filename' (BuildSiteShell.pl)\n\n";
	}

	open(my $TempMetadata,'<',$temp_metadata_filename)
		|| die "\n  ERROR:  Failed to open temporary metadata file '$temp_metadata_filename' (BuildSiteShell.pl)\n\n";

	my %Keywords;
	while (my $line = <$TempMetadata>) {
		$line =~ s/\n|\r//g;
		if ($line =~ /^\s*([A-Z]+)\s*\:\s*(.+)\s*$/) {
			$Keywords{$1} = $2;
		}
	}

	close($TempMetadata);

	foreach my $mandatory_keyword ("OWNER","GITUSER","GITREPO","SITE","SITEDESCRIPTION","SITEURL") {
		if (!$Keywords{$mandatory_keyword}) {
			die "\n  ERROR:  Mandatory keyword '$mandatory_keyword' not in temporary metadata file '$temp_metadata_filename' (BuildSiteShell.pl)\n\n";
		}
	}

	return \%Keywords;

}
