#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;


my $WORKING_DIR = getcwd();
$WORKING_DIR = $WORKING_DIR.'/' if ($WORKING_DIR !~ /\/$/);

sub GetScriptDir { my $sd = $0; $sd =~ s/\/?[^\/]+$//; $sd = '.' if (!$sd); return $sd.'/'; }
my $SCRIPT_DIR = GetScriptDir();
use lib GetScriptDir();
use __FixLinks;


sub GenreMarkdownToHTML;
sub SafeTagsCheck;
sub GenreDirSetupFail;
sub PullPlainName;
sub SetupGenreDir;
sub ComposeGenreHTML;



if (@ARGV != 2) {
	die "\n  USAGE:  ./BuildGenreDirFromMarkdown.pl [path/to/site] [file.md]\n\n"; 
}


my $site_dir_name = $ARGV[0];
if (!(-d $site_dir_name)) {
	die "\n  ERROR:  Failed to locate site directory '$site_dir_name' (BuildGenreDirFromMarkdown.pl)\n\n";
}
$site_dir_name = $site_dir_name.'/' if ($site_dir_name !~ /\/$/);


my $markdown_file_name = $ARGV[1];
if (!(-e $markdown_file_name)) {
	die "\n  ERROR:  Failed to locate markdown file '$markdown_file_name' (BuildGenreDirFromMarkdown.pl)\n\n";
}


my $genre_dir_name = SetupGenreDir($site_dir_name,$markdown_file_name);


print "GENREDIR:$genre_dir_name\n";


1;







###################################################################
#
#  Function:  GenreMarkdownToHTML
#
sub GenreMarkdownToHTML
{
	
	my $markdown_file_name = shift;

	my $conversion_script = $SCRIPT_DIR.'MarkdownToHTML.pl';
	if (!(-e $conversion_script)) {
		die "\n  ERROR:  Failed to locate markdown conversion script '$conversion_script' (BuildGenreDirFromMarkdown.pl)\n\n";
	}

	my $conversion_cmd = "perl $conversion_script $markdown_file_name |";
	open(my $HTMLFile,"$conversion_cmd")
		|| die "\n  ERROR:  Markdown to HTML conversion command '$conversion_cmd' failed (BuildGenreDirFromMarkdown.pl)\n\n";

	my $genre_name_html = '';
	my $genre_desc_html = '';
	while (my $line = <$HTMLFile>) {

		if ($line =~ /<h1>(.*)<\/h1>/) {
	
			$genre_name_html = $1;
	
		} else {
	
			$line =~ s/\n|\r//g;
			$genre_desc_html = $genre_desc_html.$line;
	
		}

	}
	close($HTMLFile);

	$genre_desc_html = SafeTagsCheck($genre_desc_html);

	$genre_name_html =~ s/^\s*//;
	$genre_name_html =~ s/\s*$//;

	return ($genre_name_html,$genre_desc_html);

}








###################################################################
#
#  Function:  SafeTagsCheck
#
sub SafeTagsCheck
{

	my $in_html_str = shift;

	$in_html_str =~ s/^\s*//;
	$in_html_str =~ s/\s*$//;

	my %SafeTags;
	$SafeTags{'em'}     = 1;
	$SafeTags{'strong'} = 1;	
	$SafeTags{'a'}      = 1;

	# This is stupid, but I think it's going to work
	$in_html_str =~ s/>/></g;

	my $out_html_str = "";
	foreach my $bit (split(/</,$in_html_str)) {

		if ($bit =~ /^\/?(\S+).*>$/) {
			my $tag = $1;
			if ($SafeTags{$tag}) {
				$out_html_str = $out_html_str.' <'.$bit;
			}
		} else {
			$out_html_str = $out_html_str.' '.$bit;
		}

	}

	$out_html_str =~ s/^\s*//;
	$out_html_str =~ s/\s*$//;

	return $out_html_str;

}







###################################################################
#
#  Function:  GenreDirSetupFail
#
sub GenreDirSetupFail
{
	my $error_message  = shift;
	my $genre_dir_name = shift;
	system("rm -rf $genre_dir_name");
	die "\n  ERROR:  $error_message (BuildGenreDirFromMarkdown.pl)\n\n";
}






###################################################################
#
#  Function:  PullPlainName
#
sub PullPlainName
{
	my $markdown_file_name = shift;
	
	open(my $MarkdownFile,'<',$markdown_file_name)
		|| die "\n  ERROR:  Failed to open markdown file '$markdown_file_name' (BuildGenreDirFromMarkdown.pl)\n\n";
	
	my $name;
	while (my $line = <$MarkdownFile>) {
		$line =~ s/\n|\r//g;
		if ($line =~ /^\s*#\s*(.+)\s*$/) {
			$name = $1;
			last;
		}
	}
	
	close($MarkdownFile);

	return $name;

}






###################################################################
#
#  Function:  SetupGenreDir
#
sub SetupGenreDir 
{

	my $site_dir_name      = shift;
	my $markdown_file_name = shift;


	my ($genre_name_html,$genre_desc_html) = GenreMarkdownToHTML($markdown_file_name);


	my $genre_name_text = PullPlainName($markdown_file_name);

	$genre_name_text =~ s/^\s*//;
	$genre_name_text =~ s/\s*$//;
	$genre_name_text =~ s/\s/_/g;
	while ($genre_name_text =~ /__/) {
		$genre_name_text =~ s/__/_/g;
	}
	$genre_name_text =~ s/\W//g;


	my $genre_dir_name = $site_dir_name.$genre_name_text.'/';
	if (-d ($genre_dir_name)) {
		die "\n  ERROR:  Genre directory '$genre_dir_name' already exists (BuildGenreDirFromMarkdown.pl)\n\n";
	}


	if (system("mkdir $genre_dir_name")) {
		die "\n  ERROR:  Failed to create genre directory '$genre_dir_name' (BuildGenreDirFromMarkdown.pl)\n\n";
	}


	open(my $MetadataFile,'>',$genre_dir_name.'.metadata')
		|| GenreDirSetupFail("Failed to create metadata file",$genre_dir_name);
	print $MetadataFile "GENRE: $genre_name_html\n";
	print $MetadataFile "GENREDESCRIPTION: $genre_desc_html\n";
	close($MetadataFile);


	ComposeGenreHTML($genre_dir_name);


	open(my $SiteMetadata,'<',$site_dir_name.'.metadata')
		|| die "\n  ERROR:  Failed to open metadata file '$site_dir_name.metadata'\n\n";
	my $site_url;
	while (my $line = <$SiteMetadata>) {
		if ($line =~ /^\s*SITEURL\s*:\s*(\S+)/) {
			$site_url = $1;
			$site_url =~ s/\/$//;
			last;
		}
	}
	close($SiteMetadata);
		
	open(my $GenreListFile,'>>',$site_dir_name.'.genre-list')
		|| die "\n  ERROR:  Failed to open genre list file '$site_dir_name.genre-list'\n\n";
	print $GenreListFile "\"$genre_name_html\" $site_url/$genre_name_text\n";
	close($GenreListFile);


	return $genre_dir_name;

}








###################################################################
#
#  Function:  ComposeGenreHTML
#
sub ComposeGenreHTML
{
	
	my $genre_dir_name = shift;
	
	my $compose_genre_script = $SCRIPT_DIR.'ComposeGenreHTML.pl';
	my $compose_genre_cmd = "perl $compose_genre_script $genre_dir_name";
	if (system($compose_genre_cmd)) {
		GenreDirSetupFail("Failed to compose genre index HTML (command:'$compose_genre_cmd')",$genre_dir_name);
	}

	my $link_fixed_html = $genre_dir_name.'.fixed.html';
	open(my $FixedHTML,'>',$link_fixed_html)
		|| GenreDirSetupFail("Failed to open temporary html file '$link_fixed_html'",$genre_dir_name);

	open(my $IndexHTML,'<',$genre_dir_name.'index.html')
		|| GenreDirSetupFail("Failed to open (uncorrected) index.html file in '$genre_dir_name'",$genre_dir_name);


	while (my $line = <$IndexHTML>) {
		print $FixedHTML "$line";
		last if ($line =~ /class="genreDesc"/);
	}

	while (my $line = <$IndexHTML>) {
		$line =~ s/\n|\r//g;
		if ($line =~ /\S/) {
			$line = FixLinks($line,$genre_dir_name,$genre_dir_name);
			GenreDirSetupFail("Failed while attempting to manage links",$genre_dir_name) if (!$line);
		}
		print $FixedHTML "$line\n";
		last if ($line =~ /<script/);
	}

	while (my $line = <$IndexHTML>) {
		print $FixedHTML "$line";
	}


	close($FixedHTML);
	close($IndexHTML);


	my $cp_cmd = "cp $link_fixed_html $genre_dir_name".'index.html';
	if (system($cp_cmd)) {
		GenreDirSetupFail("Failed to copy $link_fixed_html to index.html in $genre_dir_name",$genre_dir_name);
	}

}


