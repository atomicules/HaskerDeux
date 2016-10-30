{-# LANGUAGE DeriveDataTypeable #-}
--HaskerDeux

import System.Environment
import System.IO
import System.IO.Error
import Data.List
import Data.List.Split --need to install
import Data.Map
import Network.Curl --need to install
import Control.Monad
import Data.Maybe
import Text.JSON --need to install for JSON
import Text.JSON.Generic --need to install for JSON
--import Data.Time --Seriously datA.time? This doesn't work for me now. At least 3 years out of sync!
import System.Time
import System.Locale (defaultTimeLocale)
import System.Directory
--import Web.Encodings --need to install. Now depreciated, but I'm behind on GHC versions. Is this actually used? Oh yeah for decodeJSON, but should be able to use Text.JSON instead to decode
--import Data.Text
import Network.URI.Encode --need to install

--Note to self: to run you type `runhaskell haskerdeux.hs test "me" "this" "that"`, etc
dispatch :: String -> (Curl, String, [String]) -> IO ()
dispatch "today" = today
--dispatch "new" = new
dispatch "crossoff" = crossoff
--dispatch "putoff" = putoff
--dispatch "moveto" = moveto
--dispatch "delete" = remove
--Since we might want to force a login
dispatch "test" = test


main = withCurlDo $ do 
	curl <- initialize
	--Get today's date. Need <- else get IO string
	time <- getClockTime >>= toCalendarTime --https://wiki.haskell.org/Unix_tools/Date
	let todays_date = formatCalendarTime defaultTimeLocale "%Y-%m-%d" time
	(command:argList) <- getArgs
	if (command == "today" && Data.List.null argList) || (command == "test" && Data.List.null argList) || (command `elem` ["new", "crossoff", "putoff", "delete"] && length argList == 1) || (command == "moveto" && length argList == 2)  
		then do 
			username <- fmap fst readnetrc
			password <- fmap snd readnetrc
			token <- login (curl, [username, password])
			dispatch command (curl, token, todays_date:argList)
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


curlget (curl, token, todays_date) = do
	let curlheaders = CurlHttpHeaders ["X-CSRF-Token: " ++ token]
	let opts = method_GET ++ [CurlCookieFile "haskerdeux.cookies", CurlCookieJar "haskerdeux.cookies", curlheaders, CurlVerbose False]
	resp <- do_curl_ curl ("https://teuxdeux.com/api/v1/todos/calendar?begin_date="++todays_date++"&end_date="++todays_date) opts :: IO CurlResponse
	--let opts1 = [] 
	--body <- curlGetString "https://teuxdeux.com/api/list.json" opts1
	let tds = decodeJSON $ respBody resp :: [Teuxdeux]
	let tdsf = Data.List.filter (\td -> current_date td == todays_date && not (done td)) tds
	return tdsf
	

--curlpost [todays_date, curlpostdata, apiurl, okresponse] number = withCurlDo $ do
--	curlpostfields <- if isJust number
--		then do
--			tdsf <- curlget todays_date
--			let itemid = Main.id $ tdsf!!(read (fromJust number)::Int)
--			return $ CurlPostFields ["todo_item["++show itemid++"?]"++curlpostdata]
--		else return $ CurlPostFields ["todo_item[todo]="++curlpostdata, "todo_item[do_on]="++todays_date]
--	let opts = method_POST ++ [curlpostfields]
--	curl <- initialize
--	resp <- do_curl_ curl apiurl opts :: IO CurlResponse
--	if respCurlCode resp == CurlOK && respStatus resp == 200
--		then putStrLn okresponse
--		else putStrLn "Uh Oh! Didn't work!"
--
--
--curldelete [todays_date, apiurl, okresponse] number = withCurlDo $ do
--	--Not really a DELETE, rather a POST supporting it. Means duplication of code, but keeps the curlpost above clean
--	tdsf <- curlget todays_date
--	let itemid = Main.id $ tdsf!!(read number::Int)
--	let curlpostfields = return $ CurlPostFields ["_method=delete"]
--	let opts = method_POST ++ [curlpostfields]
--	curl <- initialize
--	resp <- do_curl_ curl (apiurl++(show itemid)) opts :: IO CurlResponse
--	if respCurlCode resp == CurlOK && respStatus resp == 200
--		then putStrLn okresponse
--		else putStrLn "Uh Oh! Didn't work!"

curlput (curl, token, [todays_date, json, apiurl, okresponse]) number = do
	--Need the json we are PUTTING somewhere in here
	tdsf <- curlget (curl, token, todays_date)
	--Need some way to post the body.
	--Need headers for posting json "Content-Type: application/json"
	-- -d ""
	let itemid = Main.id $ tdsf!!(read number::Int)
	--let curlpostfields = return $ CurlPostFields [json] --try json here
	let curlheaders = CurlHttpHeaders ["X-CSRF-Token: " ++ token, "Content-Type: application/json", "Expect:", "Content-Length: 13"]
	let opts = [CurlCookieFile "haskerdeux.cookies", CurlCookieJar "haskerdeux.cookies", curlheaders, CurlPostFields [json], CurlUpload True, CurlVerbose True]
	resp <- do_curl_ curl (apiurl++(show itemid)) opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
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


login (curl, [username, password]) = do
	let opts = method_GET ++ [CurlFollowLocation True, CurlCookieJar "haskerdeux.cookies", CurlVerbose False]
	resp <- do_curl_ curl ("https://teuxdeux.com/login") opts :: IO CurlResponse
	let body = respBody resp
	token <- getauthtoken body
	--home <- getHomeDirectory
	--authtoken <- readFile (home ++ "/.haskerdeux-token")
	let curlpostfields = CurlPostFields ["username=" ++ username, "password=" ++ password, "authenticity_token=" ++ token] 
	let curlheaders = CurlHttpHeaders ["X-CSRF-Token: " ++ token]
	let opts = method_POST ++ [CurlCookieFile "haskerdeux.cookies", CurlCookieJar "haskerdeux.cookies", curlpostfields, curlheaders, CurlFollowLocation True, CurlVerbose False]
	resp <- do_curl_ curl "https://teuxdeux.com/login" opts :: IO CurlResponse
	return token


test (curl, token, [todays_date]) = do
	let curlheaders = CurlHttpHeaders ["X-CSRF-Token: " ++ token]
	let opts = method_GET ++ [CurlCookieFile "haskerdeux.cookies", CurlCookieJar "haskerdeux.cookies", curlheaders, CurlVerbose True]
	resp <- do_curl_ curl ("https://teuxdeux.com/api/v1/todos/calendar?begin_date="++todays_date++"&end_date="++todays_date) opts :: IO CurlResponse
	putStr $ respBody resp


today (curl, token, [todays_date]) = do
	tdsf <- curlget (curl, token, todays_date)
	putStr $ unlines $ zipWith (\n td -> show n ++ " - " ++ td) [0..] $ Data.List.map text tdsf --numbering from LYAH


--new (curl, [todays_date, todo]) = do 
--	let encodedtodo = Network.URI.Encode.encode todo
--	curlpost [todays_date, encodedtodo, "https://teuxdeux.com/api/todo.json", "Added!"] Nothing
--
--
crossoff (curl, token, [todays_date, number]) = 
	curlput (curl, token, [todays_date, "{ \"done\": true }", "https://teuxdeux.com/api/v1/todos/", "Crossed Off!"]) number
	-- is a PUT to https://teuxdeux.com/api/v1/todos/42396076
	--should just be able to do "done": true, but might need whole object...
--
--putoff (curl, [todays_date, number]) = do
--	let tomorrows_date = show (addDays 1 $ read todays_date::Day)
--	curlpost [todays_date, "[do_on]="++tomorrows_date, "https://teuxdeux.com/api/update.json", "Put Off!"] (Just number)
--
--
--moveto (curl, [todays_date, number, new_date]) = 
--	curlpost [todays_date, "[do_on]="++new_date, "https://teuxdeux.com/api/update.json", "Moved!"] (Just number)
--
--
--remove (curl, [todays_date, number]) = 
--	curldelete [todays_date, "_method=delete", "https://teuxdeux.com/api/todo/", "Deleted!"] number


--Thanks to http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/ and http://hpaste.org/41263/parsing_json_with_textjson
data Teuxdeux = Teuxdeux {
    id :: Integer,
	current_date :: String, 
	text :: String,
	done :: Bool
} deriving (Eq, Show, Data, Typeable) 
