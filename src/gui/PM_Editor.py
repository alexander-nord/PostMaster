import os
import re
import datetime

import PM_GUI_Generics as PMGUI

import tkinter as tk
import tkinter.filedialog as tkfd
from tkinter import ttk


class PM_Editor:


	PARENT_WINDOW = None


	# This is the most important part of this as an object!
	# If this is set to True, then the corresponding blog
	# will be written to the website!
	#
	PUBLISH = False



	#
	#   __init__
	#
	def __init__ (self, parent_window=None, title=None, file_name=None):


		self.PARENT_WINDOW = parent_window

		self.title         = title
		self.file_name     = file_name

		if self.PARENT_WINDOW:
			self.PARENT_WINDOW.withdraw()


		self.title = title
		if not self.title:
			self.title = f"Update ({datetime.datetime.today().strftime('%Y/%m/%d')})"


		self.file_name = file_name


		self.window = PMGUI.NewWindow(parent_window=self.PARENT_WINDOW,height=500)[0]


		self.window.rowconfigure([1,2,3,4], weight=1)
		self.window.columnconfigure(1, weight=1)

		self.editor = tk.Text(self.window, font=("Helvetica",14))
		self.editor.grid(row=1,column=1,columnspan=2,padx=10,pady=5,sticky="new")


		self.last_saved_text = self.EditorTextToStr()

		if self.file_name:
			self.Open()
		
		PMGUI.SetWindowTitle(self.window,f"Editor - {self.title}")


		help_button  = tk.Button(self.window, width=7, height=1, text="Quick Guide", command=self.Guide )
		save_button  = tk.Button(self.window, width=7, height=1, text="Save",        command=self.Save  )
		close_button = tk.Button(self.window, width=7, height=1, text="Close",       command=self.Close )

		help_button.grid( row=2,column=1,sticky="ne",padx=10)
		save_button.grid( row=3,column=1,sticky="ne",padx=10)
		close_button.grid(row=4,column=1,sticky="ne",padx=10)


		self.window.mainloop()




	#
	#  DEF: EditorTextToStr
	#
	def EditorTextToStr (self):
		return self.editor.get("1.0","end-1c")



	#
	#  DEF: Guide
	#
	def Guide (self):

		GuideWindow = PMGUI.NewWindow(width=600)[0]
		GuideWindow.title('Markdown Syntax Guide')

		GuideWindow.rowconfigure([1,2],weight=1)
		GuideWindow.columnconfigure([1,2,3],weight=1)

		with open(os.path.dirname(os.path.realpath(__file__))+'/markdown-guide.txt',"r") as GuideFile:
			guide_text = GuideFile.read()

		guide_display = tk.Text(GuideWindow,font=("Menlo",14))
		guide_display.grid(row=1,column=1,columnspan=3,padx=10,pady=10,sticky="nsew")
		guide_display.insert(tk.END,guide_text)
		guide_display.configure(state='disabled')

		close_button = tk.Button(GuideWindow,width=7,height=1,text="Close",command=GuideWindow.destroy)
		close_button.grid(row=2,column=3,sticky="ne",padx=10)

		GuideWindow.mainloop()


	#
	#  DEF: TextLossSafeGuard
	#
	def TextLossSafeGuard (self):

		if (self.EditorTextToStr() == self.last_saved_text):
			return True

		ButtonReturns = {}
		ButtonReturns['delete_safe'] = False

		TLSG = None

		def TLSG_SAVE():
			self.Save()
			ButtonReturns['delete_safe'] = True
			TLSG.quit()
			TLSG.destroy()

		def TLSG_DELETE():
			ButtonReturns['delete_safe'] = True
			TLSG.quit()
			TLSG.destroy()

		def TLSG_CANCEL():
			ButtonReturns['delete_safe'] = False
			TLSG.quit()
			TLSG.destroy()
			
		TLSG = PMGUI.NewWindow(width=275,height=90)[0]
		TLSG.title('WARNING')

		TLSG.rowconfigure([1,2,3], weight=1)
		TLSG.columnconfigure([1,2], weight=1)

		label = ttk.Label(TLSG,text="Text has not been saved.\nSave to file?")
		label.grid(row=1, column=1, rowspan=3, sticky="e")


		save_button   = tk.Button( TLSG, text="Save",       command=TLSG_SAVE   )
		delete_button = tk.Button( TLSG, text="Don't Save", command=TLSG_DELETE )
		cancel_button = tk.Button( TLSG, text="Cancel",     command=TLSG_CANCEL )

		save_button.grid(  row=1, column=2, sticky="ew", padx=10)
		delete_button.grid(row=2, column=2, sticky="ew", padx=10)
		cancel_button.grid(row=3, column=2, sticky="ew", padx=10)

		TLSG.mainloop()
		
		return ButtonReturns['delete_safe']




	#
	#  DEF: Open
	#
	def Open (self):

		# They're opening a new file, which makes things nice 'n' easy for us!
		if not os.path.exists(self.file_name):
			# TO DO: Add serious error handling
			print("OH NO!!!!")

		with open(self.file_name, mode="r", encoding="utf-8") as InFile:

			first_text_line = InFile.readline()
			while (first_text_line == "\n"):
				first_text_line = InFile.readline()

			title_check = re.search('^\s*\#\s+(.+)\s*$',first_text_line)
			if title_check:
				self.title = title_check.group(1)

			self.editor.insert(tk.END,InFile.read())

		self.last_saved_text = self.EditorTextToStr()
		
		return True



	#
	#  DEF:  PublishConfirm
	#
	def PublishConfirm (self):
			
		ButtonReturns = {}
		ButtonReturns['publish'] = False

		confirm_pub = None

		def ConfirmPubNo():
			confirm_pub.quit()
			confirm_pub.destroy()

		def ConfirmPubYes():
			ButtonReturns['publish'] = True
			confirm_pub.quit()
			confirm_pub.destroy()


		confirm_pub = PMGUI.NewWindow(width=275,height=90)[0]
		confirm_pub.title('Publish Confirmation')

		confirm_pub.rowconfigure([1,2], weight=1)
		confirm_pub.columnconfigure([1,2], weight=1)

		label = ttk.Label(confirm_pub,text="Confirmation required: Ready to publish?")
		label.grid(row=1, column=1, columnspan=2, sticky="s", padx=5)

		no_pub_button  = tk.Button( confirm_pub, text="Not yet",  width=10, command=ConfirmPubNo  )
		no_pub_button.grid(row=2, column=1, sticky="ew", padx=10)

		yes_pub_button = tk.Button( confirm_pub, text="Publish!", width=10, command=ConfirmPubYes )
		yes_pub_button.grid(row=2, column=2, sticky="ew", padx=10)

		confirm_pub.mainloop()

		return ButtonReturns['publish']




	#
	#  DEF: Publish
	#
	def Publish (self):
		self.Save()
		if self.PublishConfirm():
			self.PUBLISH = True
			self.Close()





	#
	#  DEF: Save
	#
	def Save (self):

		# This should only be during debugging...
		if not self.file_name:
			
			print(f"# {self.title}\n\n")
			print(self.editor.get("1.0",tk.END))

		else:

			with open(self.file_name, mode="w", encoding="utf-8") as OutFile:
				OutFile.write(f"# {self.title}\n\n")
				OutFile.write(self.editor.get("1.0",tk.END))

		self.last_saved_text = self.EditorTextToStr()




	#
	#  DEF: Close
	#
	def Close (self):
		if self.TextLossSafeGuard():
			self.window.quit()
			self.window.destroy()
			if self.PARENT_WINDOW:
				self.PARENT_WINDOW.deiconify()
				self.PARENT_WINDOW.focus_force()






