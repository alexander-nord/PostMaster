#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;


sub CodeBlockCatch;
sub BlockQuoteCatch;
sub OrderedListCatch;
sub UnorderedListCatch;
sub LinkCatch;
sub PerformQuickConversions;
sub TagScan;
sub TranslateStringToHTML;
sub ConvertFileToHTML;


my %IMG_EXTS;
$IMG_EXTS{'gif'}  = 1;
$IMG_EXTS{'jpg'}  = 1;
$IMG_EXTS{'jpeg'} = 1;
$IMG_EXTS{'png'}  = 1;
$IMG_EXTS{'img'}  = 1;
$IMG_EXTS{'svg'}  = 1;
$IMG_EXTS{'webp'} = 1;



if (scalar(@ARGV) != 1) {
	die "\n  USAGE:  ./MarkdownToHTML.pl [file.md]\n\n";
}


my $in_file_name = $ARGV[0];
if (!(-e $in_file_name)) {
	die "\n  ERROR:  Failed to locate markdown file '$ARGV[0]' (MarkdownToHTML.pl)\n\n";
}


my $html_str = ConvertFileToHTML($in_file_name);

print "$html_str\n";



1;






############################################################
#
#  Function:  CodeBlockCatch
#
sub CodeBlockCatch
{
	my $str = shift;

	my @Lines = split(/\n/,$str);
	$str = "<code>\n";
	
	foreach my $line (@Lines) {
		$line =~ s/^\s*\`\s*//;
		$str = $str.$line."\n" if ($line =~ /\S/);
	}
	
	return $str."</code><br>\n";

}







############################################################
#
#  Function:  BlockQuoteCatch
#
sub BlockQuoteCatch
{
	my $str = shift;

	my @Lines = split(/\n/,$str);
	$str = "<blockquote>";
	
	foreach my $line (@Lines) {
		$line =~ s/^\s*\>\s*//;
		$str = $str."\n".$line if ($line =~ /\S/);
	}
	
	return $str."\n</blockquote>\n";

}







############################################################
#
#  Function:  OrderedListCatch
#
sub OrderedListCatch
{
	my $str = shift;

	my @Lines = split(/\n/,$str);
	$str = "<ol>";
	
	foreach my $line (@Lines) {
		$line =~ s/^\s*\d+\.?\s+//;
		$str = $str."\n<li>".$line."</li><br>" if ($line =~ /\S/);
	}
	
	return $str."\n</ol>\n";

}







############################################################
#
#  Function:  UnorderedListCatch
#
sub UnorderedListCatch
{
	my $str = shift;

	my @Lines = split(/\n/,$str);
	$str = "<ul>";
	
	foreach my $line (@Lines) {
		$line =~ s/^\s*\-\s+//;
		$line =~ s/^\s*\+\s+//;
		$str = $str."\n<li>".$line."</li><br>" if ($line =~ /\S/);
	}
	
	return $str."\n</ul>\n";

}







############################################################
#
#  Function:  LinkCatch
#
sub LinkCatch
{
	my $str = shift;
	
	while ($str =~ /\[([^\]]+)\]\(([^\)]+)\)/) {

		my $text = $1;
		my $link = $2;

		$link =~ /\.([^\.]+)$/;
		my $ext = lc($1);

		if ($IMG_EXTS{$ext}) {
			$str =~ s/\[[^\]]+\]\([^\)]+\)/<img src="$link" alt="$text">/;
		} else {
			$str =~ s/\[[^\]]+\]\([^\)]+\)/<a href="$link">$text<\/a>/;
		}

	}

	return $str;

}







############################################################
#
#  Function:  PerformQuickConversions
#
sub PerformQuickConversions
{
	my $str = shift;

	$str =~ s/ "(\S)/ &ldquo;$1/g;
	$str =~ s/(\S)" /$1&rdquo; /g;

	$str =~ s/ '(\S)/ &lsquo;$1/g;
	$str =~ s/(\S)'/$1&rsquo;/g;

	$str =~ s/(\S)--(\S)/$1&ndash;$2/g;
	$str =~ s/(\S)---(\S)/$1&ndash;$2/g;

	$str =~ s/(\S)\.\.\./$1&hellip;/g;

	$str =~ s/ <[-]+ / &larr; /g;
	$str =~ s/ [-]+> / &rarr; /g;

	$str =~ s/ <= / &le; /g;
	$str =~ s/ >= / &ge; /g;

	$str =~ s/ < / &lt; /g;
	$str =~ s/ > / &gt; /g;

	$str = LinkCatch($str);

	return $str;

}







############################################################
#
#  Function:  TagScan
#
sub TagScan
{
	my $str       = shift;
	my $target    = shift;
	my $tag_open  = shift;
	my $reversion = shift;
	

	$reversion    = $target if (!$reversion);

	
	my @CharList = split(//,$str);

	
	my $tag_close = '';
	foreach my $tag (split(/\</,$tag_open)) {
		$tag_close = $tag_close.'</'.$tag;
	}
	$tag_close =~ s/\<\///; # We'll end up with one too many

	
	my @TargetChars = split(//,$target);
	my $target_len  = length($target);

	
	my $is_open = 0;
	for (my $char_id = 0; $char_id <= scalar(@CharList)-$target_len; $char_id++) {

		my $matches = 1;
		for (my $i=0; $i<$target_len; $i++) {
			if ($CharList[$char_id+$i] ne $TargetChars[$i]) {
				$matches = 0;
				last;
			}
		}
		next if (!$matches);


		for (my $i=0; $i<$target_len; $i++) {
			$CharList[$char_id+$i] = '';
		}

		if ($is_open) { $CharList[$char_id] = $tag_close; }
		else          { $CharList[$char_id] = $tag_open;  }

		$is_open = abs($is_open-1);

	}


	for (my $char_id = scalar(@CharList)-1; $char_id >=0; $char_id--) {
		last if (!$is_open);
		if ($CharList[$char_id] eq $tag_open) {
			$CharList[$char_id] = $reversion;
			$is_open = 0;
		}
	}

	return join("",@CharList);

}







############################################################
#
#  Function:  TranslateStringToHTML
#
sub TranslateStringToHTML
{

	my $md_str = shift;
	$md_str =~ s/\n|\r/ /g unless($md_str =~ /^\s*<code>/); # Preserve linebreaks for code
	
	my $html_str = PerformQuickConversions($md_str);

	my $open_tag = 0;

	$html_str = TagScan($html_str,'***','<strong><em>','&lowast;&lowast;&lowast;');
	$html_str = TagScan($html_str,'___','<strong><em>',0);

	$html_str = TagScan($html_str,'**','<strong>','&lowast;&lowast;');
	$html_str = TagScan($html_str,'__','<strong>',0);

	$html_str = TagScan($html_str,'*','<em>','&lowast;');
	$html_str = TagScan($html_str,'_','<em>',0);

	#$html_str =~ s/\s+/ /g;
	$html_str =~ s/^\s+//;
	$html_str =~ s/\s+$//;

	if ($html_str =~ /^(#+)/) {
		my $header_indicator = $1;
		my $header_level = length($header_indicator);
		$html_str =~ s/^#+\s+//;
		$html_str = '<h'.$header_level.'>'.$html_str.'</h'.$header_level.'>';
	}

	return $html_str;

}





############################################################
#
#  Function:  ConvertFileToHTML
#
sub ConvertFileToHTML
{

	my $in_file_name = shift;

	open(my $InFile,'<',$in_file_name) 
		|| die "\n  ERROR:  Failed to open markdown file '$in_file_name' (MarkdownToHTML.pl)\n\n";

	my @Paragraphs;

	my $next_paragraph    = '';
	my $is_code_block     = 1;
	my $is_block_quote    = 1;
	my $is_ordered_list   = 1;
	my $is_unordered_list = 1;

	while (my $md_line = <$InFile>) {

		$md_line =~ s/\n|\r//g;

		if ($md_line =~ /\S/) {

			$is_code_block     = 0 if ($md_line !~ /^\s*\`/);
			$is_block_quote    = 0 if ($md_line !~ /^\s*\>/);
			$is_ordered_list   = 0 if ($md_line !~ /^\s*\d+\.? /);
			$is_unordered_list = 0 if ($md_line !~ /^\s*\- |^\s*\+ /);

			$next_paragraph = $next_paragraph."\n".$md_line;

		} elsif ($next_paragraph =~ /\S/) {

			$next_paragraph =     CodeBlockCatch($next_paragraph) if ($is_code_block);
			$next_paragraph =    BlockQuoteCatch($next_paragraph) if ($is_block_quote);
			$next_paragraph =   OrderedListCatch($next_paragraph) if ($is_ordered_list);
			$next_paragraph = UnorderedListCatch($next_paragraph) if ($is_unordered_list);

			my $translation = TranslateStringToHTML($next_paragraph);
			if ($translation !~ /^\s*</) {
				$translation = '<p>'.$translation.'</p>';
			}
			push(@Paragraphs,$translation);
	
			$next_paragraph    = '';
			$is_code_block     = 1;
			$is_block_quote    = 1;
			$is_ordered_list   = 1;
			$is_unordered_list = 1;

		}

	}
	if ($next_paragraph =~ /\S/) {
	
		$next_paragraph =     CodeBlockCatch($next_paragraph) if ($is_code_block);
		$next_paragraph =    BlockQuoteCatch($next_paragraph) if ($is_block_quote);
		$next_paragraph =   OrderedListCatch($next_paragraph) if ($is_ordered_list);
		$next_paragraph = UnorderedListCatch($next_paragraph) if ($is_unordered_list);
	
		my $translation = TranslateStringToHTML($next_paragraph);
		if ($translation !~ /^\s*</) {
			$translation = '<p>'.$translation.'</p>';
		}
		push(@Paragraphs,$translation);
	
	}
	
	close($InFile);


	my $html_str = '';
	foreach my $paragraph (@Paragraphs) {
		$html_str = $html_str.$paragraph."\n<br>\n";
	}


	return $html_str;

}

