
///////////////////////////////////////////////////
//
// Part 1: Get the URL so we know what page we're on
//


const url = window.location.href;


// Format should be site.ext/genre/index.html&pagenum=[int] (or no '&pagenum=[int]')
let pagenum_pattern = /^(.+)\&pagenum=(\d+)$/;
var base_url = url;
var pagenum = 1
if (url.match(pagenum_pattern).length > 2) {
	base_url = url.match(pagenum_pattern)[1];
	pagenum  = url.match(pagenum_pattern)[2];
}




///////////////////////////////////////////////////
//
// Part 2: Read the next 10 posts (or until we hit the end of the genre-speciific "recent-posts" file)
//


const fs = require('fs');


if (fs.existsSync(post_list_fname)) {

	var RecentPostTuples;
	fs.readFile(post_list_fname,(err,data) => {
		if (err) throw err;
		RecentPostTuples = data.toString().split(/\n/);
	});

	var start_post_id = (pagenum - 1) * 10;
	var end_post_id   = start_post_id + 10;
	if (end_post_id >= RecentPostTuples.length)
		end_post_id  = RecentPostTuples.length;

	var last_page_num = 1 + int(RecentPostTuples.length / 10);

	var PostListHTML = "\n";
	for (var post_id=start_post_id; post_id<end_post_id; post_id++) {

		let post_title_pattern = /^\s*(\".+\")\s+(\S+)\s*$/;
		let post_title = RecentPostTuples[post_id].match(post_title_pattern)[1];
		let post_url   = RecentPostTuples[post_id].match(post_title_pattern)[2];

		PostListHTML += "<div class=\"genreEntry\">\n";
		PostListHTML += "<div class=\"genreEntryTitle\"><a href=\"";
		PostListHTML += post_url+"\">"+post_title+"</a></div>\n";
		PostListHTML += "</div>\n";

	}

}



///////////////////////////////////////////////////
//
// Part 3: Add simple navigators
//


var first_page_url = "";
var prev_page_url  = "";
if (pagenum > 1) {
	first_page_url = base_url;
	prev_page_url  = base_url + "&pagenum=" + (pagenum - 1);
}

var next_page_url = "";
var last_page_url = "";
if (pagenum < last_page_num) {
	next_page_url = base_url + "&pagenum=" + (pagenum + 1);
	last_page_url = base_url + "&pagenum=" + last_page_num;
}

PostNavHTML  = "<div class=\"genrePageNav\">\n";
PostNavHTML += "<p>\n";

if (first_page_url) PostNavHTML += "<a href=\"" + first_page_url +"\">";
PostNavHTML += "&ll;";
if (first_page_url) PostNavHTML += "</a>";
PostNavHTML += "&Tab;";
	
if (prev_page_url) PostNavHTML += "<a href=\"" + prev_url +"\">";
PostNavHTML += "&lt;";
if (prev_page_url) PostNavHTML += "</a>";
PostNavHTML += "&Tab;";

if (next_page_url) PostNavHTML += "<a href=\"" + next_page_url +"\">";
PostNavHTML += "&gt;";
if (next_page_url) PostNavHTML += "</a>";
PostNavHTML += "&Tab;";

if (last_page_url) PostNavHTML += "<a href=\"" + last_page_url +"\">";
PostNavHTML += "&gg;";
if (last_page_url) PostNavHTML += "</a>";
PostNavHTML += "\n";
	
PostNavHTML += "</p>\n";
PostNavHTML += "</div>\n";



///////////////////////////////////////////////////
//
// PART 4: WRITE IT ALL OUT!!!
//

document.write(PostListHTML + "\n" + PostNavHTML);

