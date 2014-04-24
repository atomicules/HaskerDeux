#Haskerdeux - A Simple Command Line Client for Teuxdeux in Haskell

Written with the dual purpose of being a learning exercise for Haskell and also because I really wanted a command line tool for [Teuxdeux](http://teuxdeux.com). As it stands this is a bit rough and ready, but it does work.

##Status

Abandonware. TeuxDeux released a Neux version and I waited a year but the corresponding new API did not come and I really missed command line access so I jumped ship to taskwarrior.


##Requirements

You need the following Haskell packages installed:

- Data.List.Split
- Network.Curl
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

`haskerdeux new "<A todo item>" <username> <password>`

E.g:

`haskerdeux new "Stop procrastinating" superprocrastinator mysecretpassword`

(Supplying username and password on the command line)

###PutOff

For putting off a task until tomorrow.

`haskerdeux putoff <tasknumber from today list> <username> <password>`

E.g:

`haskerdeux putoff 3`

(Using username and password stored in `.netrc`)

###MoveTo

For moving a task to another date.

`haskerdeux moveto <tasknumber from today list> <date in YYYY:MM:DD> <username> <password>`

E.g:

`haskerdeux moveto 11 2012-09-01`

###CrossOff

For marking a task as complete

`haskerdeux crossoff <tasknumber from today list> <username> <password>`

###Delete

For completely removing a task

`haskerdeux delete <tasknumber from today list> <username> <password>`

##Using .netrc For Storing Username and Password

The `<username>` and `<password>` arguments are optional. If not supplied then it attempts to read them from `.netrc`. Just add an entry to `.netrc` as follows:

	machine teuxdeux.com
		login superprocrastinator
		password mysecretpassword

Or the single line format:

	machine teuxdeux.com loging superprocrastinator password mysecretpassword

It should work ok with either format. It won't work if you have spaces in your password though.

##Proxy Support

I went with [Network.Curl](http://hackage.haskell.org/package/curl) because proxy support was a must for me and I couldn't figure it out (at least not using authentication) with things like http-enumerator or http-conduit. Anyway, I spent ages figuring out checking for environment variables and building the proxy options to Curl, but seems like there is no need: As long as you have the `https_proxy` environment variable set, Curl finds it by default and does it automatically. So even works where authentication is required. You just need something like the following in `.bashrc`, etc.

`export proxy https_proxy="<username>:<password>@<proxyserveraddress>:<proxyport>"`

##Development

I plan/hope to be able to re-create what [Badboy did in Ruby](https://github.com/badboy/teuxdeux) in Haskell. So in the develop branch I am going to split out the API stuff from the command line client - because I might keep the command line client lighter; I like the above functionality, I just want the code to be a bit cleaner.

##Thanks

Some resources that helped me figure this out:

- [Badboy's Teuxdeux](https://github.com/badboy/teuxdeux) and his documentation of the [Unofficial API](https://github.com/badboy/teuxdeux/wiki/API)
- [Extended sessions with the Haskell Curl bindings](http://flygdynamikern.blogspot.it/2009/03/extended-sessions-with-haskell-curl.html) without which I would have never figured out Network.Curl
- [A Haskell Newbies Guide to Text.JSON](http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/) and especially the comments explaining the generic approach.
