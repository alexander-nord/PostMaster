//
// The 'PushSite.pl' script should add the following to this script: 
//
//  +   PostTitles,   PostURLs
//  +  GenreTitles,  GenreURLs
//  + StaticTitles, StaticURLs
//


const site_url = window.location.href.match(/^([^\/]+\/+[^\/]+)/)[1];



///////////////////////////////////////////////////
//
// Part 1: List the three most recent posts
//
var PostListHTML = "";
if (PostTitles.length > 0) {
	PostListHTML += "<li class=\"navTopic\"><a href=\""+site_url+"\">Recent Posts</a></li>\n";
	PostListHTML += "<ul>\n";
	for (var i=0; i<PostTitles.length; i++) {
		PostListHTML += "<li class=\"navSubTopic\"><a href=";
		PostListHTML += PostURLs[i]+">"+PostTitles[i];
		PostListHTML += "</a></li>\n";
	}
	PostListHTML += "</ul>\n";
}



///////////////////////////////////////////////////
//
// Part 2: List blogpost genre indices
//
var GenreListHTML = "";
for (var i=0; i<GenreTitles.length; i++) {
	GenreListHTML += "<li class=\"navTopic\"><a href=";
	GenreListHTML += GenreURLs[i]+">"+GenreTitles[i];
	GenreListHTML += "</a></li>\n";
}



///////////////////////////////////////////////////
//
// Part 3: List navbar-approved static pages
//
var StaticListHTML = "";
for (var i=0; i<StaticTitles.length; i++) {
	StaticListHTML += "<li class=\"navTopic\"><a href=";
	StaticListHTML += StaticURLs[i]+">"+StaticTitles[i];
	StaticListHTML += "</a></li>\n";
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

