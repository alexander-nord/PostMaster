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
sub ComposeLandingPage;
sub SetupBaseFiles;
sub SetupFail;
sub GetSiteDescription;
sub GetKeywords;



if (@ARGV != 2) {
	die "\n  USAGE:  ./BuildSiteFromMarkdown.pl [temp-metadata] [site-description.md]\n\n";
}



my $all_sites_dir_name = $SCRIPT_DIR.'../sites/';
if (!(-d $all_sites_dir_name)) {
	if (system("mkdir $all_sites_dir_name")) {
		die "\n  ERROR:  Failed to create umbrella directory '$all_sites_dir_name' (BuildSiteFromMarkdown.pl)\n\n";
	}
}


my $keywords_ref = GetKeywords($ARGV[0],$ARGV[1]);
my %Keywords = %{$keywords_ref};


my $site_dir_name = $Keywords{'SITE'};
$site_dir_name =~ s/\W/_/g;
while ($site_dir_name =~ /__/) {
	$site_dir_name =~ s/__/_/g;
}
$site_dir_name = $site_dir_name.'/';


$site_dir_name = $all_sites_dir_name.$site_dir_name;
if (-d $site_dir_name) {
	die "\n  ERROR:  Site directory '$site_dir_name' already exists (BuildSiteFromMarkdown.pl)\n\n";
}


CloneFromGitHub($site_dir_name,$Keywords{'GITUSER'},$Keywords{'GITREPO'});

$keywords_ref = SetupBaseFiles($site_dir_name,$ARGV[1],\%Keywords);
%Keywords = %{$keywords_ref};

ComposeLandingPage($site_dir_name,SetupBaseFiles($site_dir_name,$ARGV[1],\%Keywords));


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
		die "\n  ERROR:  Site directory creation / GitHub cloning failed, command: '$clone_cmd' (BuildSiteFromMarkdown.pl)\n\n";
	}

}







###################################################################
#
#  Function:  RipTextFromFile
#
sub RipTextFromFile
{

	my $filename = shift;

	$filename =~ /^(.+\/)[^\/]+$/;
	my $site_dir_name = $1;

	if (!(-e $filename)) {
		SetupFail("Failed to locate file '$filename'",$site_dir_name);
	}
	open(my $File,'<',$filename)
		|| SetupFail("Failed to open file '$filename'",$site_dir_name);

	my $text = '';
	while (my $line = <$File>) {
		$line =~ s/\n|\r//g;
		$text = $text.$line."\n";
	}
	close($File);

	return $text;

}







###################################################################
#
#  Function:  ComposeLandingPage
#
sub ComposeLandingPage
{

	my $site_dir_name = shift;
	my $keywords_ref  = shift;

	my %Keywords = %Keywords;

	my $template_file_name = $SCRIPT_DIR.'templates/landing.html';
	open(my $TemplateFile,'<',$template_file_name)
		|| SetupFail("Failed to open landing page template file '$template_file_name'",$site_dir_name);

	my $index_file_name = $site_dir_name.'index.html';
	open(my $IndexFile,'>',$index_file_name)
		|| SetupFail("Failed to open landing page '$index_file_name'",$site_dir_name);


	while (my $line = <$TemplateFile>) {

		$line =~ s/\n|\r//g;

		while ($line =~ /__PM_([A-Z]+)/) {

			my $keyword = $1;
			my $text_to_replace = "__PM_$keyword";

			my $replacement_text;
			if ($keyword eq 'POSTLISTJS' || $keyword eq 'NAVBARJS' || $keyword eq 'FONTS') {
				
				$replacement_text = RipTextFromFile($site_dir_name.$Keywords{$keyword});

			} else {

				$replacement_text = $Keywords{$keyword};

			}

			if (!$replacement_text) {
				SetupFail("Unable to find a replacement for '$text_to_replace' in template",$site_dir_name);
			}

			$line =~ s/$text_to_replace/$replacement_text/;

		}

		print $IndexFile "$line\n";

	}


	close($TemplateFile);
	close($IndexFile);

}






