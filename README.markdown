#Haskerdeux - A Simple Command Line Client for Teuxdeux in Haskell

Written with the dual purpose of being a learning exercise for Haskell and also because I really wanted a command line tool for [Teuxdeux](http://teuxdeux.com). As it stands this is a bit rough and ready, but it does work.

It used to use Network.Curl, but I can't get that to work anymore so I'm doing straight system calls to curl which means it's not very Haskelly and ultimately a bit of a pointless use of Haskell, but it's for me, so there.

##Status

Alive! Official status is "Messy and works for me, unlikely to improve"; It was dead for years because I didn't think it was possible to get the new API to work.


##Requirements

You need the following Haskell packages installed:

- Data.List.Split
- Text.JSON

I also suggest you compile it to use it - it's much faster to use that way. Just do `ghc --make haskerdeux.hs`. If you don't compile it then replace `./haskerdeux` in the examples below with `runhaskell haskerdeux.hs`.


##Features/Commands

Haskerdeux currently includes the following commands: 

###Today

For listing today's todos only (as that is all I want to see)

`haskerdeux today <username> <password>`

This returns a numbered list, like so:

	0 - Write README for Haskerdeux
	1 - Write Blog post about Haskerdeux
	2 - Split development work in different branch
	3 - Perhaps do some actual work you are paid to do

You can use those numbers with the PutOff and CheckOff commands.

###New

For creating new tasks

`haskerdeux new "<A todo item>"`

###PutOff

For putting off a task until tomorrow.

`haskerdeux putoff <tasknumber from today list>`

E.g:

`haskerdeux putoff 3`

###MoveTo

For moving a task to another date.

`haskerdeux moveto <tasknumber from today list> <date in YYYY:MM:DD>`

E.g:

`haskerdeux moveto 11 2012-09-01`

###CrossOff

For marking a task as complete

`haskerdeux crossoff <tasknumber from today list>`

###Delete

For completely removing a task

`haskerdeux delete <tasknumber from today list>`


##Using .netrc For Storing Username and Password

It's compulsory. It used to support passing username/password as command line args, but no more. The `<username>` and `<password>` are read from `.netrc`. Just add an entry to `.netrc` as follows:

	machine teuxdeux.com
		login superprocrastinator
		password mysecretpassword

Or the single line format:

	machine teuxdeux.com loging superprocrastinator password mysecretpassword

It should work ok with either format. It won't work if you have spaces in your password though.


##Development

Nope.


##Thanks

Some resources that helped me figure this out:

- [A Haskell Newbies Guide to Text.JSON](http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/) and especially the comments explaining the generic approach.
- For the new API and making me realise it was possible to make this work once again, [dmi3's TeuxDeux Unofficial API for Python](https://github.com/dmi3/teuxdeux).
