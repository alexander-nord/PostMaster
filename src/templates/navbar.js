
///////////////////////////////////////////////////
//
// Part 1: List the three most recent posts
//

const fs = require('fs');

var path_modifier = '';
if (IS_BLOG) path_modifier = '../';  // MAKE SURE this variable (IS_BLOG) is set when we start '<script>'

var RecentPostTuples;
fs.readFile(path_modifier+'../.full-post-list',(err,data) => {
	if (err) 
		throw err;
	RecentPostTuples = data.toString().split(/\n/,3);
});

var PostListHTML = "";
if (RecentPostTuples.length > 0) {
		
	PostListHTML += "<li class=\"navTopic\"><a href=\""+path_modifier+"../index.html\">Recent Posts</a></li>\n";
		
	PostListHTML += "<ul>\n";
	for (var i=0; i<RecentPostTuples.length; i++) {
		
		let postlist_title_pattern = /^\s*\"(.+)\"\s+(\S+)\s*$/;
		let postlist_title = RecentPostTuples[i].match(postlist_title_pattern)[1];
		let postlist_url   = RecentPostTuples[i].match(postlist_title_pattern)[2];

		PostListHTML += "<li class=\"navSubTopic\"><a href=";
		PostListHTML += postlist_url + ">" + postlist_title;
		PostListHTML += "</a></li>\n";

	}
	PostListHTML += "</ul>\n";

}




///////////////////////////////////////////////////
//
// Part 2: List blogpost genre indices
//

var GenreList;
fs.readFile(path_modifier+'../.genre-list',(err,data) => {
	if (err) throw err;
	GenreList = data.toString().split(/\n/);
});

var GenreListHTML = "";
for (var i=0; i<GenreList.length; i++) {
	let genre = GenreList[i];
	GenreListHTML += "<li class=\"navTopic\"><a href=\"../"+path_modifier+genre+"/index.html\">"+genre+"</a></li>\n";
}



///////////////////////////////////////////////////
//
// Part 3: List navbar-approved static pages
//


var StaticTuples;
fs.readFile(path_modifier+'../statics/static-posts',(err,data) => {
	if (err) throw err;
	StaticTuples = data.toString().split(/\n/);
});

var StaticListHTML = "";
for (var i=0; i<StaticTuples.length; i++) {

	let tuple_title_pattern = /^\s*(\".+\")\s+(\S+)\s+(\d)\s*$/;

	let tuple_title    = StaticTuples[i].match(tuple_title_pattern)[1];
	let tuple_url      = StaticTuples[i].match(tuple_title_pattern)[2];
	let tuple_nav_bool = StaticTuples[i].match(tuple_title_pattern)[3];

	if (tuple_nav_bool == 1)
		StaticListHTML += "<li class=\"navTopic\"><a href=\"../"+path_modifier+tuple_url + "\">"+tuple_title+"</a></li>\n";

}



///////////////////////////////////////////////////
//
// Part 4: If we have anything to list, list it!
//

if (PostListHTML || GenreListHTML || StaticListHTML) {
	NavbarHTML  = "<div class=\"rightNav\">\n";
	NavbarHTML += "<ul>\n";
	if (  PostListHTML) NavbarHTML +=   PostListHTML;
	if ( GenreListHTML) NavbarHTML +=  GenreListHTML;
	if (StaticListHTML) NavbarHTML += StaticListHTML;
	NavbarHTML += "</ul>\n";
	NavbarHTML += "</div>\n";
	document.write(NavbarHTML);
}

