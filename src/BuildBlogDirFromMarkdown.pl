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


sub PageDirBuildFail;
sub FixImageLinks;
sub CopyFilesToPageDir;
sub CreatePageDir;



if (@ARGV != 2) {
	die "\n  USAGE:  ./BuildBlogDirFromMarkdown.pl [intended/path/to/dir] [file.md]\n\n";
}



if (-d $ARGV[0]) {
	die "\n  ERROR:  Directory '$ARGV[0]' already exists -- update, don't build! (BuildBlogDirFromMarkdown)\n\n";
}


my $md_file_name = $ARGV[1];
if (!(-e $md_file_name)) {
	die "\n  ERROR:  Failed to locate markdown file '$md_file_name' (BuildBlogDirFromMarkdown.pl)\n\n";
}


my ($dir_name,$created_dirs_ref) = CreatePageDir();

CopyFilesToPageDir($dir_name,$md_file_name);


1;









###################################################################
#
#  Function:  PageDirBuildFail
#
sub PageDirBuildFail
{
	my $err_msg = shift;
	foreach my $dir_name (@{$created_dirs_ref}) { 
		system("rm -rf $dir_name"); 
	}
	die "\n  ERROR: $err_msg (BuildBlogDirFromMarkdown.pl)\n\n";
}






###################################################################
#
#  Function:  FixImageLinks
#
sub FixImageLinks
{
	my $html_str     = shift;
	my $md_dir_name  = shift;
	my $out_dir_name = shift;

	my @Images;
	while ($html_str =~ /<img src="(\S+)"/) {
		push(@Images,$1);
		$html_str =~ s/<img src="\S+"/<img src="" class="blogPic"/;
	}


	foreach my $img (@Images) {

		$img =~ /\/?([^\/]+)$/;
		my $img_id = $1;

		my $src_img = $md_dir_name.$img;
		if (!(-e $src_img)) {
			PageDirBuildFail("Failed to locate image file '$src_img'");
		}

		my $out_img = $dir_name.$img_id;
		my $img_copy_cmd = "cp \"$src_img\" \"$out_img\"";
		if (system($img_copy_cmd)) {
			PageDirBuildFail("Failed to copy image file (command:'$img_copy_cmd')");
		}

		$html_str =~ s/<img src=""/<img src="$img_id"/;

	}

	return $html_str;

}





###################################################################
#
#  Function:  CopyFilesToPageDir
#
sub CopyFilesToPageDir
{
	my $out_dir_name = shift;
	my $md_file_name = shift;

	my $md_dir_name = $WORKING_DIR;
	if ($md_file_name =~ /^(\S*\/)[^\/]+$/) {
		my $md_listed_path = $1;
		if ($md_listed_path =~ /^\~/) {
			$md_listed_path =~ s/^\~/$ENV{'HOME'}/;
		} elsif ($md_listed_path =~ /^\//) {
			$md_dir_name = $md_listed_path;
		} else {
			$md_dir_name = $WORKING_DIR.$md_listed_path;
		}
	}

	my $md_to_html_cmd = 'perl '.$SCRIPT_DIR.'MarkdownToHTML.pl '.$md_file_name.' |';
	open(my $HTMLScanner,$md_to_html_cmd) 
		|| PageDirBuildFail("Failed to run markdown parsing command '$md_to_html_cmd'");

	my $out_html_file_name = $out_dir_name.'.blog.html';
	open(my $OutHTML,'>',$out_html_file_name)
		|| PageDirBuildFail("Failed to open output html file '$out_html_file_name'");

	while (my $line = <$HTMLScanner>) {

		$line = FixImageLinks($line,$md_dir_name,$out_dir_name);

		print $OutHTML "$line";

	}
	close($HTMLScanner);


	my $out_md_file_name = $out_dir_name.'.blog.md';
	my $md_copy_cmd = "cp \"$md_file_name\" \"$out_md_file_name\"";
	if (system($md_copy_cmd)) {
		PageDirBuildFail("Failed to copy markdown file to output directory (command:'$md_copy_cmd')");
	}

}






###################################################################
#
#  Function:  CreatePageDir
#
sub CreatePageDir
{
	my @CreatedDirs; # In case something fails, we'll want to undo any useless dir creation
	my $dir_name = '';
	for my $dir_element (split(/\//,$ARGV[0])) {

		# We need to be careful with the first element!
		if (!$dir_name) {
			if ($dir_element eq '~') {
				$dir_name = $ENV{'HOME'};
				$dir_name = $dir_name.'/' if ($dir_name !~ /\/$/);
				next;
			} elsif ($ARGV[0] !~ /^\//) {
				$dir_name = $WORKING_DIR;
			} else {
				$dir_name = '/';
			}
		}
		next if (!$dir_element); # This shouldn't happen, but I guess it's okay...


		$dir_name = $dir_name.$dir_element.'/';

		if (!(-d $dir_name)) {
			if (system("mkdir $dir_name")) {
				PageDirBuildFail("Creation of directory '$dir_name'");
			} else {
				push(@CreatedDirs,$dir_name);
			}
		}

	}

	return ($dir_name,\@CreatedDirs);

}


