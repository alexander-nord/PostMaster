//
// The 'PushSite.pl' script should add the following to this script: 
//
//  + PostTitles - An array of post titles, HTML-formatted
//  + PostURLs   - An array of post URLs
//  + PostDates  - An array of publication dates for posts, HTML-formatted
//  + PostGenres - An array of genre names for each post, as they appear in the url path
//


const posts_per_page = 8;


///////////////////////////////////////////////////
//
// Part 1: Parse the URL to get situated
//


var site_url;
var HTTPMatcher = window.location.href.match(/^(https?:\/+[^\/]+)/);
if (HTTPMatcher)
	site_url = HTTPMatcher[1];
else
	site_url = "http://" + window.location.href.match(/^([^\/]+)/)[1];


var genre = "";
const GenreMatcher = window.location.href.match(/^[^\/]+\/+[^\/]+\/([^\/]+)\//);
if (GenreMatcher)
	genre = GenreMatcher[1];

var pagenum = 1
const PageNumMatcher = window.location.href.match(/\?pagenum=(\d+)/);
if (PageNumMatcher)
	pagenum = PageNumMatcher[1];


///////////////////////////////////////////////////
//
// Part 2: Grab the posts you wanna link to and
//         count the total number of pages this
//         genre's index would have
//         


var post_index  = 0;

var total_genre_count = 0;
while (post_index < PostTitles.length && total_genre_count < (pagenum-1) * posts_per_page) {
	if (!genre || PostGenres[post_index] === genre)
		total_genre_count++;
	post_index++;
}

var PostListHTML = "";
var page_genre_count = 0;
while (post_index < PostTitles.length && page_genre_count < posts_per_page) {
	if (!genre || PostGenres[post_index] === genre) {
		PostListHTML += "<div class=\"genreEntry\">\n";
		PostListHTML += "<div class=\"genreEntryTitle\"><a href=\"";
		PostListHTML += PostURLs[post_index]+"\">"+PostTitles[post_index]+"</a></div>\n";
		PostListHTML += "<div class=\"genreEntryDate\">"+PostDates[post_index]+"</div>\n";
		PostListHTML += "</div>\n";
		page_genre_count++;
		total_genre_count++;
	}
	post_index++;
}

while (post_index < PostTitles.length) {
	if (!genre || PostGenres[post_index] === genre)
		total_genre_count++;
	post_index++;
}

const last_page_num = Math.max(1+Math.floor((total_genre_count-1) / posts_per_page),1);



///////////////////////////////////////////////////
//
// Part 3: Add simple navigators
//

var first_page_url = site_url + "/" + genre;
var prev_page_url  = first_page_url;
if (pagenum > 1)
	prev_page_url  = site_url + "/" + genre + "?pagenum=" + (pagenum - 1);


var last_page_url  = site_url + "/" + genre + "?pagenum=" + last_page_num;
var next_page_url  = last_page_url;
if (pagenum < last_page_num)
	next_page_url  = site_url + "/" + genre + "?pagenum=" + (pagenum + 1);


var PostNavHTML = "<div class=\"genrePageNav\">\n<p>\n";
PostNavHTML    += "<a href=\"" + first_page_url +"\">&ll;</a>\n";
PostNavHTML    += "<a href=\"" +  prev_page_url +"\">&lt;</a>\n";
PostNavHTML    += "<a href=\"" +  next_page_url +"\">&gt;</a>\n";
PostNavHTML    += "<a href=\"" +  last_page_url +"\">&gg;</a>\n";
PostNavHTML    += "</p>\n</div>\n";



///////////////////////////////////////////////////
//
// PART 4: WRITE IT ALL OUT!!!
//

document.write(PostListHTML + "\n" + PostNavHTML);



