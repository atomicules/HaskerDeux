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
api_someday = "https://teuxdeux.com/api/someday.json"
api_update = "https://teuxdeux.com/api/update.json"
api_todo = "https://teuxdeux.com/api/todo.json"
    

--to fake the approach of badboy's teuxdeux can just do:
--let client = (username, password)
--
--curlGetString base function
respCGS [client, api, opts] = withCurlDo $ do
	let username = fst client
	    password = snd client
	    opts' = opts++[CurlUserPwd $ username++":"++password]
	curlGetString api opts'

user [client] = do
	body <- respCGS client api_user []
	decodeJSON $ snd body :: [User]

--Need to include someday param.
todos [client] = do
	body <- respCGS client api_list []
	decodeJSON $ snd body :: [Teuxdeux]
	

someday [client] = do
	body <- respCGS client api_someday []
	decodeJSON $ snd body :: [Teuxdeux]

--do_curl_ base function
respDC [client, api, opts] = withCurlDo $ do
	let username = fst client
	    password = snd client
	    opts' = opts++method_POST++[CurlUserPwd $ username++":"++password]
	curl <- initialize
	do_curl_ curl api :: IO CurlResponse


create_todo [client, todo, todo_date] = do
	let opts = [CurlPostFields ["todo_item[todo]="++todo, "todo_item[do_on]="++todo_date] ]
	respDC client api_todo opts 


update_todo [client, todo, todo_date] = do
	let opts = [CurlPostFields ["todo_item["++todo++"?][done]=1"] ]
	respDC client api_update opts 

--Need to handle slightly differently and use HTTP DELETE
--delete_todo client todo todo_date = do



--Thanks to http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/ and http://hpaste.org/41263/parsing_json_with_textjson
data Teuxdeux = Teuxdeux {
    tdid :: Integer,
	do_on :: String, 
	todo :: String,
	done :: Bool
} deriving (Eq, Show, Data, Typeable) 

data User = User {
  uid :: Integer,
  login :: String,
  email :: String,
  time_zone :: String,
  utc_offset :: Integer
} deriving (Eq, Show, Data, Typeable) 
