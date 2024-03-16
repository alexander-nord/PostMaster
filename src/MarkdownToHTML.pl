#!/usr/bin/env perl
use warnings;
use strict;


sub PerformQuickConversions;
sub TranslateStringToHTML;
sub ConvertFileToHTML;


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
		$str = $str."\n<li>".$line."</li>" if ($line =~ /\S/);
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
		$str = $str."\n<li>".$line."</li>" if ($line =~ /\S/);
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
	$str =~ s/\[([^\]]+)\]\(([^\)]+)\)/<a href="$2">$1<\/a>/g;
	return $str;
}







############################################################
#
#  Function:  ImageCatch
#
sub ImageCatch
{
	my $str = shift;
	$str =~ s/\!\[([^\]]+)\]\(([^\)]+)\)/<img src="$2" alt="$1">/g;
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

	$str = ImageCatch($str); # This should be first  -- looking for ![text](img)
	$str = LinkCatch($str);  # This should be second -- looking for  [text](url)

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
	$md_str =~ s/\n|\r/ /g;
	
	my $html_str = PerformQuickConversions($md_str);

	my $open_tag = 0;

	$html_str = TagScan($html_str,'***','<strong><em>','&lowast;&lowast;&lowast;');
	$html_str = TagScan($html_str,'___','<strong><em>',0);

	$html_str = TagScan($html_str,'**','<strong>','&lowast;&lowast;');
	$html_str = TagScan($html_str,'__','<strong>',0);

	$html_str = TagScan($html_str,'*','<em>','&lowast;');
	$html_str = TagScan($html_str,'_','<em>',0);

	$html_str = TagScan($html_str,'```','<code>','&#96;&#96;&#96;');
	$html_str = TagScan($html_str,'``','<code>','&#96;&#96;');
	$html_str = TagScan($html_str,'`','<code>','&#96;');

	$html_str =~ s/\s+/ /g;
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
	my $is_block_quote    = 1;
	my $is_ordered_list   = 1;
	my $is_unordered_list = 1;

	while (my $md_line = <$InFile>) {

		$md_line =~ s/\n|\r//g;

		if ($md_line =~ /\S/) {

			$is_block_quote    = 0 if ($md_line !~ /^\s*> |^\s*>$/);
			$is_ordered_list   = 0 if ($md_line !~ /^\s*\d+\.? /);
			$is_unordered_list = 0 if ($md_line !~ /^\s*\- |^\s*\+ /);

			$next_paragraph = $next_paragraph."\n".$md_line;

		} elsif ($next_paragraph =~ /\S/) {

			$next_paragraph =    BlockQuoteCatch($next_paragraph) if ($is_block_quote);
			$next_paragraph =   OrderedListCatch($next_paragraph) if ($is_ordered_list);
			$next_paragraph = UnorderedListCatch($next_paragraph) if ($is_unordered_list);

			push(@Paragraphs,TranslateStringToHTML($next_paragraph));

			$next_paragraph = '';
			$is_block_quote    = 1;
			$is_ordered_list   = 1;
			$is_unordered_list = 1;

		}

	}
	if ($next_paragraph =~ /\S/) {
		push(@Paragraphs,TranslateStringToHTML($next_paragraph));
	}
	
	close($InFile);


	my $html_str = '';
	foreach my $paragraph (@Paragraphs) {

		if ($paragraph =~ /\<h/) {
			$html_str = $html_str.$paragraph;
		} else {
			$html_str = $html_str.'<p>'.$paragraph.'</p>';
		}
		$html_str = $html_str."\n<br>\n";

	}


	return $html_str;

}

