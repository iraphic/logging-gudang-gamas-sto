module Main where

import Control.Monad.Trans.Reader (ReaderT (runReaderT), ask)
import Control.Monad.Trans.Writer (WriterT, execWriterT, runWriterT, tell)
import Data.List
import Helper (MaybeT, liftMaybeT, maybeReadInt, prompt, runMaybeT)
import Module.Item (LogItem (UnknownItem), addNewItem, description, itemId, itemName, parseItem, parseLogItem, restockItem, storage, takeItem)
import Module.Message (LogMessage, makeLogMessage, parseLogMessage)
import System.IO (hFlush, stdout)

runProgram :: [LogItem] -> [LogMessage] -> IO ()
runProgram items messages = do
    putStrLn "\n\n\n=============== Sistem Pencatatan Gudang Gamas STO CPP Witel Jakarta Pusat ==============="
    putStrLn $ replicate 90 '='
    putStrLn $ showAllItem items
    putStrLn "(1) Isi ulang barang | (2) Ambil barang | (3) Tambah barang baru | (4) Lihat histori keluar masuk barang | (5) Cari histori barang | (6) Keluar"
    choice <- prompt "Masukkan pilihan: "
    case choice of
        --"a" -> do
          --  putStrLn $ showAllItem items
          --  empty <- prompt "Tekan Enter untuk kembali"
          --  runProgram items messages

        "1" -> do
            putStrLn "Anda akan mengisi ulang barang: "
            -- Insert ItemID
            putStr "Masukkan ID Barang: "
            hFlush stdout
            choice <- do
                result <- runMaybeT maybeReadInt
                case result of
                    (Just a) -> return a
                    Nothing -> return 0
            -- Insert Amount
            putStr "Masukkan jumlah isi ulang barang: "
            hFlush stdout
            amount <- do
                result <- runMaybeT maybeReadInt
                case result of
                    (Just a) -> return a
                    Nothing -> return 0

            newRestockedItems <- restockItem items choice amount
            parseLogItem newRestockedItems
            let changedItem = find (\item -> itemId item == choice) newRestockedItems
                extractItem :: Maybe LogItem -> LogItem
                extractItem (Just a) = a
                extractItem Nothing = UnknownItem

            let extractedItem = extractItem changedItem

            logMessage <-
                if extractedItem == UnknownItem
                    then makeLogMessage extractedItem "ERROR"
                    else makeLogMessage (extractedItem{storage = amount}) "MASUK"

            parseLogMessage logMessage
            emptyPrompt <- prompt "Tekan Enter untuk lanjut"
            runProgram newRestockedItems messages

        "2" -> do
            putStrLn "Anda akan mengambil barang: "
            -- Insert ItemID
            putStr "Masukkan ID Barang: "
            hFlush stdout
            choice <- do
                result <- runMaybeT maybeReadInt
                case result of
                    (Just a) -> return a
                    Nothing -> return 0
            -- Insert Amount
            putStr "Masukkan jumlah yang akan diambil: "
            hFlush stdout
            amount <- do
                result <- runMaybeT maybeReadInt
                case result of
                    (Just a) -> return a
                    Nothing -> return 0

            updatedItems <- takeItem items choice amount
            parseLogItem updatedItems

            let changedItem = find (\item -> itemId item == choice) updatedItems
                extractItem :: Maybe LogItem -> LogItem
                extractItem (Just a) = a
                extractItem Nothing = UnknownItem

            let extractedItem = extractItem changedItem

            logMessage <-
                if extractedItem == UnknownItem
                    then makeLogMessage extractedItem "ERROR"
                    else
                        if amount > storage extractedItem
                            then makeLogMessage (extractedItem{storage = 0}) "ERROR"
                            else makeLogMessage (extractedItem{storage = amount}) "KELUAR"
            parseLogMessage logMessage
            emptyPrompt <- prompt "Tekan Enter untuk lanjut."
            runProgram updatedItems messages

        "3" -> do
            putStrLn "\nAnda akan menambahkan barang baru ke dalam inventaris, harap isi informasi di bawah ini: "
            name <- prompt "Nama barang: "
            putStr "Jumlah: "
            hFlush stdout
            storage <- do
                result <- runMaybeT maybeReadInt
                case result of
                    (Just a) -> return a
                    Nothing -> return 0
            description <- prompt "Deskripsi barang: "
            newItems <- addNewItem items name storage description
            parseLogItem newItems
            logMessage <- makeLogMessage (last newItems) "BARU"
            parseLogMessage logMessage
            emptyPrompt <- prompt "Berhasil menambahkan barang baru! Tekan Enter untuk melanjutkan."
            runProgram newItems messages

        "6" -> do
            putStrLn "Keluar..."
            putStrLn "Sampai jumpa! Terima kasih"

        _ -> do
            empty <- prompt "Salah inputan! Tekan Enter untuk mencoba lagi."
            runProgram items messages

showItem :: [LogItem] -> String
showItem items = showItemFunc (length items) (take 2 items)
  where
    showItemFunc count [] = case count of
        0 -> "Daftar barang saat ini kosong.\n" ++ replicate 58 '='
        1 -> "\n" ++ replicate 58 '='
        2 -> "\n" ++ replicate 58 '='
        _ -> "...dan " ++ show (count - 2) ++ " selebihnya." ++ "\n" ++ replicate 58 '='
    showItemFunc count (item : rest) =
        "ID: " ++ show (itemId item)
            ++ "\nNama: "
            ++ itemName item
            ++ "\nSisa jumlah: "
            ++ show (storage item)
            ++ "\nDeskrispsi barang: "
            ++ description item
            ++ "\n"
            ++ replicate 29 '-'
            ++ "\n"
            ++ showItemFunc count rest

showAllItem :: [LogItem] -> String
showAllItem [] = replicate 90 '='
showAllItem (item : rest) =
    "ID: " ++ show (itemId item)
        ++ "\nNama Barang: "
        ++ itemName item
        ++ "\nJumlah Barang: "
        ++ show (storage item)
        ++ "\nDeskripsi Barang: "
        ++ description item
        ++ "\n"
        ++ replicate 90 '-'
        ++ "\n"
        ++ showAllItem rest

main :: IO ()
main = do
    items <- fmap parseItem (readFile "log/items.log")
    runProgram items []