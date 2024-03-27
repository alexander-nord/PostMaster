use warnings;
use strict;
use POSIX;




###################################################################
#
#  Function:  FixLinks
#
sub FixLinks
{
	
	my $html_str     = shift;
	my $md_dir_name  = shift;
	my $out_dir_name = shift;

	
	my @TagLines = split(/</,$html_str);

	$html_str = $TagLines[0];
	for (my $tag_index = 1; $tag_index < scalar(@TagLines); $tag_index++) {
		
		my $tag_line = $TagLines[$tag_index];
		
		if ($tag_line =~ /^\s*a\s+.*href="([^"]+)"/) {
			
			my $link = $1;

			if (-e $md_dir_name.$link) {
				$link = $md_dir_name.$link;
			}

			if (-e $link) {
				
				$link =~ /\/?([^\/]+)$/;
				my $source_base_name = $1;
				
				my $target_file_name = $out_dir_name.$source_base_name;
				my $cp_cmd = "cp \"$link\" \"$target_file_name\"";

				return 0 if (system($cp_cmd));

				$tag_line =~ s/href="[^"]+"/href="$source_base_name"/;

			} else {

				# Either a webpage or an email address... BUT WHICH?!
				if ($link !~ /\// && $link =~ /^[^\/]+@[^\/]+$/) {
					$link = 'mailto:'.$link;
				} else {
					$link = 'http://'.$link if ($link !~ /^http/);
				}

				$tag_line =~ s/href="[^"]+"/href="$link"/;

			}

		} elsif ($tag_line =~ /^\s*img\s+.*src="([^"]+)"/) {

			my $img_file_name = $1;

			if (!(-e $img_file_name)) {
				if (-e $md_dir_name.$img_file_name) {
					$img_file_name = $md_dir_name.$img_file_name;
				} else {
					return 0;
				}
			}

			$img_file_name =~ /\/([^\/]+)$/;
			my $source_img_name = $1;

			my $target_img_name = $out_dir_name.$source_img_name;
			my $cp_cmd = "cp \"$img_file_name\" \"$target_img_name\"";

			return 0 if (system($cp_cmd));

			$tag_line =~ s/src=\"[^\"]+\"/class="blogPic" src="$source_img_name"/;

		}

		$html_str = $html_str.'<'.$tag_line;

	}

	return $html_str;

}




1;