###################################################################
#
#  Function:  SetupBaseFiles
#
sub SetupBaseFiles
{
	
	my $site_dir_name       = shift;
	my $site_desc_file_name = shift;
	my $keywords_ref        = shift;

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


	if (system("cp $site_desc_file_name $site_dir_name")) {
		SetupFail("Failed to copy site description file '$site_desc_file_name' to '$site_dir_name'",$site_dir_name);
	}


	return \%Keywords;

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
	die "\n  ERROR:  $error_message (BuildSiteFromMarkdown.pl)\n\n";
}






###################################################################
#
#  Function:  GetSiteDescription
#
sub GetSiteDescription
{

	my $site_desc_file_name = shift;

	if (!(-e $site_desc_file_name)) {
		die "\n  ERROR:  Failed to locate site description file '$site_desc_file_name' (BuildSiteFromMarkdown.pl)\n\n";
	}

	my $conversion_cmd = $SCRIPT_DIR.'MarkdownToHTML.pl '.$site_desc_file_name.' |';
	open(my $SiteDescFile,$conversion_cmd)
		|| die "\n  ERROR:  Markdown conversion command '$conversion_cmd' failed (BuildSiteFromMarkdown.pl)\n\n";
	my $site_desc_html = '';
	while (my $line = <$SiteDescFile>) {
		$line =~ s/\n|\r//g;
		$site_desc_html = $site_desc_html.' '.$line if ($line =~ /\S/);
	}
	close($SiteDescFile);


	$site_desc_html =~ s/^\s*//;
	$site_desc_html =~ s/\s*$//;


	# Similar to the genre building script, we'll do a little
	# goofin' to make sure that only certain tags are allowed.
	my %SafeTags;
	$SafeTags{'em'}     = 1;
	$SafeTags{'strong'} = 1;
	$SafeTags{'a'}      = 1;


	$site_desc_html =~ s/>/></g;
	my $formatted_desc_html = "";
	foreach my $desc_bit (split(/</,$site_desc_html)) {
		if ($desc_bit =~ /^\s*\/?(\S+)>$/) {
			my $tag = $1;
			if ($SafeTags{$tag})
			 {
				$formatted_desc_html = $formatted_desc_html.' <'.$desc_bit;
			}
		} else {
			$formatted_desc_html = $formatted_desc_html.' '.$desc_bit;
		}
	}

	$formatted_desc_html =~ s/^\s*//;
	$formatted_desc_html =~ s/\s*$//;

	return $formatted_desc_html;

}





###################################################################
#
#  Function:  GetKeywords
#
sub GetKeywords
{

	my $temp_metadata_file_name = shift;
	my $site_desc_file_name     = shift;


	if (!(-e $temp_metadata_file_name)) {
		die "\n  ERROR:  Failed to locate temporary metadata file '$temp_metadata_file_name' (BuildSiteFromMarkdown.pl)\n\n";
	}


	open(my $TempMetadata,'<',$temp_metadata_file_name)
		|| die "\n  ERROR:  Failed to open temporary metadata file '$temp_metadata_file_name' (BuildSiteFromMarkdown.pl)\n\n";

	my %Keywords;
	while (my $line = <$TempMetadata>) {
		$line =~ s/\n|\r//g;
		if ($line =~ /^\s*([A-Z]+)\s*\:\s*(.+)\s*$/) {
			$Keywords{$1} = $2;
		}
	}

	close($TempMetadata);

	foreach my $mandatory_keyword ("OWNER","GITUSER","GITREPO","SITE","SITEURL") {
		if (!$Keywords{$mandatory_keyword}) {
			die "\n  ERROR:  Mandatory keyword '$mandatory_keyword' not in temporary metadata file '$temp_metadata_file_name' (BuildSiteFromMarkdown.pl)\n\n";
		}
	}


	$Keywords{'SITEDESCRIPTION'} = GetSiteDescription($site_desc_file_name);


	return \%Keywords;

}
