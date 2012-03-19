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

getEnvVar x = do {
	var <- getEnv x;
	return (Just var);
} `catch` \ex -> do {
	return Nothing
}

--setproxy :: Maybe String -> [CurlOption] --very close to working, but the [CurlOption] isn't quite right
--setproxy :: Monad m => Maybe [Char] -> m [CurlOption]
--apparently!
setproxy proxy = do
	let systemproxyparts = reverse $ splitOneOf "/;:@" $ fromJust proxy --surely fromJust is ok in this scenerio?
	let port = read(systemproxyparts !! 0)::Word32
	let opts = if isInfixOf "@" $ fromJust proxy
		then [ CurlProxyPort port , CurlProxy $ systemproxyparts !! 1, CurlProxyPassword  $ systemproxyparts !! 2 , CurlProxyUser $ systemproxyparts !! 3] 
		else [ CurlProxyPort port, CurlProxy $ systemproxyparts !! 1 ]
	return opts













