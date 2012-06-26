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

--API Addresses

api_user = "https://teuxdeux.com/api/user.json"
api_list = "https://teuxdeux.com/api/list.json"
api_update = "https://teuxdeux.com/api/update.json"
api_todo = "https://teuxdeux.com/api/todo.json"
    

--to fake the approach of badboy's teuxdeux can just do:
--let client = (username, password)
--

resp client api = withCurlDo $ do
	let username = fst client
	    password = snd client
	    opts = [CurlUserPwd $ username++":"++password]  --http://stackoverflow.com/a/2140445/208793
	curlGetString api opts

user client = withCurlDo $ do
	resp client user


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
