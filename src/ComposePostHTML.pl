#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;
use Cwd;


my $WORKING_DIR = getcwd();
$WORKING_DIR = $WORKING_DIR.'/' if ($WORKING_DIR !~ /\/$/);

my $SCRIPT_DIR = $0;
$SCRIPT_DIR =~ s/\/?[^\/]+$//;
$SCRIPT_DIR = '.' if (!$SCRIPT_DIR);
$SCRIPT_DIR = $SCRIPT_DIR.'/';


sub RipTextFromFile;
sub ComposePost;
sub GatherKeywords;
sub GrabTitleFromHTML;
sub TitleToHTMLFilename;
sub GetFormattedDate;



if (@ARGV != 1) {
	die "\n  USAGE:  ./ComposePostHTML.pl [path/to/post/dir]\n\n";
}


my $post_dir_name = $ARGV[0];
$post_dir_name = $post_dir_name.'/' if ($post_dir_name !~ /\//);
if (!(-d $post_dir_name)) {
	die "\n  ERROR:  Failed to locate post directory '$ARGV[0]' (ComposePostHTML.pl)\n\n";
}


my $post_file_name = ComposePost($post_dir_name);


print "POST: $post_file_name\n";


1;







###################################################################
#
#  Function:  RipTextFromFile
#
sub RipTextFromFile
{

	my $filename = shift;

	if (!(-e $filename)) {
		die "\n  ERROR:  Failed to locate file '$filename' (ComposePostHTML.pl)\n\n";
	}
	open(my $File,'<',$filename)
		|| die "\n  ERROR:  Failed to open file '$filename' (ComposePostHTML.pl)\n\n";

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
#  Function:  ComposePost
#
sub ComposePost
{
	
	my $post_dir_name = shift;

	my $keywords_ref  = GatherKeywords($post_dir_name);
	my %Keywords = %{$keywords_ref};

	my $post_template_file_name = $SCRIPT_DIR.'templates/post.html';

	my $post_html_file_name = TitleToHTMLFilename($Keywords{'TITLE'});
	if ($post_html_file_name eq '.html') {
		die "\n  ERROR:  Failed to put convert post title '$Keywords{'TITLE'}' to an html title (ComposePostHTML.pl)\n\n";
	}
	$post_html_file_name = $post_dir_name.$post_html_file_name;


	open(my $HTMLFile,'>',$post_html_file_name)
		|| die "\n  ERROR:  Failed to open output HTML file '$post_html_file_name' (ComposePostHTML.pl)\n\n";

	open(my $TemplateFile,'<',$post_template_file_name)
		|| die "\n  ERROR:  Failed to open template post HTML file '$post_template_file_name' (ComposePostHTML.pl)\n\n";


	while (my $line = <$TemplateFile>) {

		$line =~ s/\n|\r//g;

		while ($line =~ /__PM_([A-Z]+)/) {

			my $keyword = $1;
			my $text_to_replace = "__PM_$keyword";

			my $replacement_text;
			if ($keyword eq 'POSTTEXT' || $keyword eq 'NAVBARJS' || $keyword eq 'FONTS') {
				
				$replacement_text = RipTextFromFile($Keywords{$keyword});

				# If this is the post text, we've already found and printed the title				
				if ($keyword eq 'POSTTEXT') {
					$replacement_text =~ s/<h1>.*<\/h1>//;
				}

			} else {

				$replacement_text = $Keywords{$keyword};

			}

			if (!$replacement_text) {
				die "\n  ERROR:  Unable to find a replacement for '$text_to_replace' in post template (ComposePostHTML.pl)\n\n";
			}

			$line =~ s/$text_to_replace/$replacement_text/;

		}

		print $HTMLFile "$line\n";

	}

	close($TemplateFile);
	close($HTMLFile);


	return $post_html_file_name;

}






###################################################################
#
#  Function:  GatherKeywords
#
sub GatherKeywords
{

	my $post_dir_name = shift;


	my $genre_dir_name = $post_dir_name;
	$genre_dir_name =~ s/\/[^\/]+\/$/\//;

	my $site_dir_name = $genre_dir_name;
	$site_dir_name =~ s/\/[^\/]+\/$/\//;

	my @MetadataFileNames;
	push(@MetadataFileNames,$genre_dir_name.'.metadata');
	push(@MetadataFileNames, $site_dir_name.'.metadata');


	my %Keywords;
	foreach my $metadata_file_name (@MetadataFileNames) {

		if (!(-e $metadata_file_name)) {
			die "\n  ERROR:  Failed to locate metadata file '$metadata_file_name' (ComposePostHTML.pl)\n\n";
		}

		open(my $MetadataFile,'<',$metadata_file_name)
			|| die "\n  ERROR:  Failed to open metadata file '$metadata_file_name' (ComposePostHTML.pl)\n\n";
		while (my $line = <$MetadataFile>) {
			if ($line =~ /^\s*(\S+)\s*\:\s*(.+)\s*$/) {
				$Keywords{$1} = $2;
			}
		}
		close($MetadataFile);

	}

	# What's the actual post content (hmtl)?!
	$Keywords{'POSTTEXT'} = $post_dir_name.'.post.html';

	# Grab the title from the html, all clever-like
	$Keywords{'TITLE'} = GrabTitleFromHTML($Keywords{'POSTTEXT'});

	# The post is considered 'published' when this script is run
	$Keywords{'PUBLISHDATE'} = GetFormattedDate();

	# The font and navbar files are likely relative to the site 
	# directory location, so we'll need to make sure we're looking
	# in the right place
	if (!(-e $Keywords{'FONTS'   })) { $Keywords{'FONTS'   } = $site_dir_name.$Keywords{'FONTS'   }; }
	if (!(-e $Keywords{'NAVBARJS'})) { $Keywords{'NAVBARJS'} = $site_dir_name.$Keywords{'NAVBARJS'}; }

	return \%Keywords;

}





###################################################################
#
#  Function:  GrabTitleFromHTML
#
sub GrabTitleFromHTML
{
	my $filename = shift;

	if (!(-e $filename)) {
		die "\n  ERROR:  Failed to locate post HTML file '$filename' (ComposePostHTML.pl)\n\n";
	}
	open(my $File,'<',$filename)
		|| die "\n  ERROR:  Failed to open post HTML file '$filename' (ComposePostHTML.pl)\n\n";


	my $title;
	while (my $line = <$File>) {
		if ($line =~ /<h1>(.*)<\/h1>/) {
			$title = $1;
			last;
		}
	}
	close($File);


	if (!$title) {
		die "\n  ERROR:  Failed to read post title (level-1 header) from post HTML file '$filename' (ComposePostHTML.pl)\n\n";
	}


	return $title;

}






###################################################################
#
#  Function:  TitleToHTMLFilename
#
sub TitleToHTMLFilename
{
	my $title = shift;

	$title =~ s/\<[^\>]+\>//g;
	$title =~ s/^\s*//g;
	$title =~ s/\s*$//g;
	$title =~ s/\s/\_/g;
	$title =~ s/\W//g;

	return $title.'.html';

}





###################################################################
#
#  Function:  GetFormattedDate
#
sub GetFormattedDate 
{
	my @Months = ("January","February","March","April","May","June","July","August","September","October","November","December");
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

	$year += 1900;
	
	my $formatted_day = $mday.'<sup>';
	if    ($mday eq '1' || $mday eq '21' || $mday eq '31') { $formatted_day = $formatted_day.'st'; }
	elsif ($mday eq '2' || $mday eq '22'                 ) { $formatted_day = $formatted_day.'nd'; }
	elsif ($mday eq '3' || $mday eq '23'                 ) { $formatted_day = $formatted_day.'rd'; }
	else                                                   { $formatted_day = $formatted_day.'th'; }
	$formatted_day = $formatted_day.'</sup>';

	return "$year, $Months[$mon] $formatted_day";

}


