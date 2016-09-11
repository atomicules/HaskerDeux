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
import Data.Time
import System.Locale (defaultTimeLocale)
import System.Directory
--import Web.Encodings --need to install. Now depreciated, but I'm behind on GHC versions. Is this actually used? Oh yeah for decodeJSON, but should be able to use Text.JSON instead to decode

--Note to self: to run you type `runhaskell haskerdeux.hs test "me" "this" "that"`, etc
dispatch :: String -> [String] -> IO ()
dispatch "today" = today
dispatch "new" = new
dispatch "crossoff" = crossoff
dispatch "putoff" = putoff
dispatch "moveto" = moveto
dispatch "delete" = remove
--Since we might want to force a login
dispatch "login" = login


main = do 
	--Get today's date. Need <- else get IO string
	todays_date <- fmap (formatTime defaultTimeLocale "%Y-%m-%d") getCurrentTime
	(command:argList) <- getArgs
	--If username and password not supplied read from netrc
	if (command == "today" && null argList) || (command `elem` ["new", "crossoff", "putoff", "delete"] && length argList == 1) || (command == "moveto" && length argList == 2)  
		then do 
			username <- fmap fst readnetrc
			password <- fmap snd readnetrc
			dispatch command $ todays_date:argList++[username, password]
		else dispatch command $ todays_date:argList


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


curlget [todays_date, username, password] = withCurlDo $ do
	let opts1 = [CurlUserPwd $ username++":"++password] 
	body <- curlGetString "https://teuxdeux.com/api/list.json" opts1
	let tds = decodeJSON $ snd body :: [Teuxdeux]
	let tdsf = filter (\td -> do_on td ==todays_date && not (done td)) tds
	return tdsf
	

curlpost [todays_date, curlpostdata, apiurl, okresponse, username, password] number = withCurlDo $ do
	curlpostfields <- if isJust number
		then do
			tdsf <- curlget [todays_date, username, password]
			let itemid = Main.id $ tdsf!!(read (fromJust number)::Int)
			return $ CurlPostFields ["todo_item["++show itemid++"?]"++curlpostdata]
		else return $ CurlPostFields ["todo_item[todo]="++curlpostdata, "todo_item[do_on]="++todays_date]
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, curlpostfields]
	curl <- initialize
	resp <- do_curl_ curl apiurl opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"


curldelete [todays_date, curlpostdata, apiurl, okresponse, username, password] number = withCurlDo $ do
	--Not really a DELETE, rather a POST supporting it. Means duplication of code, but keeps the curlpost above clean
	tdsf <- curlget [todays_date, username, password]
	let itemid = Main.id $ tdsf!!(read number::Int)
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields $ return curlpostdata]
	curl <- initialize
	resp <- do_curl_ curl (apiurl++(show itemid)) opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"


getauthtoken = withCurlDo $ do
	curl <- initialize
	--Could use curlgetstring for this
	let opts = method_GET ++ [CurlFollowLocation True, CurlCookieJar "haskerdeux.cookies", CurlVerbose True]
	resp <- do_curl_ curl ("https://teuxdeux.com/login") opts :: IO CurlResponse
	let body = respBody resp
	let bodylines = lines body
	let authline = dropWhile (not . isInfixOf "authenticity_token") bodylines
	let authwords = words $ head authline
	let authtokenword = stripPrefix "value=\"" $ last authwords
	let revauthtokenword = reverse $ fromJust authtokenword
	let authtoken = reverse $ fromJust $ stripPrefix ">\"" revauthtokenword
	home <- getHomeDirectory
	writeFile (home ++ "/.haskerdeux-token") authtoken

--let headers = Data.Map.fromList(respHeaders resp)
--let cookietuple = fromJust $ Data.Map.lookup "Set-Cookie" headers
--let cookie = head $ Data.List.Split.splitOn ";" $ (Data.List.Split.splitOn "=" cookietuple)!!1
--writeFile ".haskerdeux-cookie" cookie

login [username, password] = withCurlDo $ do
	getauthoken
	authtoken <- readFile (home ++ "/.haskerdeux-token")
    let curlpostfields = CurlPostFields ["username=" ++ username, "password=" ++ password, "authenticity_token=" ++ authtoken] 
	let curlheaders = CurlHttpHeaders ["X-CSRF-Token: " ++ authtoken]
	--let opts = method_POST ++ [CurlCookie $ "rack.session=" ++ cookie,  curlpostfields, curlheaders, CurlFollowLocation True]
	let opts = method_POST ++ [CurlCookieFile "haskerdeux.cookies", CurlCookieJar "haskerdeux.cookies", curlpostfields, curlheaders, CurlFollowLocation True]
	resp <- do_curl_ curl "https://teuxdeux.com/login" opts :: IO CurlResponse
	--let opts = method_GET ++ [CurlCookie $ "rack.session=" ++ cookie, curlheaders]


--
	let opts = method_GET ++ [CurlCookieFile "haskerdeux.cookies", curlheaders]
	resp <- do_curl_ curl "https://teuxdeux.com/api/v1/todos/calendar?begin_date=2016-08-16&end_date=2016-08-17" opts :: IO CurlResponse


today [todays_date] = do
	tdsf <- curlget [todays_date]
	putStr $ unlines $ zipWith (\n td -> show n ++ " - " ++ td) [0..] $ map todo tdsf --numbering from LYAH


new [todays_date, todo] = do 
	let encodedtodo = encodeUrl todo
	curlpost [todays_date, encodedtodo, "https://teuxdeux.com/api/todo.json", "Added!", username, password] Nothing


crossoff [todays_date, number] = 
	curlpost [todays_date, "[done]=1", "https://teuxdeux.com/api/update.json", "Crossed Off!", username, password] (Just number)


putoff [todays_date, number] = do
	let tomorrows_date = show (addDays 1 $ read todays_date::Day)
	curlpost [todays_date, "[do_on]="++tomorrows_date, "https://teuxdeux.com/api/update.json", "Put Off!", username, password] (Just number)


moveto [todays_date, number, new_date] = 
	curlpost [todays_date, "[do_on]="++new_date, "https://teuxdeux.com/api/update.json", "Moved!", username, password] (Just number)


remove [todays_date, number] = 
	curldelete [todays_date, "_method=delete", "https://teuxdeux.com/api/todo/", "Deleted!", username, password] number


--Thanks to http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/ and http://hpaste.org/41263/parsing_json_with_textjson
data Teuxdeux = Teuxdeux {
    id :: Integer,
	do_on :: String, 
	todo :: String,
	done :: Bool
} deriving (Eq, Show, Data, Typeable) 
