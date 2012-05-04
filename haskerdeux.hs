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



dispatch :: String -> [String] -> IO ()
--dispatch "today" = today
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


--today :: [String] -> IO ()
--today [username, password] = do
--	let user = C.pack username
--	let pass = C.pack password
--	let req = applyBasicAuth user pass $ fromJust $ parseUrl  "https://teuxdeux.com/api/list.json"
--	res <- withManager $ httpLbs req
--	L.putStrLn $ responseBody res

	--http://stackoverflow.com/a/5614946/208793




test :: [String] -> IO ()
test [username, password, command] = do
	putStrLn username
	putStrLn password
	putStrLn command
