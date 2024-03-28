import os
import re

import PM_GUI_Generics as PMGUI

import tkinter as tk
import tkinter.filedialog as tkfd
from tkinter import ttk



class PM_LoadSite:


	PARENT_WINDOW = None


	# This is the variable that lets the calling script know that
	# the new site is good to go!
	#
	SITE_SELECTED = False
	SELECTED_SITE = None


	#
	#  DEF: __init__
	#
	#  This is a simple window for loading a site from the PostMaster
	#  sites this user has built (visible on this device...)
	#
	def __init__ (self, parent_window=None, dir_name=None):

		self.PARENT_WINDOW = parent_window

		if not dir_name:
			dir_name_match = re.match('^(.*)src\/gui\/?$',os.path.dirname(os.path.realpath(__file__)))
			if not dir_name_match:
				# TO DO: Handle them seemingly not running this from where it's supposed to live...
				return None
			dir_name = dir_name_match.group(1)

		self.pm_base_dir_name = dir_name

		SiteNames = self.GetSiteNameList()


		# If there aren't any sites to choose from, we'll let the user know and bail
		if len(SiteNames) == 0:
			self.DisplayNoSitesMsg()
			return


		self.window = PMGUI.NewWindow(parent_window=self.PARENT_WINDOW,width=250,height=80)[0]

		PMGUI.SetWindowTitle(self.window, "Load Site")

		self.window.rowconfigure([1,2], weight=1)
		self.window.columnconfigure([1,2], weight=1)

		self.default_menu_text = "-- Select Site --"
		self.selected_site = tk.StringVar(self.window,self.default_menu_text)

		SiteNames.sort()
		SiteNames.insert(0,self.default_menu_text)

		site_select_menu = tk.OptionMenu(self.window,self.selected_site,*(SiteNames))
		site_select_menu.config(width=len(max(SiteNames,key=len))-7)
		site_select_menu.grid(row=1,column=1,columnspan=2,padx=10,pady=10,sticky="sew")


		cancel_button = tk.Button( self.window, text="Cancel", command=self.CancelLoad, width=40 )
		load_button   = tk.Button( self.window, text="Load",   command=self.TryLoad,    width=40 )

		cancel_button.grid(row=2,column=1,padx=10,pady=10)
		load_button.grid(  row=2,column=2,padx=10,pady=10)


		self.window.mainloop()


	#
	#  DEF: GetSiteNameList
	#
	def GetSiteNameList (self):
		
		SiteList = []
		site_dir_name = self.pm_base_dir_name + "sites/"

		for site in os.listdir(site_dir_name):

			# Make sure this looks like an actual PostMaster site directory...
			if os.path.isfile(site_dir_name + site + "-PostMaster-Data/metadata"):
				SiteList.append(site)

		return SiteList



	#
	#  DEF: DisplayNoSitesMsg
	#
	def DisplayNoSitesMsg (self):

		LoadErr = PMGUI.NewWindow(parent_window=self.PARENT_WINDOW,width=260,height=100)[0]
		LoadErr.title('No Sites Found')

		LoadErr.rowconfigure([1,2],weight=1)
		LoadErr.columnconfigure(1,weight=1)

		load_err_label = ttk.Label(LoadErr,text="No PostMaster sites appear\n to be stored on this device...")
		load_err_label.grid(row=1,column=1,padx=30,pady=13,sticky="nsew")

		load_err_button = tk.Button(LoadErr,text="Close",command=LoadErr.destroy)
		load_err_button.grid(row=2,column=1,pady=10,sticky="s")

		LoadErr.mainloop()


	#
	#  DEF: CancelLoad
	#
	def CancelLoad (self):
		self.window.quit()
		self.window.destroy()



	#
	#  DEF: TryLoad
	#
	def TryLoad (self):
		if self.selected_site.get() != self.default_menu_text:
			self.SELECTED_SITE = self.selected_site.get()
			self.SITE_SELECTED = True
		self.window.quit()
		self.window.destroy()





