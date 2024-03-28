import os
import re
import subprocess

import PM_GUI_Generics as PMGUI
import PM_NewSite
import PM_LoadSite
import PM_SiteHome

import tkinter as tk
import tkinter.font as tkfont
import tkinter.filedialog as tkfd
from tkinter import ttk




class PM_Startup:


	SELECTED_SITE=None


	def __init__ (self):

		
		dir_name_match = re.match('^(.*)src\/gui\/?$',os.path.dirname(os.path.realpath(__file__)))
		if not dir_name_match:
			# TO DO: Handle them seemingly not running this from where it's supposed to live...
			return None
		self.pm_base_dir_name = dir_name_match.group(1)


		self.window = PMGUI.NewWindow(width=300,height=400)[0]
		PMGUI.SetWindowTitle(self.window)

		self.window.columnconfigure([1],weight=1)
		self.window.rowconfigure([1,2,3],weight=1)

		new_button   = tk.Button(self.window,width=10,height=2,text="New Site", command=self.New  )
		load_button  = tk.Button(self.window,width=10,height=2,text="Load Site",command=self.Load )
		close_button = tk.Button(self.window,width=10,height=2,text="Close",    command=self.Close)

		font_size_setter = tkfont.Font(size=20)
		new_button['font']   = font_size_setter
		load_button['font']  = font_size_setter
		close_button['font'] = font_size_setter

		new_button.grid(  column=1,row=1,padx=10,pady=5,sticky="nsew")
		load_button.grid( column=1,row=2,padx=10,pady=5,sticky="nsew")
		close_button.grid(column=1,row=3,padx=10,pady=5,sticky="nsew")

		self.window.mainloop()




	#
	#  DEF: Load
	#
	def Load (self, site_to_load=None):

		if not site_to_load:
	
			LoadSiteObj = PM_LoadSite.PM_LoadSite(parent_window=self.window)

			if not LoadSiteObj.SITE_SELECTED:
				return

			site_to_load = LoadSiteObj.SELECTED_SITE

		loaded_site_dir = self.pm_base_dir_name + "sites/" + site_to_load + "/"

		# Even though it's pretty much impossible for this site to be missing
		# if we've made it this far, let's just be *absolutely* sure
		if not os.path.isdir(loaded_site_dir):
			# TO DO: Add a pretty intense error message -- this shouldn't happen!!!
			return
		
		SiteHome = PM_SiteHome.PM_SiteHome(parent_window=self.window,site_dir=loaded_site_dir)



	#
	#  DEF: New
	#
	def New (self):

		NewSiteObj = PM_NewSite.PM_NewSite(parent_window=self.window)

		new_site_success  = NewSiteObj.GOOD_NEW_SITE
		new_site_name     = NewSiteObj.NEW_SITE_NAME
		new_site_tmp_meta = NewSiteObj.SITE_TMP_META_FILE

		del NewSiteObj

		if new_site_success:

			subprocess.run(["perl",f"{self.pm_base_dir_name}src/BuildSiteShell.pl",new_site_tmp_meta])
			subprocess.run(["rm",new_site_tmp_meta])

			self.Load(site_to_load=new_site_name)



	#
	#  DEF: Close
	#
	def Close (self):
		self.window.destroy()



