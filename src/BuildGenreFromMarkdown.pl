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


sub GenreMarkdownToHTML;
sub SafeTagsCheck;
sub ComposeGenreHTML;


if (@ARGV != 2) {
	die "\n  USAGE:  ./BuildGenreDirFromMarkdown.pl [path/to/site] [file.md]\n\n"; 
}


my $site_dir_name = $ARGV[0];
if (!(-d $site_dir_name)) {
	die "\n  ERROR:  Failed to locate site directory '$site_dir_name' (BuildGenreDirFromMarkdown.pl)\n\n";
}

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
				$out_html_str = $out_html_str.'<'.$bit;
			}
		} else {
			$out_html_str = $out_html_str.$bit;
		}

	}

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

	
	open(my $GenreListFile,'>>',$site_dir_name.'.genre-list')
		|| die "\n  ERROR:  Failed to open genre list file '$site_dir_name.genre-list'\n\n";
	print $GenreListFile "\"$genre_name_html\" $genre_name_text\n";
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
		GenreDirSetupFail("Failed to compose genre index HTML",$genre_dir_name);
	}

}


