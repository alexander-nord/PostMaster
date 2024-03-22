
const fs = require('fs');


///////////////////////////////////////////////////
//
// Part 1: List the three most recent posts
//

var full_list_name = path_to_landing+'.full-post-list';
var PostListHTML = "";

if (fs.existsSync(full_list_name)) {

	var RecentPostTuples;
	fs.readFile(path_to_landing+'.full-post-list',(err,data) => {
		if (err) throw err;
		RecentPostTuples = data.toString().split(/\n/,3);
	});

	if (RecentPostTuples.length > 0) {
		
		PostListHTML += "<li class=\"navTopic\"><a href=\""+path_to_landing+"index.html\">Recent Posts</a></li>\n";
		
		PostListHTML += "<ul>\n";
		for (var i=0; i<RecentPostTuples.length; i++) {
		
			let postlist_title_pattern = /^\s*\"(.+)\"\s+(\S+)\s*$/;
			let postlist_title = RecentPostTuples[i].match(postlist_title_pattern)[1];
			let postlist_url   = RecentPostTuples[i].match(postlist_title_pattern)[2];

			PostListHTML += "<li class=\"navSubTopic\"><a href=";
			PostListHTML += postlist_url+">"+postlist_title;
			PostListHTML += "</a></li>\n";

		}
		PostListHTML += "</ul>\n";
	
	}

}




///////////////////////////////////////////////////
//
// Part 2: List blogpost genre indices
//

var genre_list_name = path_to_landing+'.genre-list';
var GenreListHTML = "";

if (fs.existsSync(genre_list_name)) {
	
	var GenreListTuples;
	fs.readFile(genre_list_name,(err,data) => {
		if (err) throw err;
		GenreListTuples = data.toString().split(/\n/);
	});

	for (var i=0; i<GenreListTuples.length; i++) {

		let genre_pattern = /^\s*\"(.+)\"\s+(\S+)\s*$/;
		let genre_title = GenreListTuples[i].match(postlist_title_pattern)[1];
		let genre_path  = GenreListTuples[i].match(postlist_title_pattern)[2];

		GenreListHTML += "<li class=\"navTopic\"><a href=\"";
		GenreListHTML += path_to_landing+genre_path+"/index.html\">";
		GenreListHTML += genre_title+"</a></li>\n";

	}

}



///////////////////////////////////////////////////
//
// Part 3: List navbar-approved static pages
//


var static_list_name = path_to_landing+'statics/.static-post-list';
var StaticListHTML = "";

if (fs.existsSync(static_list_name)) {

	var StaticTuples;
	fs.readFile(path_to_landing+'statics/.static-post-list',(err,data) => {
		if (err) throw err;
		StaticTuples = data.toString().split(/\n/);
	});

	for (var i=0; i<StaticTuples.length; i++) {

		let tuple_title_pattern = /^\s*\"(.+)\"\s+(\S+)\s+(\d)\s*$/;

		let tuple_title    = StaticTuples[i].match(tuple_title_pattern)[1];
		let tuple_url      = StaticTuples[i].match(tuple_title_pattern)[2];
		let tuple_nav_bool = StaticTuples[i].match(tuple_title_pattern)[3];

		if (tuple_nav_bool == 1) {
			StaticListHTML += "<li class=\"navTopic\"><a href=\"";
			StaticListHTML += path_to_landing+tuple_url+"\">";
			StaticListHTML += tuple_title+"</a></li>\n";
		}

	}
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

