{-# LANGUAGE DeriveDataTypeable #-}
--HaskerDeux

import System.Environment
import System.IO
import System.IO.Error
import System.Process
import Data.List
import Data.List.Split --need to install
import Data.Map
import Control.Monad
import Data.Maybe
import Text.JSON --need to install for JSON
import Text.JSON.Generic --need to install for JSON
import Data.Time
import System.Time
import System.Locale (defaultTimeLocale)
import System.Directory
--import Web.Encodings --need to install. Now depreciated, but I'm behind on GHC versions. Is this actually used? Oh yeah for decodeJSON, but should be able to use Text.JSON instead to decode
--import Data.Text
import Network.URI.Encode --need to install

--Note to self: to run you type `runhaskell haskerdeux.hs test "me" "this" "that"`, etc
dispatch :: String -> (String, [String]) -> IO()
dispatch "today" = today
--dispatch "new" = new
dispatch "crossoff" = crossoff
dispatch "putoff" = putoff
dispatch "moveto" = moveto
dispatch "delete" = remove
--Since we might want to force a login


main = do 
	time <- getClockTime >>= toCalendarTime --https://wiki.haskell.org/Unix_tools/Date
	let todays_date = formatCalendarTime defaultTimeLocale "%Y-%m-%d" time
	(command:argList) <- getArgs
	if (command == "today" && Data.List.null argList) || (command `elem` ["new", "crossoff", "putoff", "delete"] && length argList == 1) || (command == "moveto" && length argList == 2)
		then do
			username <- fmap fst readnetrc
			password <- fmap snd readnetrc
			token <- login [username, password]
			dispatch command (token, todays_date:argList)
		else
			return()
			--I can't be bothered to do credentials any other way than .netrc


readnetrc = do
	home <- getHomeDirectory
	netrc <- fmap lines $ readFile (home ++ "/.netrc")
	let netrc' = dropWhile (not . isInfixOf "teuxdeux") netrc
	let (username, password) = if "login" `isInfixOf` head netrc'
		-- if entry is on one line	
		then (getcred "login", getcred "password") 
		-- if entry is on multiple lines
		else (last $ words $ netrc' !! 1, last $ words $ netrc' !! 2)
		where getcred c = dropWhile (not . isInfixOf c) (words $ head netrc') !! 1
	return (username, password)


curlget (token, todays_date) = do
	let curlheader = "X-CSRF-Token: " ++ token
	body <- readProcess "curl" ["-s", "-L", "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader, "https://teuxdeux.com/api/v1/todos/calendar?begin_date="++todays_date++"&end_date="++todays_date] []
	--let opts1 = [] 
	--body <- curlGetString "https://teuxdeux.com/api/list.json" opts1
	let tds = decodeJSON body :: [Teuxdeux]
	let tdsf = Data.List.filter (\td -> current_date td == todays_date && not (done td)) tds
	return tdsf
	

curlpost (token, [todays_date, key, value, apiurl, okresponse]) number = do
	tdsf <- curlget (token, todays_date)
	let itemid = Main.id $ tdsf!!(read number::Int)
	let curlheader = "X-CSRF-Token: " ++ token
	--Can be much improved, but will do for now:
	let json = "{ \"ids\" : [\""++(show itemid)++"\"], \""++key++"\" : \""++value++"\"}"
	body <- readProcess "curl" ["-s", "-XPOST", apiurl, "-L", "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader, "-H", "Content-Type: application/json", "-d", json] []
	--just check body contains stuff?
	--putStrLn body
	if isInfixOf "done_updated_at" body
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"


curldelete (token, [todays_date, apiurl, okresponse]) number = do
	tdsf <- curlget (token, todays_date)
	let itemid = Main.id $ tdsf!!(read number::Int)
	let curlheader = "X-CSRF-Token: " ++ token
	body <- readProcess "curl" ["-s", "-XDELETE", apiurl++(show itemid), "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader] []
    --putStrLn okresponse
	return()
	-- what does the response say?
    -- if respCurlCode resp == CurlOK && respStatus resp == 200
    -- 	then putStrLn okresponse
    -- 	else putStrLn "Uh Oh! Didn't work!"

curlput (token, [todays_date, json, apiurl, okresponse]) number = do
	--Need the json we are PUTTING somewhere in here
	tdsf <- curlget (token, todays_date)
	--Need some way to post the body.
	--Need headers for posting json "Content-Type: application/json"
	-- -d ""
	let itemid = Main.id $ tdsf!!(read number::Int)
	--let curlpostfields = return $ CurlPostFields [json] --try json here
	let curlheader = "X-CSRF-Token: " ++ token
	body <- readProcess "curl" ["-s", "-XPUT", apiurl++(show itemid), "-L", "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader, "-H", "Content-Type: application/json", "-d", json] []
	--how to check response? For now that will make parsing hard so let it fail
	--just check body contains stuff?
	if isInfixOf "done_updated_at" body
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"

getauthtoken body = do
	let bodylines = lines body
	let authline = dropWhile (not . isInfixOf "authenticity_token") bodylines
	let authwords = words $ head authline
	let authtokenword = stripPrefix "value=\"" $ last authwords
	let revauthtokenword = reverse $ fromJust authtokenword
	let authtoken = reverse $ fromJust $ stripPrefix ">\"" revauthtokenword
	--home <- getHomeDirectory
	--putStrLn authtoken
	--writeFile (home ++ "/.haskerdeux-token") authtoken
	return authtoken


login [username, password] = do
	--See if we have a token, then to clear we can just delete the file
	home <- getHomeDirectory
	--handle error
	check <- doesFileExist (home ++ "/.haskerdeux-token")
	if check
		then do
			token <- readFile (home ++ "/.haskerdeux-token")
			return token
		else do
			body <- readProcess "curl" ["-s", "-L", "-c", "haskerdeux.cookies", "https://teuxdeux.com/login"] []
			token <- getauthtoken body
			writeFile (home ++ "/.haskerdeux-token") token
			--can probably use one post?
			let curlheader = "X-CSRF-Token: " ++ token
			let curlpostfields = "username=" ++ username ++ "&password=" ++ password ++ "&authenticity_token=" ++ token
			body <- readProcess "curl" ["-s", "-L", "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader, "-d", curlpostfields, "https://teuxdeux.com/login"] []
			return token


today (token, [todays_date]) = do
	tdsf <- curlget (token, todays_date)
	putStr $ unlines $ zipWith (\n td -> show n ++ " - " ++ td) [0..] $ Data.List.map text tdsf --numbering from LYAH


--new (curl, [todays_date, todo]) = do 
--	let encodedtodo = Network.URI.Encode.encode todo
--	curlpost [todays_date, encodedtodo, "https://teuxdeux.com/api/todo.json", "Added!"] Nothing
--
--
crossoff (token, [todays_date, number]) =
	curlput (token, [todays_date, "{ \"done\": true }", "https://teuxdeux.com/api/v1/todos/", "Crossed Off!"]) number
	-- is a PUT to https://teuxdeux.com/api/v1/todos/42396076
	--should just be able to do "done": true, but might need whole object...
	--check for retured body

putoff (token, [todays_date, number]) = do
	let tomorrows_date = show (addDays 1 $ read todays_date::Data.Time.Day)
	curlpost (token, [todays_date, "current_date", tomorrows_date, "https://teuxdeux.com/api/v1/todos/reposition/", "Put Off!"]) number


moveto (token, [todays_date, number, new_date]) = do
	--Need to figure out moving to bottom of a list
	curlpost (token, [todays_date, "current_date", new_date, "https://teuxdeux.com/api/v1/todos/reposition", "Moved!"]) number


remove (token, [todays_date, number]) =
	curldelete (token, [todays_date, "https://teuxdeux.com/api/v1/todos/", "Deleted!"]) number


--Thanks to http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/ and http://hpaste.org/41263/parsing_json_with_textjson
data Teuxdeux = Teuxdeux {
    id :: Integer,
	current_date :: String, 
	text :: String,
	done :: Bool
} deriving (Eq, Show, Data, Typeable) 
