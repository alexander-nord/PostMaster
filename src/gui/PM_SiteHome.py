import os
import re
import subprocess

import PM_GUI_Generics as PMGUI
import PM_Editor

import tkinter as tk
import tkinter.filedialog as tkfd
from tkinter import ttk


#
#  NOTE:  This is a bit of a mess, and should probably be broken into
#         submodules, but that's just part of the charm, right?
#
#   + __init__
#   + SiteExists
#   + GetGenres
#
#   + Publish
#
#   + New
#   |
#   |  - DestroyNewWindow
#   |
#   |  - InitNewBlogPost
#   |     - DestroyNewBlogWindow
#   |     - CheckValidNewBlog
#   |
#   |  - InitNewStaticPage
#   |     - DestroyNewStaticWindow
#   |     - CheckValidNewStatic
#   |
#   |  - CreateNewBlogGenre
#   |     - DestroyNewGenreWindow
#   |     - CheckValidNewGenre
#
#   + Edit
#
#   + Delete
#
#   + SetSiteDisplay
#   + GetUsageStr
#   + SiteStructureToStr
#   + DirDiveToStr
#
#   + Exit
#


class PM_SiteHome:

	PARENT_WINDOW=None
	SITE_NAME=None
	SITE_DIR=None
	META_DIR=None

	GENRES=None

	DISPLAY_INDENT='     ' # Used for the lil' text display


	def __init__ (self,parent_window=None,site_dir=None):


		if parent_window:
			self.PARENT_WINDOW = parent_window
			self.PARENT_WINDOW.withdraw()


		site_name_extract = re.match('^(.*\/)([^\/]+)\/$',site_dir)

		self.SITE_NAME = site_name_extract.group(2)
		self.SITE_DIR  = site_dir
		self.META_DIR  = site_name_extract.group(1) + site_name_extract.group(2) + "-PostMaster-Data/"

		if not self.SiteExists():
			self.Exit()

		self.GetGenres()

		self.window = PMGUI.NewWindow(parent_window=self.PARENT_WINDOW)[0]

		PMGUI.SetWindowTitle(self.window,self.SITE_NAME)


		self.window.rowconfigure([1,2],weight=1)
		self.window.columnconfigure([1,2,3,4,5],weight=1)


		# ROW 1: Buttons to guide basic functionality

		publish_button = tk.Button(self.window, width=4, height=2, text="Publish", command=self.Publish)
		write_button   = tk.Button(self.window, width=4, height=2, text="New",     command=self.New    )
		edit_button    = tk.Button(self.window, width=4, height=2, text="Edit",    command=self.Edit   )
		delete_button  = tk.Button(self.window, width=4, height=2, text="Delete",  command=self.Delete )
		exit_button    = tk.Button(self.window, width=4, height=2, text="Exit",    command=self.Exit   )

		publish_button.grid(row=1,column=1,sticky="new",padx=10,pady=5)
		write_button.grid(  row=1,column=2,sticky="new",padx=10,pady=5)
		edit_button.grid(   row=1,column=3,sticky="new",padx=10,pady=5)
		delete_button.grid( row=1,column=4,sticky="new",padx=10,pady=5)
		exit_button.grid(   row=1,column=5,sticky="new",padx=10,pady=5)

		
		# ROW 2: lil' display for our friends

		self.site_display = tk.Text(self.window,state='disabled', font=("Menlo",14))
		self.site_display.grid(row=2, column=1, columnspan=5, padx=10, pady=5, sticky="sew")

		self.SetSiteDisplay("usage and structure")


		# Let 'er rip!
		self.window.mainloop()




	#
	#  DEF: SiteExists
	#
	def SiteExists (self):
		if not os.path.isdir(self.SITE_DIR):
			return False
		if not os.path.isdir(self.META_DIR):
			return False
		if not os.path.isfile(self.META_DIR + "metadata"):
			return False
		return True # If you're tricking me, good work, trickster!



	#
	#  DEF: GetGenres
	#
	def GetGenres (self):

		if not os.path.isfile(self.META_DIR+'genre-list'):
			self.GENRES = None
			return

		GenreFile = open(self.META_DIR+'genre-list','r')

		GenreList = []

		for line in GenreFile:
			if line != "\n":
				GenreList.append(line.rstrip())

		GenreFile.close()

		if len(GenreList) > 0:
			GenreList.sort()
			self.GENRES = GenreList
		else:
			self.GENRES = None



	#
	#  DEF: Publish
	#
	def Publish (self):
		self.Exit()



	#
	#  DEF: New
	#
	def New (self):

		NewWindow = PMGUI.NewWindow(parent_window=self.window,width=300,height=250)[0]
		PMGUI.SetWindowTitle(NewWindow,f"{self.SITE_NAME} - New")

		NewWindow.rowconfigure([1,2,3,4],weight=1)
		NewWindow.columnconfigure([1],weight=1)


		def DestroyNewWindow():
			
			NewWindow.quit()
			NewWindow.destroy()


		def InitNewBlogPost():

			DestroyNewWindow()

			if not self.GENRES:
				no_genres_err_text = "You need to create at least one genre\n   before you can start blogging!"
				PMGUI.ErrorWindow(title="No Genres Found",text=no_genres_err_text,height=100)
				return


			new_blog_window = PMGUI.NewWindow(width=400,height=100)[0]
			PMGUI.SetWindowTitle(new_blog_window,f"{self.SITE_NAME} - New Blog Post")

			new_blog_window.rowconfigure([1,2,3],weight=1)
			new_blog_window.columnconfigure([1,2,3,4],weight=1)

			default_genre_text = "-- Select Genre --"
			selected_genre = tk.StringVar(new_blog_window,default_genre_text)
			intended_title = tk.StringVar(new_blog_window,None)

			title_label, title_entry    = PMGUI.AddLabelAndEntry(new_blog_window,"Blog Title",intended_title,1)
			genre_label, genre_dropdown = PMGUI.AddLabelAndDropdown(new_blog_window,"Blog Genre",self.GENRES,selected_genre,2)

			title_entry.grid(columnspan=3)
			genre_dropdown.grid(columnspan=3)


			BlogMeta = {}


			def DestroyNewBlogWindow():
				
				new_blog_window.quit()
				new_blog_window.destroy()


			def CheckValidNewBlog():

				blog_title = intended_title.get().lstrip().rstrip()
				blog_genre = selected_genre.get()

				new_blog_err_msg    = ""
				new_blog_err_height = 90
				if not blog_title:				
					new_blog_err_msg    += "\nBlog title is required\n"
					new_blog_err_height += 30
				if blog_genre == default_genre_text:
					new_blog_err_msg    += "\nBlog genre is required\n"
					new_blog_err_height += 30

				if new_blog_err_msg:
					
					PMGUI.ErrorWindow(title="ERROR",text=new_blog_err_msg,height=new_blog_err_height)

				else:

					BlogMeta["title"] = blog_title
					BlogMeta["genre"] = blog_genre
					
					DestroyNewBlogWindow()


			cancel_button = tk.Button( new_blog_window, text="Cancel", command=DestroyNewBlogWindow )
			create_button = tk.Button( new_blog_window, text="Create", command=CheckValidNewBlog    )

			cancel_button.grid(row=3,column=3,padx=20,pady=5,sticky="ne")
			create_button.grid(row=3,column=4,padx=20,pady=5,sticky="nw")

			new_blog_window.mainloop()


			# Did the user decide not to share their deepest thoughts on the Internet?
			blog_title = BlogMeta.get("title")
			blog_genre = BlogMeta.get("genre")
			if not (blog_title and blog_genre):
				return


			# Is there a draft folder corresponding to this genre?
			blog_dir_name = self.SITE_DIR + 'drafts/' + blog_genre + '/'
			if not os.path.isdir(blog_dir_name):
				os.mkdir(blog_dir_name)

			# Let's title this draft!
			blog_file_name = blog_title
			blog_file_name = re.sub('\'','\\\'',blog_file_name)
			blog_file_name = re.sub('\"','\\\"',blog_file_name)
			
			blog_file_name = blog_dir_name + blog_file_name

			file_name_check = blog_file_name + '.md'
			check_num = 1
			while os.path.isfile(file_name_check):
				check_num += 1
				file_name_check = blog_file_name + check_num + '.md'
			blog_file_name = file_name_check

			BlogDraft = open(blog_file_name,'w')
			BlogDraft.write(f"# {blog_title}\n")
			BlogDraft.close()

			# Let the people write!
			BlogEditor = PM_Editor.PM_Editor(parent_window=self.window,title=blog_title,file_name=blog_file_name)

			self.SetSiteDisplay("usage and structure")


		def InitNewStaticPage():

			DestroyNewWindow()

			new_static_window = PMGUI.NewWindow(width=400,height=100)[0]
			PMGUI.SetWindowTitle(new_static_window,f"{self.SITE_NAME} - New Static Page")

			new_static_window.rowconfigure([1,2,3],weight=1)
			new_static_window.columnconfigure([1,2,3,4],weight=1)

			intended_title   = tk.StringVar(new_static_window,None)
			navbar_page_link = tk.StringVar(new_static_window,None)

			checkbox_text = "Add a link to this page on the navbar?"
			title_label, title_entry = PMGUI.AddLabelAndEntry(new_static_window,"Static Page Title",intended_title,1,label_col=1,entry_col=3)
			checkbox_label, checkbox = PMGUI.AddLabelAndCheckbox(new_static_window,checkbox_text,navbar_page_link,2,label_col=1,checkbox_col=4)

			title_label.grid(columnspan=2,sticky="nw")
			title_entry.grid(columnspan=2,sticky="new",padx=20)

			checkbox_label.grid(columnspan=3,sticky="nw")
			checkbox.grid(sticky="n",padx=20)


			StaticMeta = {}


			def DestroyNewStaticWindow():
				new_static_window.quit()
				new_static_window.destroy()

			def CheckValidNewStatic():

				static_title = intended_title.get().lstrip().rstrip()
				add_nav_link = navbar_page_link.get()

				if not static_title:
					
					PMGUI.ErrorWindow(title="ERROR",text="\nTitle is required\n",height=120)

				else:

					StaticMeta["title"] = static_title

					if (add_nav_link == "on"):
						StaticMeta["nav_link"] = True
					else:
						StaticMeta["nav_link"] = False

					DestroyNewStaticWindow()



			cancel_button = tk.Button( new_static_window, text="Cancel", command=DestroyNewStaticWindow )
			create_button = tk.Button( new_static_window, text="Create", command=CheckValidNewStatic    )

			cancel_button.grid(row=3,column=3,padx=20,pady=5,sticky="ne")
			create_button.grid(row=3,column=4,padx=20,pady=5,sticky="nw")

			new_static_window.mainloop()


			# Did the user decide not to create this static page?
			static_title = StaticMeta.get("title")
			add_nav_link = StaticMeta.get("nav_link")
			if not static_title:
				return


			# Is there a draft folder corresponding to this genre?
			static_drafts_dir_name    = self.SITE_DIR + 'drafts/statics/'
			linked_statics_dir_name   = static_drafts_dir_name + '1/'
			unlinked_statics_dir_name = static_drafts_dir_name + '0/'
			
			# Name the file that we'll write to
			static_file_name = static_title
			static_file_name = re.sub('\'','\\\'',static_file_name)
			static_file_name = re.sub('\"','\\\"',static_file_name)
			
			# Confirm that there isn't any file that this would conflict with
			if os.path.isfile(self.SITE_DIR + 'statics/' + static_file_name + '.html'):
				PMGUI.ErrorWindow(title="ERROR",text=f"\nA '{static_title}' page has already been published!\n",height=120)
			elif os.path.isfile(linked_statics_dir_name + static_file_name + '.md') or os.path.isfile(unlinked_statics_dir_name + static_file_name + '.md'):
				PMGUI.ErrorWindow(title="ERROR",text=f"\nA '{static_title}' page is already being drafted\n",height=120)

			# Now that we know it's safe to write this file, make sure we have
			# the required directory structure!
			if not os.path.isdir(static_drafts_dir_name):
				os.mkdir(static_drafts_dir_name)
				os.mkdir(linked_statics_dir_name)
				os.mkdir(unlinked_statics_dir_name)

			if add_nav_link:
				static_file_name = linked_statics_dir_name   + static_file_name + '.md'
			else:
				static_file_name = unlinked_statics_dir_name + static_file_name + '.md'

			StaticDraft = open(static_file_name,'w')
			StaticDraft.write(f"# {static_title}\n")
			StaticDraft.close()

			# Let the people write!
			StaticEditor = PM_Editor.PM_Editor(parent_window=self.window,title=static_title,file_name=static_file_name)

			self.SetSiteDisplay("usage and structure")



		def CreateNewBlogGenre():
		
			DestroyNewWindow()

			new_genre_window = PMGUI.NewWindow(width=400,height=175)[0]
			PMGUI.SetWindowTitle(new_genre_window,f"{self.SITE_NAME} - New Genre")

			new_genre_window.rowconfigure([1,2,3],weight=1)
			new_genre_window.columnconfigure([1,2,3,4],weight=1)

			intended_name = tk.StringVar(new_genre_window,None)
			intended_desc = tk.StringVar(new_genre_window,None)

			name_label, name_entry = PMGUI.AddLabelAndEntry(new_genre_window,"Blog Genre Name",intended_name,row=1)
			#desc_label, desc_entry = PMGUI.AddLabelAndEntry(new_genre_window,"Genre Description",intended_desc,row=2)

			name_label.configure(height=1)
			name_label.grid(padx=15,pady=5,sticky="ne")
			name_entry.grid(padx= 5,pady=5,sticky="nw",columnspan=3)
			#desc_entry.grid(columnspan=3)

			desc_prompt = "[Genre Description]"
			desc_entry = tk.Text(new_genre_window,font=("Helvetica",14),height=5)
			desc_entry.grid(row=2,column=1,columnspan=4,padx=15,pady=5,sticky="sew")
			desc_entry.insert(tk.END,desc_prompt)

			GenreMeta = {}

			def DestroyNewGenreWindow():
				new_genre_window.quit()
				new_genre_window.destroy()

			def CheckValidNewGenre():

				genre_name = intended_name.get().lstrip().rstrip()
				genre_desc = desc_entry.get("1.0","end-1c").lstrip().rstrip()

				new_genre_err_msg    = ""
				new_genre_err_height = 90

				if not genre_name:
					new_genre_err_msg    += "\nGenre name is required\n"
					new_genre_err_height += 30
				elif os.path.isdir(self.SITE_DIR + genre_name):
					new_genre_err_msg    += f"\nGenre {genre_name} already exists\n"
					new_genre_err_height += 30

				if genre_desc == desc_prompt:
					new_genre_err_msg    += "\nGenre description is required\n"
					new_genre_err_height += 30

				if new_genre_err_msg:
					
					PMGUI.ErrorWindow(title="ERROR",text=new_genre_err_msg,height=new_genre_err_height)

				else:

					GenreMeta["name"] = genre_name
					GenreMeta["desc"] = genre_desc
					
					DestroyNewGenreWindow()

			cancel_button = tk.Button( new_genre_window, text="Cancel", height=1, command=DestroyNewGenreWindow )
			create_button = tk.Button( new_genre_window, text="Create", height=1, command=CheckValidNewGenre    )

			cancel_button.grid(row=3,column=2,padx=20,pady=5,sticky="ne")
			create_button.grid(row=3,column=3,padx=20,pady=5,sticky="nw")

			new_genre_window.mainloop()

			# Are we stoked?!
			genre_name = GenreMeta.get("name")
			genre_desc = GenreMeta.get("desc")
			if not (genre_name and genre_desc):
				return

			# AWESOME! We'll make a temporary file with the description and send this up the chain
			desc_file_name = self.META_DIR + genre_name + '-desc.md'
			with open(desc_file_name,"w") as DescFile:
				DescFile.write(f"# {genre_name}\n")
				DescFile.write(genre_desc)

			add_genre_script  = os.path.dirname(os.path.realpath(__file__)) + "/../AddGenre.pl"
			os.system(f"perl {add_genre_script} \"{self.SITE_NAME}\" \"{genre_name}\" \"{desc_file_name}\"")

			# Assuming we've done what we need to, clean up!
			os.system(f"rm \"{desc_file_name}\"")

			self.GetGenres()
			self.SetSiteDisplay("usage and structure")


		blog_button   = tk.Button(NewWindow,width=20,height=5,text="Write New Blog Post"  ,command=InitNewBlogPost    )
		static_button = tk.Button(NewWindow,width=20,height=5,text="Write New Static Page",command=InitNewStaticPage  )
		genre_button  = tk.Button(NewWindow,width=20,height=5,text="Create New Blog Genre",command=CreateNewBlogGenre )
		cancel_button = tk.Button(NewWindow,width=20,height=5,text="Cancel"               ,command=DestroyNewWindow   )

		blog_button.grid(  row=1,column=1,padx=10,pady=5)
		static_button.grid(row=2,column=1,padx=10,pady=5)
		genre_button.grid( row=3,column=1,padx=10,pady=5)
		cancel_button.grid(row=4,column=1,padx=10,pady=5)

		NewWindow.mainloop()




	#
	#  DEF: Edit
	#
	def Edit (self):
		self.Exit()





	#
	#  DEF: Delete
	#
	def Delete (self):
		self.Exit()





	#
	#  DEF: SetSiteDisplay
	#
	def SetSiteDisplay (self, opt=None):

		display_text = ""

		if opt == "usage and structure":
			display_text = self.GetUsageStr() + self.SiteStructureToStr()

		elif opt == "structure":
			display_text = self.SiteStructureToStr()

		self.site_display.configure(state='normal')
		self.site_display.delete('1.0',tk.END)
		self.site_display.insert(tk.END,display_text)
		self.site_display.configure(state='disabled')



	#
	#  DEF: GetUsageStr
	#
	def GetUsageStr (self):

		UsageLines = []
		UsageLines.append("Basic Usage Guide")
		UsageLines.append("-----------------")
		UsageLines.append("")
		UsageLines.append("  Publish:  Publish new/edited content to the website.")
		UsageLines.append("")
		UsageLines.append("  New    :  Draft a new blog post or static page")
		UsageLines.append("            OR create a new blog post genre.")
		UsageLines.append("")
		UsageLines.append("  Edit   :  Edit an existing blog post, blog draft, or static page")
		UsageLines.append("            OR re-name a blog post genre or merge two genres.")
		UsageLines.append("")
		UsageLines.append("  Delete :  Delete an existing blog post, static page, or draft.")
		UsageLines.append("")
		UsageLines.append("  Exit   :  Close the current window.")
		

		usage_str = "\n\n\n"
		for line in UsageLines:
			usage_str += self.DISPLAY_INDENT + line + "\n"

		return usage_str + "\n\n"


	#
	#  DEF: SiteStructureToStr
	#
	def SiteStructureToStr (self):

		indent_len = 4

		site_structure_str  = "\n" 
		site_structure_str += self.DISPLAY_INDENT +            self.SITE_NAME   + "\n"
		site_structure_str += self.DISPLAY_INDENT + ('-' * len(self.SITE_NAME)) + "\n"

		site_structure_str += self.DirDiveToStr(self.SITE_DIR,0,indent_len,self.DISPLAY_INDENT)

		return site_structure_str + "\n\n\n"



	#
	#  DEF: DirDiveToStr
	#
	def DirDiveToStr (self, dir_name, depth, indent_len, indent_str):

		DirContents = os.listdir(dir_name)
		SubDirs  = []
		DirFiles = []

		for dir_item in DirContents:

			if (re.match('^\.',dir_item)):
				continue

			elif (os.path.isdir(dir_name + dir_item)):
				SubDirs.append(dir_item)

			else:
				DirFiles.append(dir_item)


		indent_str += (' ' * (indent_len-1))


		# The string we'll ultimately return
		dir_level_str = ""


		if (len(DirFiles) > 0):

			DirFiles.sort()
	
			for dir_file_name in DirFiles:
				dir_level_str += indent_str + ":\n"
				dir_level_str += indent_str + "+= " + dir_file_name + "\n"


		if (len(SubDirs) > 0):

			SubDirs.sort()

			for dir_subdir_name in SubDirs:
				dir_level_str += indent_str + ":\n"
				dir_level_str += indent_str + ":\n"
				dir_level_str += indent_str + " > " + dir_subdir_name + "\n"

				if (dir_subdir_name != SubDirs[-1]):
					dir_level_str += self.DirDiveToStr(dir_name + dir_subdir_name + '/', depth+1, indent_len, indent_str+":")
				else:
					dir_level_str += self.DirDiveToStr(dir_name + dir_subdir_name + '/', depth+1, indent_len, indent_str+" ")


		return dir_level_str




	#
	#  DEF: Exit
	#
	def Exit (self):
		self.window.quit()
		self.window.destroy()
		if self.PARENT_WINDOW:
			self.PARENT_WINDOW.deiconify()
			self.PARENT_WINDOW.focus_force()





