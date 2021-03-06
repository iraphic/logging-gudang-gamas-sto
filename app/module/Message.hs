module Module.Message where

import Data.Int
import Data.Time
import Data.Time.Clock.POSIX
import Module.Item

data LogMessage
    = LogMessage
        { item :: Int
        , quantity :: Int
        , timestamp :: Int
        , status :: Status
        }
    | Unknown
    deriving (Show)

data Status = MASUK | KELUAR | BARU | ERROR deriving (Show, Read)

secondSinceEpoch :: UTCTime -> Int
secondSinceEpoch =
    floor . nominalDiffTimeToSeconds . utcTimeToPOSIXSeconds

makeLogMessage :: LogItem -> String -> IO LogMessage
makeLogMessage item status = do
    u <- getCurrentTime
    let currentTime = secondSinceEpoch u
        message =
            if item == UnknownItem
                then
                    LogMessage
                        { item = 0
                        , quantity = 0
                        , timestamp = currentTime
                        , status = ERROR
                        }
                else
                    LogMessage
                        { item = itemId item
                        , quantity = storage item
                        , timestamp = currentTime
                        , status = read status :: Status
                        }
    return message

parseLogMessage :: LogMessage -> IO ()
parseLogMessage message = do
    u <- getCurrentTime
    let currentTime = secondSinceEpoch u
    let parsedLogMessage =
            "ID Barang: "
                ++ show (item message)
                ++ " | Status: "
                ++ show (status message)
                ++ " | Jumlah: "
                ++ show (quantity message)
                ++ " | Timestamp: "
                ++ show (currentTime)
                ++ "\n"
    appendFile "log/messages.log" parsedLogMessage
