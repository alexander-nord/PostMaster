import os
import re

import PM_GUI_Generics as PMGUI

import tkinter as tk
import tkinter.filedialog as tkfd
from tkinter import ttk



class PM_NewSite:


	PARENT_WINDOW = None


	# This is the variable that lets the calling script know that
	# the new site is good to go!
	#
	GOOD_NEW_SITE = False
	NEW_SITE_NAME = None
	SITE_TMP_META_FILE = 'pm-new-site-info.tmp'



	#
	#  DEF: __init__
	#
	#  Initializes a window for the user to provide the basic
	#  information for a new PM-managed site -- specifically:
	#
	#     (1) the name of the site       # REQUIRED
	#     (2) their name (for copyright) # REQUIRED
	#     (3) a github username          # Optional
	#     (4) a domain                   # Optional
	#
	#  Because this isn't especially sophisticated, we assume
	#  that the user is hosting through github.io, and if they
	#  aren't then we collapse into shameful shambles.
	#
	#
	def __init__ (self, parent_window=None, dir_name=None):

		self.PARENT_WINDOW = parent_window

		self.site_name = None
		self.user_name = None
		self.github_id = None
		self.domain    = None


		if not dir_name:
			dir_name_match = re.match('^(.*)src\/gui\/?$',os.path.dirname(os.path.realpath(__file__)))
			if not dir_name_match:
				# TO DO: Handle them seemingly not running this from where it's supposed to live...
				return None
			dir_name = dir_name_match.group(1) + "sites/"


		self.window = PMGUI.NewWindow(parent_window=self.PARENT_WINDOW,width=400,height=175)[0]

		PMGUI.SetWindowTitle(self.window, "New Site")

		self.window.rowconfigure([1,2,3,4,5], weight=1)
		self.window.columnconfigure([1,2], weight=1)


		self.usr_site_name = tk.StringVar(self.window)
		self.usr_user_name = tk.StringVar(self.window)
		self.usr_github_id = tk.StringVar(self.window)
		self.usr_domain    = tk.StringVar(self.window)

		site_name_label, self.site_name_entry = PMGUI.AddLabelAndEntry(self.window,"Site Name",self.usr_site_name,1)
		user_name_label, self.user_name_entry = PMGUI.AddLabelAndEntry(self.window,"Site Owner Name",self.usr_user_name,2)
		github_id_label, self.github_id_entry = PMGUI.AddLabelAndEntry(self.window,"GitHub Username (Optional)",self.usr_github_id,3)
		domain_label,    self.domain_entry    = PMGUI.AddLabelAndEntry(self.window,"Domain Name (Optional)",self.usr_domain,4)


		cancel_button = tk.Button( self.window, text="Cancel", command=self.CancelCreate, width=75 )
		create_button = tk.Button( self.window, text="Create", command=self.TryCreate,    width=75 )

		cancel_button.grid(row=5,column=1,padx=50,pady=15)
		create_button.grid(row=5,column=2,padx=50,pady=15)


		self.window.mainloop()




	#
	#  DEF: CancelCreate
	#
	def CancelCreate (self):
		self.window.quit()
		self.window.destroy()



	#
	#  DEF: TryCreate
	#
	def TryCreate (self):


		good_site_name, site_name_err = self.ConfirmSiteName()
		good_user_name, user_name_err = self.ConfirmOwnerName()
		good_github_id, github_id_err = self.ConfirmGitHubUsername()
		good_domain,    domain_err    = self.ConfirmDomain()


		if (good_site_name and good_user_name and good_github_id and good_domain):

			if not self.github_id:
				self.github_id = "0"
			if not self.domain:
				self.domain = "0"

			with open(self.SITE_TMP_META_FILE, mode="w", encoding="utf-8") as OutFile:
				OutFile.write(f"{self.site_name}\n{self.user_name}\n{self.github_id}\n{self.domain}\n")

			self.GOOD_NEW_SITE = True
			self.NEW_SITE_NAME = self.site_name

			self.window.quit()
			self.window.destroy()
			return


		if not good_site_name:
			self.site_name_entry.config(bg=PMGUI.entry_err_bg,fg=PMGUI.entry_err_fg)
		else:
			self.site_name_entry.config(bg=PMGUI.entry_std_bg,fg=PMGUI.entry_std_fg)


		if not good_user_name:
			self.user_name_entry.config(bg=PMGUI.entry_err_bg,fg=PMGUI.entry_err_fg)
		else:
			self.user_name_entry.config(bg=PMGUI.entry_std_bg,fg=PMGUI.entry_std_fg)


		if not good_github_id:
			self.github_id_entry.config(bg=PMGUI.entry_err_bg,fg=PMGUI.entry_err_fg)
		else:
			self.github_id_entry.config(bg=PMGUI.entry_std_bg,fg=PMGUI.entry_std_fg)


		if not good_domain:
			self.domain_entry.config(bg=PMGUI.entry_err_bg,fg=PMGUI.entry_err_fg)
		else:
			self.domain_entry.config(bg=PMGUI.entry_std_bg,fg=PMGUI.entry_std_fg)


		create_err_height = 90
		if not good_site_name:
			create_err_height += 30
		if not good_user_name:
			create_err_height += 30
		if not good_github_id:
			create_err_height += 45 
		if not good_domain:
			create_err_height += 45

		PMGUI.ErrorWindow(title="New Site Error",text=site_name_err+user_name_err+github_id_err+domain_err,height=create_err_height)




	#
	#  DEF: ConfirmSiteName
	#
	def ConfirmSiteName (self):

		attempt_site_name = self.usr_site_name.get()

		if not attempt_site_name:
			return False, "\nSite Name field cannot be empty\n"

		if os.path.isdir(attempt_site_name):
			# Tell the user that this site already exists...
			self.site_name = None
			return False, "\nA site with this name already exists\n"

		self.site_name = attempt_site_name
		return True, ""



	#
	#  DEF: ConfirmOwnerName
	#
	def ConfirmOwnerName (self):

		attempt_user_name = self.usr_user_name.get()

		if not attempt_user_name:
			self.user_name = None
			return False, "\nOwner Name field cannot be empty\n"

		self.user_name = attempt_user_name
		return True, ""



	#
	#  DEF: ConfirmGitHubUsername
	#
	def ConfirmGitHubUsername (self):

		attempt_github_id = self.usr_github_id.get()

		if not attempt_github_id:
			self.github_id = None
			return True, ""

		# Maybe a few lil' validations (no whitespace, special chars, etc.)...
		git_id_validation = re.sub("\-",'',attempt_github_id)
		git_id_validation = re.search('\W',git_id_validation) # Hopefully returns 'None'

		if git_id_validation:
			self.github_id = None
			return False, "\nGitHub Username includes illegal\n   characters\n"


		self.github_id = attempt_github_id
		return True, ""


	#
	#  DEF: ConfirmDomain
	#
	def ConfirmDomain (self):

		# Domain is optional
		if not self.usr_domain.get():
			self.domain = None
			return True, ""

		domain_match = re.search('([^\/|\.]+\.[^\/|\.]+)$',self.usr_domain.get())

		if domain_match:
			self.domain = 'https://' + domain_match.group(1)
			return True, ""

		# Let the user know that they need their domain needs to have the 
		# '[domain].[com/org/whatever]' format
		return False, "\nDomain should be in 'ABC.XYZ' format\n   (e.g., 'alexnord.org')\n"






	
