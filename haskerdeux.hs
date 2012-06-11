{-# LANGUAGE DeriveDataTypeable #-}
--HaskerDeux

import System.Environment
import System.IO
import System.IO.Error
import Data.List
import Data.List.Split --need to install
import Network.Curl --need to install
--import Network.TLS --still needed with Curl?
import Data.Word (Word32) --for use with Curl port
import Control.Monad
import Data.Maybe
import Text.JSON --need to install for JSON
import Text.JSON.Generic --need to install for JSON
import qualified Data.Map as Map
import Data.Time
import System.Locale (defaultTimeLocale)


--Note to self: to run you type `runhaskell haskeduex.hs test "me" "this" "that"`, etc
dispatch :: String -> [String] -> IO ()
dispatch "today" = today
--dispatch "new" = new
--dispatch "complete" = complete
dispatch "test" = test
--dispatch "edit" = edit
--dispatch "delete" = delete

--Define function to get Env variable.
--from http://stackoverflow.com/a/2682887/208793
--As don't care about error, just the actual thing.
getEnvVar x = do {
	var <- getEnv x;
	return (Just var);
} `catch` \ex -> do {
	return Nothing
} 


setproxy :: Monad m => Maybe [Char] -> m [CurlOption]
setproxy proxy = do
	let systemproxyparts = reverse $ splitOneOf "/;:@" $ fromJust proxy --surely fromJust is ok in this scenerio?
	let port = read(systemproxyparts !! 0)::Word32
	let proxyopts = if isInfixOf "@" $ fromJust proxy
		then [ CurlProxyPort port , CurlProxy $ systemproxyparts !! 1, CurlProxyPassword  $ systemproxyparts !! 2 , CurlProxyUser $ systemproxyparts !! 3] 
		else [ CurlProxyPort port, CurlProxy $ systemproxyparts !! 1 ]
	return proxyopts

main = withCurlDo $ do --http://flygdynamikern.blogspot.com/2009/03/extended-sessions-with-haskell-curl.html

	systemproxy <- getEnvVar "http-proxy"

	let opts = if isJust systemproxy
		then head $ setproxy systemproxy --I don't get why this is a nested list. Something to do with the return statement?
		else []
	

	curl <- initialize
	setopts curl opts

	(command:argList) <- getArgs
	dispatch command argList


today :: [String] -> IO ()
today [username, password] = do
	let opts = [CurlUserPwd $ username++":"++password] --http://stackoverflow.com/a/2140445/208793
	body <- curlGetString "https://teuxdeux.com/api/list.json" opts
	let tds = decodeJSON $ snd body :: [Teuxdeux]
	--Get today's date. Need <- else get IO string
	todays_date <-  fmap (formatTime defaultTimeLocale "%Y-%m-%d") getCurrentTime
	print $ filter (\td -> do_on td ==todays_date) tds



test :: [String] -> IO ()
test [username, password, command] = do
	putStrLn username
	putStrLn password
	putStrLn command

--Thanks to http://www.amateurtopologist.com/blog/2010/11/05/a-haskell-newbies-guide-to-text-json/ and http://hpaste.org/41263/parsing_json_with_textjson
data Teuxdeux = Teuxdeux {
    id :: Integer,
	do_on :: String, 
	todo :: String,
	done :: Bool
} deriving (Eq, Show, Data, Typeable) 



