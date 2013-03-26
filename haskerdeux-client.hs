
import System.Environment
import System.IO
import System.IO.Error
import Data.List
import Data.List.Split --need to install
import Control.Monad
import Data.Maybe
import Data.Time
import System.Locale (defaultTimeLocale)


dispatch :: String -> [String] -> IO ()
dispatch "today" = today
dispatch "new" = new
dispatch "crossoff" = crossoff
dispatch "putoff" = putoff
dispatch "moveto" = moveto
dispatch "delete" = delete


main = do 

	--Get today's date. Need <- else get IO string
	todays_date <- fmap (formatTime defaultTimeLocale "%Y-%m-%d") getCurrentTime

	(command:argList) <- getArgs
	dispatch command $ todays_date:argList


today :: [String] -> IO ()
today [todays_date, username, password] = withCurlDo $ do
	let opts = [CurlUserPwd $ username++":"++password] --http://stackoverflow.com/a/2140445/208793
	body <- curlGetString "https://teuxdeux.com/api/list.json" opts
	let tds = decodeJSON $ snd body :: [Teuxdeux]
	let tdsf = filter (\td -> do_on td ==todays_date && done td == False) tds
	putStr $ unlines $ zipWith (\n td -> show n ++ " - " ++ td) [0..] $ map (\td ->  todo td) tdsf --numbering from LYAH


new :: [String] -> IO ()
new [todays_date, username, password, todo] = withCurlDo $ do
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields ["todo_item[todo]="++todo, "todo_item[do_on]="++todays_date] ]
	curl <- initialize
	resp <- do_curl_ curl "https://teuxdeux.com/api/todo.json" opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn "Added!"
		else putStrLn "Uh Oh! Didn't work!"


crossoff :: [String] -> IO ()
crossoff [todays_date, username, password, number] = withCurlDo $ do
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
putoff [todays_date, username, password, number] = withCurlDo $ do
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


