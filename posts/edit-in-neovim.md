# Use NeoVim anywhere on OSX

I often want to use NeoVim outside the terminal, when writing emails or notes.
Luckily, I found Jamie Schembri's post [NeoVim everywhere on MacOS].
I have made a few improvements with regards to stability and ""stability"".

[NeoVim everywhere on MacOS]: https://schembri.me/post/neovim-everywhere-on-macos/

## 'Edit in NeoVim' service

This workflow takes as input the current selection and outputs the text to replace it.
It uses iTerm2 and NeoVim to edit the text.

If you haven't used Automator before,
I recommend following the official guide hon how to [create a Quick Action workflow].
You'll want to set *Workflow receives current* to "text" and check the box *Output replaces selected text*.
Then add a *Run AppleScript* action to the workflow with the below code.

[create a Quick Action workflow]: https://support.apple.com/en-ke/guide/automator/aut73234890a/2.10/mac/14.0

```applescript
on readFile(unixPath)
	set fileDescriptor to (open for access (POSIX file unixPath))
	set theText to (read fileDescriptor for (get eof fileDescriptor) as «class utf8»)
	close access fileDescriptor
	return theText
end readFile

on writeTextToFile(theText, filePath, overwriteExistingContent)
	try
		-- Convert the file to a string
		set filePath to filePath as string

		-- Open the file for writing
		set fileDescriptor to (open for access filePath with write permission)

		-- Clear the file if content should be overwritten
		if overwriteExistingContent is true then set eof of fileDescriptor to 0

		-- Write the new content to the file
		set theText to theText as string
		write theText to fileDescriptor starting at eof as «class utf8»

		-- Close the file
		close access fileDescriptor

		-- Return a boolean indicating that writing was successful
		return true

		-- Handle a write error
	on error errMessage
		-- Close the file
		try
			close access file theFile
		end try

		display alert "Failed to write to file" message "Failed to write to file " & theFile & ": " & errMessage

		-- Return a boolean indicating that writing failed
		return false
	end try
end writeTextToFile

on run {input, parameters}
	-- Save the frontmost application for later.
	tell application "System Events"
		set activeProc to first application process whose frontmost is true
	end tell

	-- Write the selected text (input) to a temporary file.
	set tempfile to do shell script "mktemp -t edit-in-vim"
	if writeTextToFile(input, tempfile, true) is false then
		-- Failed to write the input to the file. The function has already
		-- displayed an error message, so let us just return the input unaltered.
		return input
	end if

	-- Edit that temporary file with Neovim under iTerm2.
	tell application "iTerm2"
		-- If General>Closing>'Quit when all windows are closed' is enabled,
		-- this will create two windows if iTerm2 was previosly closed.
		--
		-- We use a custom profile (with a descriptive name) to reduce the
		-- risk of idiot Linus accidentally breaking something by changing
		-- the default profile.
		create window with profile "Rediger i Neovim (brugt af workflow)"

		tell the current window
			tell the current session
				-- Edit the file using Neovim. We set 'nofixeol' to avoid inserting
				-- extraneous linebreaks in the final output. We also set 'wrap' since
				-- we seldom want to rewrite as we often don't want to manually break
				-- lines in MacOS input fields.
				write text "nvim -c 'set nofixeol' \"" & tempfile & "\""

				-- Wait for the editing process to finish.
				-- This requires shell-integration to be enabled.
				delay 0.5
				repeat while not is at shell prompt
					delay 0.2
				end repeat
			end tell

			-- Close the window we just created so it doesn't clutter up the desktop.
			close
		end tell
	end tell

	-- Switch back to the previously active application.
	tell application "System Events"
		set the frontmost of activeProc to true
	end tell

	-- The new text is stored in tempfile.
	return readFile(tempfile)
end run
```

The functions `readFile` and `writeFile` come from the [Mac Automation Scripting Guide].
Do beware that the original `writeFile` linked before doesn't handle Unicode text properly.

[Mac Automation Scripting Guide]: https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/ReadandWriteFiles.html

The code for restoring the focused application was taken from a [patch on the `pass` mail archives].

[patch on the `pass` mail archives]: https://lists.zx2c4.com/pipermail/password-store/2015-July/001628.html

## Neovim as a standalone application.

This next snippet wraps NeoVim in a proper Application&trade;.
Doing this means it will be recognized by MacOS in various places.
For example, when opening files in Finder it is now possible to choose NeoVim.
I have set it as the default for all markdown files on my computer.

A more robust – and probably all around better – would be to use [VimR].
I have yet to test it, but I might replace this script with VimR in the future.

[VimR]: <https://github.com/qvacua/vimr>

```Applescript
on run {input, parameters}
	if input is not {} then
		set filePath to POSIX path of input
		set cmd to "nvim \"" & filePath & "\""
	else
		set cmd to "nvim"
	end if

	tell application "iTerm2"
		create window with default profile
		tell the current window
			tell the current session
				write text cmd

				-- Wait for command to finish.
				repeat while not is at shell prompt
					delay 0.2
				end repeat
			end tell

			close
		end tell
	end tell
end run
```
