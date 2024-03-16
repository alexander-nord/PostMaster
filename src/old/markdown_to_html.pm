#
#  markdown_to_html.pm - Alex Nord, 2022
#
use warnings;
use strict;
use POSIX;

# NOTE: We won't use bureaucracy.pm because we want this to be
#       extremely specific if something goes wrong with I/O.


sub MarkdownToHTMLString;
sub MarkdownParagraphToHTML;


sub LooksIndentSensitive;

sub LooksLikeMarkdownHeader;
sub MarkdownToHTMLHeader;

sub LooksLikeMarkdownNumericList;
sub MarkdownToHTMLNumericList;

sub LooksLikeMarkdownUnorderedList;
sub MarkdownToHTMLUnorderedList;

sub LooksLikeMarkdownBlockQuote;
sub MarkdownToHTMLBlockQuote;

sub LooksLikeMarkdownCodeBlock;
sub MarkdownToHTMLCodeBlock;


sub ApplyBasicHTMLConversions;
sub TabifyHTML;







##############################################################
#
#  Function:  MarkdownToHTMLString
#
sub MarkdownToHTMLString
{

    my $markdown_input = shift;

    # Have we been provided with a file?
    if ($markdown_input =~ /^\S+$/ && -e $markdown_input) {

        if (open(my $MarkdownFile,'<',$markdown_input)) {

            my $input_str = '';
            while (my $line = <$MarkdownFile>) {
                $input_str = $input_str.$line;
            }
            $markdown_input = $input_str;

            close($MarkdownFile);

        } else {

            die "\n  ERROR:  Failed to open markdown file '$markdown_input'\n\n";

        }

    }


    # If we're looking at text provided on a Windows machine we'll
    # have to adjust the linebreaks.
    $markdown_input =~ s/\r\n/\n/g;


    my @Paragraphs;
    my $num_paragraphs = 0;
    my $paragraph_str = '';
    my $indent_sensitive = 0;

    foreach my $line (split(/\n/,$markdown_input)) {
        
        if (!$line) {
        
            if ($paragraph_str) {
                
                if (!$indent_sensitive) {
                    $paragraph_str =~ s/^\s*//;
                    $paragraph_str =~ s/\s*$//;
                    $paragraph_str =~ s/\.\s+/\.\n/;
                    $paragraph_str =~ s/\!\s+/\!\n/;
                    $paragraph_str =~ s/\?\s+/\?\n/;
                    while ($paragraph_str =~ /  /) {
                        $paragraph_str =~ s/  / /g;
                    }
                }
                
                $paragraph_str =~ s/\</\&lt\;/g;
                $paragraph_str =~ s/\</\&gt\;/g;

                push(@Paragraphs,$paragraph_str);
                $num_paragraphs++;

                $paragraph_str = '';
                $indent_sensitive = 0;

            }

        } elsif (!$paragraph_str && LooksIndentSensitive($line)) {
        
            $paragraph_str = $line."\n";
            $indent_sensitive = 1;

        } elsif ($indent_sensitive) {

            $paragraph_str = $paragraph_str.$line."\n";

        } else {
        
            $paragraph_str = $paragraph_str.' '.$line;
        
        }

    }

    if ($paragraph_str) {

        if (!$indent_sensitive) {
            $paragraph_str =~ s/^\s*//;
            $paragraph_str =~ s/\s*$//;
            $paragraph_str =~ s/\.\s+/\.\n/;
            $paragraph_str =~ s/\!\s+/\!\n/;
            $paragraph_str =~ s/\?\s+/\?\n/;
            while ($paragraph_str =~ /  /) {
                $paragraph_str =~ s/  / /g;
            }
        }
                
        $paragraph_str =~ s/\</\&lt\;/g;
        $paragraph_str =~ s/\</\&gt\;/g;

        push(@Paragraphs,$paragraph_str);

        $num_paragraphs++;        
    }
        

    if ($num_paragraphs == 0) {
        print "  Warning:  No content found for provided markdown...\n";
        return '';
    }


    my $html = '';
    for (my $i=0; $i<$num_paragraphs; $i++) {
        my $paragraph_html = MarkdownParagraphToHTML($Paragraphs[$i]);
        $html = $html."<br>\n" if ($html);
        $html = $html.$paragraph_html;
    }

    return $html;

}










##############################################################
#
#  Function:  LooksLikeMarkdownHeader
#
sub LooksIndentSensitive
{
    my $str = shift;
    return 1 if (LooksLikeMarkdownHeader($str));
    return 1 if (LooksLikeMarkdownNumericList($str));
    return 1 if (LooksLikeMarkdownUnorderedList($str));
    return 1 if (LooksLikeMarkdownCodeBlock($str));
    return 1 if (LooksLikeMarkdownBlockQuote($str));
    return 0;
}








