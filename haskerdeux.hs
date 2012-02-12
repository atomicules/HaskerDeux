--HaskerDeux

import System.Environment
import System.IO
import Data.List

import Network.HTTP.Conduit
import Network.TLS
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy as L
import Data.Maybe (fromJust)
import Network.HTTP.Proxy (parseProxy)

dispatch :: String -> [String] -> IO ()
dispatch "today" = today
--dispatch "new" = new
--dispatch "complete" = complete
dispatch "test" = test
--dispatch "edit" = edit
--dispatch "delete" = delete


main = do
	(command:argList) <- getArgs
	dispatch command argList


--logon? Don't know how to cache credentials though, just send with each command for now


today :: [String] -> IO ()
today [username, password] = do
	
	let user = C.pack username
	let pass = C.pack password

	--Proxy Support notes
	--===================
	--http-conduit does it in host port fashion
	--let proxyhost = ""
	--let proxyport = read "80"::Int --As otherwise is Integer which is wrong type
	--which then somehow gets added like to 
	--let req = addProxy proxy $ applyBasicAuth user pass $ fromJust $ parseUrl  "https://teuxdeux.com/api/list.json"
	--But don't think I can do authentication like that. Need it in the form that simpleHTTP uses:
	--let proxy = parseProxy "http://<username>:<password>@<proxyhost>:<proxyport>"
	--But then I don't believe simpleHTTP does https?
	let req = applyBasicAuth user pass $ fromJust $ parseUrl  "https://teuxdeux.com/api/list.json"
	--But next problem is http-conduit and https certs. Need to do something like:
	--let manager = newManager manSettings
	--where 
	--	manSettings = managerCheckCerts = \ _ _ -> return CertificateUsageAccept
	
	res <- withManager $ httpLbs req

	L.putStrLn $ responseBody res

	--http://stackoverflow.com/a/5614946/208793


test :: [String] -> IO ()
test [username, password, command] = do
	putStrLn username
	putStrLn password
	putStrLn command
