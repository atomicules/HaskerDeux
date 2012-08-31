{-# LANGUAGE DeriveDataTypeable #-}
--HaskerDeux

import System.Environment
import System.IO
import System.IO.Error
import Data.List
import Data.List.Split --need to install
import Network.Curl --need to install
import Data.Word (Word32) --for use with Curl port
import Control.Monad
import Data.Maybe
import Text.JSON --need to install for JSON
import Text.JSON.Generic --need to install for JSON
import Data.Time
import System.Locale (defaultTimeLocale)
import System.Directory

--Note to self: to run you type `runhaskell haskeduex.hs test "me" "this" "that"`, etc
dispatch :: String -> [String] -> IO ()
dispatch "today" = today
dispatch "new" = new
dispatch "crossoff" = crossoff
dispatch "putoff" = putoff
dispatch "moveto" = moveto


main = do 

	--Get today's date. Need <- else get IO string
	todays_date <- fmap (formatTime defaultTimeLocale "%Y-%m-%d") getCurrentTime

	(command:argList) <- getArgs
	--If username and password not supplied read from netrc
	if (command == "today" && length argList == 0) || ((command == "new" || command =="crossoff" || command == "putoff") && length argList == 1) || (command == "moveto" && length argList == 2)  
		then do 
			username <- fmap fst readnetrc
			password <- fmap snd readnetrc
			dispatch command $ todays_date:argList++[username, password]
		else dispatch command $ todays_date:argList


readnetrc = do
	home <- getHomeDirectory
	netrc <- fmap lines $ readFile (home ++ "/.netrc")
	let netrc' = dropWhile (not . isInfixOf "teuxdeux") netrc
	let (username, password) = if "login" `isInfixOf` (head netrc')
		-- if entry is on one line	
		then (getcred "login", getcred "password") 
		-- if entry is on multiple lines
		else (last $ words $ netrc' !! 1, last $ words $ netrc' !! 2)
		where getcred = \c -> (dropWhile (not . isInfixOf c) $ words $ head netrc') !! 1
	return (username, password)


today :: [String] -> IO ()
today [todays_date, username, password] = withCurlDo $ do
	let opts = [CurlUserPwd $ username++":"++password] --http://stackoverflow.com/a/2140445/208793
	body <- curlGetString "https://teuxdeux.com/api/list.json" opts
	let tds = decodeJSON $ snd body :: [Teuxdeux]
	let tdsf = filter (\td -> do_on td ==todays_date && done td == False) tds
	putStr $ unlines $ zipWith (\n td -> show n ++ " - " ++ td) [0..] $ map (\td ->  todo td) tdsf --numbering from LYAH


new :: [String] -> IO ()
new [todays_date, todo, username, password] = withCurlDo $ do
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields ["todo_item[todo]="++todo, "todo_item[do_on]="++todays_date] ]
	curl <- initialize
	resp <- do_curl_ curl "https://teuxdeux.com/api/todo.json" opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn "Added!"
		else putStrLn "Uh Oh! Didn't work!"


crossoff :: [String] -> IO ()
crossoff [todays_date, number, username, password] = withCurlDo $ do
	--Somehow convert number to item id. Since they aren't in memory, which?
	--Need to get a list of todos again
	--Need to do this DRYly at some point though
	let opts1 = [CurlUserPwd $ username++":"++password] 
	body <- curlGetString "https://teuxdeux.com/api/list.json" opts1
	let tds = decodeJSON $ snd body :: [Teuxdeux]
	let tdsf = filter (\td -> do_on td ==todays_date && done td == False) tds
	let itemid = Main.id $ tdsf!!(read number::Int)
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields ["todo_item["++(show itemid)++"?][done]=1"] ]
	curl <- initialize
	resp <- do_curl_ curl "https://teuxdeux.com/api/update.json" opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn "Crossed Off!"
		else putStrLn "Uh Oh! Didn't work!"


putoff :: [String] -> IO ()
putoff [todays_date, number, username, password] = withCurlDo $ do
	let tomorrows_date = show (addDays 1 $ read todays_date::Day)
	let opts1 = [CurlUserPwd $ username++":"++password] 
	body <- curlGetString "https://teuxdeux.com/api/list.json" opts1
	let tds = decodeJSON $ snd body :: [Teuxdeux]
	let tdsf = filter (\td -> do_on td ==todays_date && done td == False) tds
	let itemid = Main.id $ tdsf!!(read number::Int)
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields ["todo_item["++(show itemid)++"?][do_on]="++tomorrows_date] ]
	curl <- initialize
	resp <- do_curl_ curl "https://teuxdeux.com/api/update.json" opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn "Put Off!"
		else putStrLn "Uh Oh! Didn't work!"


moveto :: [String] -> IO ()
moveto [todays_date, number, new_date, username, password] = withCurlDo $ do
	let opts1 = [CurlUserPwd $ username++":"++password] 
	body <- curlGetString "https://teuxdeux.com/api/list.json" opts1
	let tds = decodeJSON $ snd body :: [Teuxdeux]
	let tdsf = filter (\td -> do_on td ==todays_date && done td == False) tds
	let itemid = Main.id $ tdsf!!(read number::Int)
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields ["todo_item["++(show itemid)++"?][do_on]="++new_date] ]
	curl <- initialize
	resp <- do_curl_ curl "https://teuxdeux.com/api/update.json" opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn "Moved!"
		else putStrLn "Uh Oh! Didn't work!"

--Thanks to http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/ and http://hpaste.org/41263/parsing_json_with_textjson
data Teuxdeux = Teuxdeux {
    id :: Integer,
	do_on :: String, 
	todo :: String,
	done :: Bool
} deriving (Eq, Show, Data, Typeable) 