##############################################################
#
#  Function:  MarkdownParagraphToHTML
#
sub MarkdownParagraphToHTML
{
    my $input_str = shift;

    my $apply_conversions = 1;

    my $html = '';
    if (LooksLikeMarkdownHeader($input_str)) 
    {
        $html = MarkdownToHTMLHeader($input_str);
    } 
    elsif (LooksLikeMarkdownNumericList($input_str)) 
    {
        $html = MarkdownToHTMLNumericList($input_str);
    } 
    elsif (LooksLikeMarkdownUnorderedList($input_str))
    {
        $html = MarkdownToHTMLUnorderedList($input_str);
    }
    elsif (LooksLikeMarkdownBlockQuote($input_str))
    {
        $html = MarkdownToHTMLBlockQuote($input_str);
    }
    elsif (LooksLikeMarkdownCodeBlock($input_str))
    {
        $html = MarkdownToHTMLCodeBlock($input_str);
        $apply_conversions = 0;
    }
    else
    {
        $html = "<p>\n".$input_str;
        $html = $html."\n" if ($input_str !~ /\n$/);
        $html = $html."</p>\n";
    }
    
    $html = ApplyBasicHTMLConversions($html) if ($apply_conversions);

    return $html;

}







##############################################################
#
#  Function:  LooksLikeMarkdownHeader
#
sub LooksLikeMarkdownHeader 
{
    my $str = shift;

    if ($str =~ /^\s*(#+)/) {

        my $header_level = length($1);
        if ($header_level > 6) {
            return 0; # This would be really strange...
        }
        return 1;

    }

    return 0;

}



##############################################################
#
#  Function:  MarkdownToHTMLHeader
#
sub MarkdownToHTMLHeader 
{
    my $str = shift;

    $str =~ /^\s*(#+)/;
    my $header_level = length($1);

    $str =~ s/^\s*\#+//;
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    $str = '<h'.$header_level.'>'.$str.'</h'.$header_level.">\n";

    return $str;

}








##############################################################
#
#  Function:  LooksLikeMarkdownNumericList
#
sub LooksLikeMarkdownNumericList 
{
    my $str = shift;
    return 1 if ($str =~ /^\s*1\.\s+\S+/);
    return 0;
}



##############################################################
#
#  Function:  MarkdownToHTMLNumericList
#
sub MarkdownToHTMLNumericList 
{
    my $str = shift;

    my @IndentLengths;
    push(@IndentLengths,0);
    my $current_indent_depth = 0;
    
    my $html = '';
    foreach my $line (split(/\n/,$str)) {

        if ($line =~ /^(\s*)\d+\.(.*)$/) {

            my $indent_str = $1;
            my $item_content = $2;
            
            my $indent_length = length($indent_str);

            if ($indent_length > $IndentLengths[$current_indent_depth]) {

                $current_indent_depth++;
                $IndentLengths[$current_indent_depth] = $indent_length;

                $html = $html."\n<ol>\n";

            } elsif ($indent_length == $IndentLengths[$current_indent_depth]) {

                if ($html) {
                    $html = $html."</li>\n";
                } else {
                    $html = "<ol>\n";
                }

            } else {

                $html = $html."</li>\n";
                
                $current_indent_depth--;
                $html = $html."</ol>\n</li>\n";
                while ($indent_length < $IndentLengths[$current_indent_depth]) {
                    $current_indent_depth--;
                    $html = $html."</ol>\n</li>\n";
                }

                if ($indent_length > $IndentLengths[$current_indent_depth]) {
                    $current_indent_depth++;
                    $IndentLengths[$current_indent_depth] = $indent_length;
                    $html = $html."\n<ol>\n";
                }

            }

            $item_content =~ s/^\s+//g;
            $item_content =~ s/\s+$//g;
            $html = $html."<li>".$item_content;

        } else {

            $line =~ s/^\s+//;
            $html = $html.' '.$line;

        }

    }
    $html = $html."</li>\n" if ($html);
 
    while ($current_indent_depth) {
        $html = $html."</ol>\n</li>\n";
        $current_indent_depth--;
    }


    $html = $html."</ol>\n";

    return $html;
    
}








##############################################################
#
#  Function:  LooksLikeMarkdownUnorderedList
#
sub LooksLikeMarkdownUnorderedList 
{
    my $str = shift;
    return 1 if ($str =~ /^\s*[\-|\*|\+]\s+\S+/);
    return 0;
}



##############################################################
#
#  Function:  MarkdownToHTMLUnorderedList
#
sub MarkdownToHTMLUnorderedList 
{

    my $str = shift;

    my @IndentLengths;
    push(@IndentLengths,0);
    my $current_indent_depth = 0;
    
    my $html = '';
    foreach my $line (split(/\n/,$str)) {

        if ($line =~ /^(\s*)[\-|\*|\+](.*)$/) {

            my $indent_str = $1;
            my $item_content = $2;
            
            my $indent_length = length($indent_str);

            if ($indent_length > $IndentLengths[$current_indent_depth]) {

                $current_indent_depth++;
                $IndentLengths[$current_indent_depth] = $indent_length;

                $html = $html."\n<ul>\n";

            } elsif ($indent_length == $IndentLengths[$current_indent_depth]) {

                if ($html) {
                    $html = $html."</li>\n";
                } else {
                    $html = "\n<ul>\n";
                }

            } else {

                $html = $html."</li>\n";
                
                $current_indent_depth--;
                $html = $html."\n</ul>\n</li>\n";
                while ($indent_length < $IndentLengths[$current_indent_depth]) {
                    $current_indent_depth--;
                    $html = $html."</ul>\n</li>\n";
                }

                if ($indent_length > $IndentLengths[$current_indent_depth]) {
                    $current_indent_depth++;
                    $IndentLengths[$current_indent_depth] = $indent_length;
                    $html = $html."\n<ul>\n";
                }

            }

            $item_content =~ s/^\s+//g;
            $item_content =~ s/\s+$//g;
            $html = $html."<li>".$item_content;

        } else {

            $line =~ s/^\s+//;
            $html = $html.' '.$line;

        }

    }
    $html = $html."</li>\n" if ($html);
 
    while ($current_indent_depth) {
        $html = $html."</ul>\n</li>\n";
        $current_indent_depth--;
    }


    $html = $html."</ul>\n";

    return $html;
   
}








##############################################################
#
#  Function:  LooksLikeMarkdownBlockQuote
#
sub LooksLikeMarkdownBlockQuote
{
    my $str = shift;
    return 1 if ($str =~ /^\s*\>/);
    return 0;
}



##############################################################
#
#  Function:  MarkdownToHTMLBlockQuote
#
sub MarkdownToHTMLBlockQuote
{
    my $str = shift;

    my $in_block_paragraph = 0;

    my $html = "<blockquote>\n";
    foreach my $line (split(/\n/,$str)) {

        $line =~ s/^\s*[\>]+\s+//;

        if (!$line) {

            if ($in_block_paragraph) {
                $html = $html."</p>\n";
                $in_block_paragraph = 0;
            }

        } elsif ($in_block_paragraph) {

            $html = $html.$line."\n";

        } else {

            $html = $html."<p>\n".$line;
            $in_block_paragraph = 1;

        }

    }
    $html = $html."</p>\n" if ($in_block_paragraph);
    $html = $html."</blockquote>\n";

    return $html;

}








##############################################################
#
#  Function:  LooksLikeMarkdownCodeBlock
#
sub LooksLikeMarkdownCodeBlock
{
    my $str = shift;
    return 1 if ($str =~ /^\s*``/);
    return 0;
}



##############################################################
#
#  Function:  MarkdownToHTMLCodeBlock
#
sub MarkdownToHTMLCodeBlock 
{
    my $str = shift;

    $str =~ s/\s*``\s*\n?//g;

    my $html = "<pre><code>\n";
    
    my %ObservedTabLengths;
    foreach my $line (split(/\n/,$str)) {
        if ($line =~ /^(\s+)\S/) {
            my $tab_length = length($1);
            $ObservedTabLengths{$tab_length} = 1;
        } else {
            $ObservedTabLengths{0} = 1;
        }
    }

    my %InTabLengthToOutTabLength;
    my $tab_scale = 4;
    my $num_tab_lengths = 0;
    foreach my $tab_length (sort { $a <=> $b } keys %ObservedTabLengths) {
        $InTabLengthToOutTabLength{$tab_length} = ($num_tab_lengths * $tab_scale) + 2;
        $num_tab_lengths++;
    }

    foreach my $line (split(/\n/,$str)) {

        my $in_tab_length = 0;
        if ($line =~ /^(\s+)\S/) {
            $in_tab_length = length($1);
        }

        for (my $i=0; $i<$InTabLengthToOutTabLength{$in_tab_length}; $i++) {
            $html = $html.' ';
        }
        $line =~ s/^\s+//;


        $line =~ s/\</\&lt\;/g;
        $line =~ s/\>/\&gt\;/g;


        $html = $html.$line."<br>\n";

    }

    $html = $html."</code></pre>\n";
    return $html;

}






##############################################################
#
#  Function:  ApplyBasicHTMLConversions
#
sub ApplyBasicHTMLConversions 
{

    my $html_in = shift;

    my $html_out = '';
    foreach my $line (split(/\n/,$html_in)) {

        while ($line =~ /^([^\*\*\*]*)\*\*\*([^\*\*\*]+)\*\*\*(.*)$/) {
            my $pre_super_emph_content = $1;
            my $super_emph_content = $2;
            my $post_super_emph_content = $3;
            $line = $pre_super_emph_content.'<em><strong>'.$super_emph_content.'</strong></em>'.$post_super_emph_content;
        }

        while ($line =~ /^([^\*\*]*)\*\*([^\*\*]+)\*\*(.*)$/) {
            my $pre_bold_content = $1;
            my $bold_content = $2;
            my $post_bold_content = $3;
            $line = $pre_bold_content.'<strong>'.$bold_content.'</strong>'.$post_bold_content;
        }

        while ($line =~ /^([^\*]*)\*([^\*]+)\*(.*)$/) {
            my $pre_emph_content = $1;
            my $emph_content = $2;
            my $post_emph_content = $3;
            $line = $pre_emph_content.'<em>'.$emph_content.'</em>'.$post_emph_content;
        }

        while ($line =~ /^([^`]+)`([^`]+)`(.*)$/) {
            my $pre_code_content = $1;
            my $code_content = $2;
            my $post_code_content = $3;
            $line = $pre_code_content.'<code>'.$code_content.'</code>'.$post_code_content;
        }

        while ($line =~ /^([^\!\[]*)\!\[([^\]]+)\]\((\S+)\)(.*)$/) {
            my $pre_img_content = $1;
            my $img_text = $2;
            my $img_file_location = $3;
            my $post_img_content = $4;
            ConfirmFile($img_file_location);
            $line = $pre_img_content.'<img src="'.$img_file_location.'" alt="'.$img_text.'">'.$post_img_content;
        }
       
        while ($line =~ /^([^\[]*)\[([^\]]+)\]\((\S+)\)(.*)$/) {
            my $pre_link_content = $1;
            my $link_text = $2;
            my $link_url = $3;
            my $post_link_content = $4;
            $line = $pre_link_content.'<a href="'.$link_url.'">'.$link_text.'</a>'.$post_link_content;
        }

        while ($line =~ /^([^\<https\:]*)\<(https\:[^\>]+)\>(.*)$/) {
            my $pre_link_content = $1;
            my $link_url = $2;
            my $post_link_content = $3;
            $line = $pre_link_content.'<a href="'.$link_url.'">'.$link_url.'</a>'.$post_link_content;
        }

        while ($line =~ /^(.*)\<(\S+\@\S+)\>(.*)$/) {
            my $pre_email_content = $1;
            my $email_address = $2;
            my $post_email_content = $3;
            $line = $pre_email_content.'<a href="mailto:'.$email_address.'">'.$email_address.'</a>'.$post_email_content;
        }

        $line =~ s/\(tm\)/\&trade\;/g;
        $line =~ s/\(TM\)/\&trade\;/g;

        $line =~ s/\(c\)/\&copy\;/g;
        $line =~ s/\(C\)/\&copy\;/g;

        $line =~ s/\(r\)/\&reg\;/g;
        $line =~ s/\(R\)/\&reg\;/g;

        $line =~ s/\<\-/\&larr\;/;
        $line =~ s/\<\=/\&lArr\;/;

        $line =~ s/\-\>/\&rarr\;/;
        $line =~ s/\=\>/\&rArr\;/;

        $line =~ s/\-\-\-/\&mdash\;/;
        $line =~ s/\-\-/\&ndash\;/;

        $line =~ s/ \"/ \&ldquo\;/;
        $line =~ s/\" /\&rdquo\; /;

        $line =~ s/\.\.\./\&hellip\;/g;

        $html_out = $html_out.$line."\n";

    }

    return $html_out;

}







##############################################################
#
#  Function:  TabifyHTML
#
sub TabifyHTML 
{
    my $html = shift;

    my $num_open_tags = 0;
    my $tab_scale = 5;
    my $out_html = '';

    foreach my $line (split(/\n/,$html)) {

        my $scoot_for_tag_close = 0;
        if ($line =~ /^\<\/[a-z]/) {
            $scoot_for_tag_close = 1;
        }

        my $tab_length = ($num_open_tags - $scoot_for_tag_close) * $tab_scale;
        for (my $i=0; $i<$tab_length; $i++) {
            $out_html = $out_html.' ';
        }
        $out_html = $out_html.$line."\n";

        $line = lc($line);

        $line =~ s/\<br\>//g;
        $line =~ s/\<meta//g;
        $line =~ s/\<link//g;
        
        while ($line =~ /\<[a-z]/) {
            $num_open_tags++;
            $line =~ s/\<[a-z]//;
        }
        while ($line =~ /\<\/[a-z]/) {
            $num_open_tags--;
            $line =~ s/\<\/[a-z]//;
        }

    }

    return $out_html;
   
}







1; # EOF
