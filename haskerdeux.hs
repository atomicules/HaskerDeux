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
import Control.Applicative
import Data.Maybe
import Text.JSON --need to install for JSON
import Text.JSON.Generic --need to install for JSON
import Data.Time
import System.Time
import System.Locale (defaultTimeLocale)
import System.Directory
import Network.URI.Encode --need to install

--Note to self: to run you type `runhaskell haskerdeux.hs test "me" "this" "that"`, etc
dispatch :: String -> (String, [String]) -> IO()
dispatch "todos" = todos
dispatch "new" = new
dispatch "crossoff" = crossoff
dispatch "putoff" = putoff
dispatch "moveto" = moveto
dispatch "delete" = remove


main = do 
	(date:command:argList) <- getArgs
	time <- getClockTime >>= toCalendarTime --https://wiki.haskell.org/Unix_tools/Date
	let todays_date = formatCalendarTime defaultTimeLocale "%Y-%m-%d" time
	let tomorrows_date = show (addDays 1 $ read todays_date::Data.Time.Day)
	let  todos_date | date == "today" = todays_date
	                | date == "tomorrow" = tomorrows_date
	                | otherwise = date
	when ((command `elem` ["todos"] && Data.List.null argList) || (command `elem` ["new", "crossoff", "putoff", "delete"] && length argList == 1) || (command == "moveto" && length argList == 2)) $ do
		username <- fmap fst readnetrc
		password <- fmap snd readnetrc
		token <- login [username, password]
		dispatch command (token, todos_date:argList)


readnetrc = do
	home <- getHomeDirectory
	netrc <- lines Control.Applicative.<$> readFile (home ++ "/.netrc")
	let netrc' = dropWhile (not . ("teuxdeux" `isInfixOf`)) netrc
	let (username, password) = if "login" `isInfixOf` head netrc'
		-- if entry is on one line	
		then (getcred "login", getcred "password") 
		-- if entry is on multiple lines
		else (last $ words $ netrc' !! 1, last $ words $ netrc' !! 2)
		where getcred c = dropWhile (not . (c `isInfixOf`)) (words $ head netrc') !! 1
	return (username, password)


curlget (token, date) = do
	let curlheader = "X-CSRF-Token: " ++ token
	body <- readProcess "curl" ["-s", "-L", "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader, "https://teuxdeux.com/api/v1/todos/calendar?begin_date="++date++"&end_date="++date] []
	let tds = decodeJSON body :: [Teuxdeux]
	let tdsf = Data.List.filter (\td -> current_date td == date && not (done td)) tds
	return tdsf
	

curlpost (token, [date, key, value, apiurl, okresponse]) number = do
	let curlheader = "X-CSRF-Token: " ++ token
	--Can be much improved, but will do for now:
	json <- if isJust number
		then do
			tdsf <- curlget (token, date)
			let itemid = Main.id $ tdsf!!(read (fromJust number)::Int)
			let modjson = "{ \"ids\" : [\""++show itemid++"\"], \""++key++"\" : \""++value++"\"}"
			return modjson
		else do
			--Can't just straight return these strings, need to let them first
			let newjson = "{ \"current_date\" : \""++date++"\", \""++key++"\" : \""++value++"\"}"
			return newjson
	body <- readProcess "curl" ["-s", "-XPOST", apiurl, "-L", "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader, "-H", "Content-Type: application/json", "-d", json] []
	if "done_updated_at" `isInfixOf` body
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"


curldelete (token, [date, apiurl, okresponse]) number = do
	tdsf <- curlget (token, date)
	let itemid = Main.id $ tdsf!!(read number::Int)
	let curlheader = "X-CSRF-Token: " ++ token
	body <- readProcess "curl" ["-s", "-XDELETE", apiurl++show itemid, "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader] []
	if "done_updated_at" `isInfixOf` body
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"


curlput (token, [date, json, apiurl, okresponse]) number = do
	tdsf <- curlget (token, date)
	let itemid = Main.id $ tdsf!!(read number::Int)
	let curlheader = "X-CSRF-Token: " ++ token
	body <- readProcess "curl" ["-s", "-XPUT", apiurl++show itemid, "-L", "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader, "-H", "Content-Type: application/json", "-d", json] []
	if "done_updated_at" `isInfixOf` body
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"


getauthtoken body = do
	let bodylines = lines body
	let authline = dropWhile (not . ("authenticity_token" `isInfixOf`)) bodylines
	let authwords = words $ head authline
	let authtokenword = stripPrefix "value=\"" $ last authwords
	let revauthtokenword = reverse $ fromJust authtokenword
	let authtoken = reverse $ fromJust $ stripPrefix ">\"" revauthtokenword
	return authtoken


login [username, password] = do
	--See if we have a token, then to clear we can just delete the file
	--TODO: handle that error
	home <- getHomeDirectory
	check <- doesFileExist (home ++ "/.haskerdeux-token")
	if check
		then
			readFile (home ++ "/.haskerdeux-token")
		else do
			body <- readProcess "curl" ["-s", "-L", "-c", "haskerdeux.cookies", "https://teuxdeux.com/login"] []
			token <- getauthtoken body
			writeFile (home ++ "/.haskerdeux-token") token
			--can probably use one post?
			let curlheader = "X-CSRF-Token: " ++ token
			let curlpostfields = "username=" ++ username ++ "&password=" ++ password ++ "&authenticity_token=" ++ token
			body <- readProcess "curl" ["-s", "-L", "-c", "haskerdeux.cookies", "-b", "haskerdeux.cookies", "-H", curlheader, "-d", curlpostfields, "https://teuxdeux.com/login"] []
			return token


todos (token, [todos_date]) = do
	tdsf <- curlget (token, todos_date)
	putStr $ unlines $ zipWith (\n td -> show n ++ " - " ++ td) [0..] $ Data.List.map text tdsf --numbering from LYAH


new (token, [todos_date, todo]) = do 
	let encodedtodo = Network.URI.Encode.encode todo
	curlpost (token, [todos_date, "text", todo, "https://teuxdeux.com/api/v1/todos/", "Added!"]) Nothing


crossoff (token, [todos_date, number]) =
	curlput (token, [todos_date, "{ \"done\": true }", "https://teuxdeux.com/api/v1/todos/", "Crossed Off!"]) number


putoff (token, [todos_date, number]) = do
	let tomorrows_date = show (addDays 1 $ read todos_date::Data.Time.Day)
	curlpost (token, [todos_date, "current_date", tomorrows_date, "https://teuxdeux.com/api/v1/todos/reposition/", "Put Off!"]) (Just number)


moveto (token, [todos_date, number, new_date]) =
	--TODO: Need to figure out moving to bottom of a list
	curlpost (token, [todos_date, "current_date", new_date, "https://teuxdeux.com/api/v1/todos/reposition", "Moved!"]) (Just number)


remove (token, [todos_date, number]) =
	curldelete (token, [todos_date, "https://teuxdeux.com/api/v1/todos/", "Deleted!"]) number


--Thanks to http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/ and http://hpaste.org/41263/parsing_json_with_textjson
data Teuxdeux = Teuxdeux {
    id :: Integer,
	current_date :: String, 
	text :: String,
	done :: Bool
} deriving (Eq, Show, Data, Typeable) 
