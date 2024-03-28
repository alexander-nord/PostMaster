import tkinter as tk
import tkinter.filedialog as tkfd
from tkinter import ttk


STD_WINDOW_WIDTH  = 800
STD_WINDOW_HEIGHT = 450


entry_std_bg = "black"	
entry_std_fg = "white"

entry_err_bg = "#DC3D3D"
entry_err_fg = "black"



#
#  NewWindow
#
def NewWindow (parent_window=None, inherit_size=False, width=STD_WINDOW_WIDTH, height=STD_WINDOW_HEIGHT, x=None, y=None):

		new_window = None

		if parent_window:

			new_window = tk.Toplevel(parent_window)

			if inherit_size:
				width  = tk.winfo_width( parent_window)
				height = tk.winfo_height(parent_window)

		else:

			new_window = tk.Tk()


		if not x:
			x = int(new_window.winfo_screenwidth()/2 - width/2)

		if not y:
			y = int(new_window.winfo_screenheight()/2 - height/2)


		SetWindowGeometry(new_window,width,height,x,y)
		SetWindowTitle(new_window)


		return (new_window,width,height,x,y)



#
#  SetWindowTitle
#
def SetWindowTitle (window, specifics=None):
	
	title_text = "PostMaster"
	
	if specifics:
		title_text += " - " + specifics
	
	window.title(title_text)


#
#  SetWindowGeometry
#
def SetWindowGeometry (window,width,height,x,y):
	window.geometry(f"{width}x{height}+{x}+{y}")



#
#  DEF: AddLabelAndEntry
#
def AddLabelAndEntry (window,text,text_var,row,label_col=1,entry_col=2):

	label = tk.Label(window,text=text)
	label.grid(row=row,column=label_col,padx=10,sticky="s")
		
	entry = tk.Entry(window,textvariable=text_var,background=entry_std_bg,foreground=entry_std_fg)
	entry.grid(row=row,column=entry_col,padx=10,sticky="sew")

	return label, entry


#
#  DEF: AddLabelAndDropdown
#
def AddLabelAndDropdown (window,text,Choices,text_var,row,label_col=1,dropdown_col=2):

	label = tk.Label(window,text=text)
	label.grid(row=row,column=label_col,padx=10,sticky="s")

	dropdown = tk.OptionMenu(window,text_var,*(Choices))
	dropdown.config(width=len(max(Choices,key=len))-7)
	dropdown.grid(row=row,column=dropdown_col,padx=10,sticky="sew")

	return label, dropdown



#
#  DEF: AddLabelAndCheckbutton
#
def AddLabelAndCheckbox (window,text,text_var,row,label_col=1,checkbox_col=2):

	label = tk.Label(window,text=text)
	label.grid(row=row,column=label_col,padx=10,sticky="s")

	checkbox = tk.Checkbutton(window,variable=text_var,onvalue="on",offvalue="off")
	checkbox.grid(row=row,column=checkbox_col,padx=10,sticky="sew")
	checkbox.deselect()

	return label, checkbox




#
#  DEF: ErrorWindow
#
def ErrorWindow (title="ERROR",text="OOPS!",width=260,height=150):

	ErrWin = NewWindow(width=width,height=height)[0]
	ErrWin.title(title)

	def DestroyErrWin():
		ErrWin.quit()
		ErrWin.destroy()

	ErrWin.rowconfigure([1,2],weight=1)
	ErrWin.columnconfigure([1],weight=1)

	err_label = ttk.Label(ErrWin,text=text)
	err_label.grid(row=1,column=1,padx=10,pady=10,sticky="sew")

	err_button = tk.Button(ErrWin,text="Close",command=DestroyErrWin)
	err_button.grid(row=2,column=1,pady=10,sticky="n")

	ErrWin.mainloop()





