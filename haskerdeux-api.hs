{-# LANGUAGE DeriveDataTypeable #-}
--HaskerDeux

import System.Environment
import System.IO
import System.IO.Error
import Data.List
import Data.List.Split --need to install
import Network.Curl --need to install
import Control.Monad
import Data.Maybe
import Text.JSON --need to install for JSON
import Text.JSON.Generic --need to install for JSON
import Data.Time
import System.Locale (defaultTimeLocale)

--API Addresses
api_user = "https://teuxdeux.com/api/user.json"
api_list = "https://teuxdeux.com/api/list.json"
api_update = "https://teuxdeux.com/api/update.json"
api_todo = "https://teuxdeux.com/api/todo.json"
    

--Curl abstraction thingys
curlget [apiurl, username, password] = withCurlDo $ do
	let opts1 = [CurlUserPwd $ username++":"++password] 
	body <- curlGetString api_url opts1
	let tds = decodeJSON $ snd body :: [Teuxdeux]
	return tds
	

curlpost [apiurl, curlpostdata, okresponse, username, password] = withCurlDo $ do
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, curlpostdata]
	curl <- initialize
	resp <- do_curl_ curl apiurl opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"


curldelete [apiurl, curlpostdata, okresponse, username, password]  = withCurlDo $ do
	--Not really a DELETE, rather a POST supporting it. Means duplication of code, but keeps the curlpost above clean
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields $ return curlpostdata]
	curl <- initialize
	resp <- do_curl_ curl (apiurl++(show itemid)) opts :: IO CurlResponse
	if respCurlCode resp == CurlOK && respStatus resp == 200
		then putStrLn okresponse
		else putStrLn "Uh Oh! Didn't work!"


--api methods
todos client = withCurlDo $ do
	body client list

	let tds = decodeJSON $ snd body :: [Teuxdeux]
	

someday client = withCurl $ do
	body client list




create_todo client todo = withCurlDo $ do
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields ["todo_item[todo]="++todo, "todo_item[do_on]="++todays_date] ]
	curl <- initialize
	resp <- do_curl_ curl "https://teuxdeux.com/api/todo.json" opts :: IO CurlResponse



update_todo [todays_date, username, password, number] = withCurlDo $ do
	
	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields ["todo_item["++(show itemid)++"?][done]=1"] ]
	curl <- initialize
	resp <- do_curl_ curl "https://teuxdeux.com/api/update.json" opts :: IO CurlResponse


delete_todo [todays_date, username, password, number] = withCurlDo $ do

	let opts = method_POST ++ [CurlUserPwd $ username++":"++password, CurlPostFields ["todo_item["++(show itemid)++"?][do_on]="++tomorrows_date] ]
	curl <- initialize
	resp <- do_curl_ curl "https://teuxdeux.com/api/update.json" opts :: IO CurlResponse



--Thanks to http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/ and http://hpaste.org/41263/parsing_json_with_textjson
data Teuxdeux = Teuxdeux {
    id :: Integer,
	do_on :: String, 
	todo :: String,
	done :: Bool
} deriving (Eq, Show, Data, Typeable) 

data User = User {
  id: Integer,
  login: String,
  email: String,
  time_zone: String,
  utc_offset: <timezone offset in minutes>
}
