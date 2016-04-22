AskCreds <- function(Title="User credentials for a database", startuid="", returnValOnCancel = "ID_CANCEL") {
    # Peter Ellis, 12 August 2013
    # A wrapper function to provide a GUI to ask a user for user id and password so they
    # can be given to a database in a future call of connectODBC() or similar
    # Based on http://www.sciviews.org/_rgui/tcltk/ModalDialog.html
    dlg <- tktoplevel()
    tkwm.deiconify(dlg)
    tkgrab.set(dlg)
    tkfocus(dlg)
    tkwm.title(dlg, Title)
    uidEntryVarTcl <- tclVar(startuid)
    uidEntryWidget <- tkentry(dlg, width = 50, textvariable = uidEntryVarTcl)
    pwdEntryVarTcl <- tclVar("")
    pwdEntryWidget <- tkentry(dlg, width = 50, textvariable = pwdEntryVarTcl, show="X")
    tkgrid(tklabel(dlg, text = "       "))
    tkgrid(tklabel(dlg, text = "User ID"), uidEntryWidget)
    tkgrid(tklabel(dlg, text = "Password"), pwdEntryWidget)
    ReturnVal <- returnValOnCancel
    
    onOK <- function() {
        ReturnVal <<- list(uid=tclvalue(uidEntryVarTcl), pwd=tclvalue(pwdEntryVarTcl))
        tkgrab.release(dlg)
        tkdestroy(dlg)
    }
    onCancel <- function() {
        ReturnVal <<- returnValOnCancel
        tkgrab.release(dlg)
        tkdestroy(dlg)
    }
    OK.but <- tkbutton(dlg, text = "   OK   ", command = onOK)
    Cancel.but <- tkbutton(dlg, text = " Cancel ", command = onCancel)
    tkgrid(OK.but, Cancel.but)
    tkgrid(tklabel(dlg, text = "    "))
    
    tkfocus(dlg)
    
    tkbind(pwdEntryWidget, "<Return>", onOK)
    tkwait.window(dlg)
    
    return(ReturnVal)
}
