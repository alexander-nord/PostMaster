#!/usr/bin/env perl
#
#  RemoveBlog.pl - Alex Nord, 2022
#
use warnings;
use strict;
use POSIX;


sub LocateScript { return './' if ($0 !~ /\//); $0 =~ /^(.*\/)[^\/]+$/; return $1; }
use lib LocateScript();
use bureaucracy;


sub RevertToTwoGenres;



if (@ARGV != 5) { die "\n  USAGE:  ./MergeGenres.pl [Site-Name] [Genre-1] [Genre-2] [Resulting-Genre-Name] [Genre-Description.md]\n\n"; }



my $site_name = $ARGV[0];

my $src_dir_name = LocateScript();
my $site_dir_name = $src_dir_name;

if ($site_dir_name eq './') {
	$site_dir_name = ConfirmDirectory('../sites/'.$site_name);
} else {
	$site_dir_name =~ s/src\/?$//;
	$site_dir_name = ConfirmDirectory($site_dir_name.'sites/'.$site_name);
}


my $formatted_genre1_name = lc($ARGV[1]);
$formatted_genre1_name =~ s/\s/\_/g;

my $formatted_genre2_name = lc($ARGV[2]);
$formatted_genre2_name =~ s/\s/\_/g;

my $genre1_dir_name = ConfirmDirectory($site_dir_name.$formatted_genre1_name);
my $genre2_dir_name = ConfirmDirectory($site_dir_name.$formatted_genre2_name);



my $new_genre_name = $ARGV[3];
my $formatted_new_genre_name = lc($new_genre_name);
$formatted_new_genre_name =~ s/\s/\_/g;

my $tmp_dir_name = CreateDirectory($site_dir_name.'tmp');
my $tmp_genre1_dir_name = $tmp_dir_name.$formatted_genre1_name;
my $tmp_genre2_dir_name = $tmp_dir_name.$formatted_genre2_name;
RunSystemCommand("mv $genre1_dir_name $tmp_genre1_dir_name");
RunSystemCommand("mv $genre2_dir_name $tmp_genre2_dir_name");


my $add_genre_cmd = 'perl '.$src_dir_name.'AddGenre.pl '.$site_name.' '.$new_genre_name.' '.$ARGV[4];

if (system($add_genre_cmd)) {
	RevertToTwoGenres();
	die "\n  ERROR:  Failed to add new genre (command '$add_genre_cmd' returned non-0)\n\n";
}

my $new_dir_name = $site_dir_name.$formatted_new_genre_name.'/';

if (!(-d $new_dir_name)) {
	RevertToTwoGenres();
	print "\n";
	print "  ERROR:  I can't find the new directory! (looking for '$new_dir_name')\n"; 
	print "          Contact Alex if you see this error -- it shouldn't be possible!\n";
	die "\n";
}

my $recents_filename = $site_dir_name.'recent-posts';
if (!(-e $recents_filename)) {
	RevertToTwoGenres();
	die "\n  ERROR:  Failed to locate recent posts file '$recents_filename'\n\n";
}
my $tmp_recents_filename = $recents_filename.'.tmp';


my $InRecentsFile = OpenInputFile($recents_filename);
my $TmpRecentsFile = OpenOutputFile($tmp_recents_filename);
my $GenreRecentsFile = OpenOutputFile($new_dir_name.'recent-posts');
while (my $line = <$InRecentsFile>) {

	$line =~ s/\n|\r//g;
	next if (!$line);

	if ($line =~ /\/$formatted_genre1_name\/(\S+)$/) {

		my $html_fname = $1;

		RunSystemCommand("cp \"$tmp_genre1_dir_name$html_fname\" \"$new_dir_name$html_fname\"");

		$line =~ s/\/$formatted_genre1_name\//\/$formatted_new_genre_name\//;
		print $GenreRecentsFile "$line\n";

	} elsif ($line =~ /\/$formatted_genre2_name\/(\S+)/) {

		my $html_fname = $1;

		RunSystemCommand("cp \"$tmp_genre2_dir_name$html_fname\" \"$new_dir_name$html_fname\"");

		$line =~ s/\/$formatted_genre2_name\//\/$formatted_new_genre_name\//;
		print $GenreRecentsFile "$line\n";

	}

	print $TmpRecentsFile "$line\n";


}
close($InRecentsFile);
close($TmpRecentsFile);
close($GenreRecentsFile);

RunSystemCommand("mv $tmp_recents_filename $recents_filename");
RunSystemCommand("rm -rf $tmp_dir_name");


1;







#######################################################################
#
#  Function:  RevertToTwoGenres
#
sub RevertToTwoGenres
{
	RunSystemCommand("mv $tmp_genre1_dir_name $genre1_dir_name");
	RunSystemCommand("mv $tmp_genre2_dir_name $genre2_dir_name");
	RunsystemCommand("rm -rf $new_dir_name");
	RunSystemCommand("rm -rf $tmp_dir_name");
}








