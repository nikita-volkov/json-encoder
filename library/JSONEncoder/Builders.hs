module JSONEncoder.Builders where

import JSONEncoder.Prelude hiding (length)
import ByteString.TreeBuilder
import qualified JSONEncoder.ByteStrings as ByteStrings
import qualified Data.Text


{-# INLINABLE intercalate #-}
intercalate :: Foldable f => Builder -> f Builder -> Builder
intercalate incut =
  foldl' (appendWithIncut incut) mempty

{-# INLINABLE appendWithIncut #-}
appendWithIncut :: Builder -> Builder -> Builder -> Builder
appendWithIncut incut a b =
  if length a == 0
    then b
    else if length b == 0
      then mempty
      else a <> incut <> b

{-# INLINE asciiChar #-}
asciiChar :: Char -> Builder
asciiChar =
  byte . fromIntegral . ord

{-# INLINE utf8Char #-}
utf8Char :: Char -> Builder
utf8Char =
  byteString . ByteStrings.utf8Char

{-# INLINABLE stringEncodedChar #-}
stringEncodedChar :: Char -> Builder
stringEncodedChar =
  \case
    '\"' -> "\\\""
    '\\' -> "\\\\"
    '\n' -> "\\n"
    '\r' -> "\\r"
    '\t' -> "\\t"
    char -> encodedChar char

{-# INLINABLE encodedChar #-}
encodedChar :: Char -> Builder
encodedChar char =
  if char < '\x20'
    then 
      let
        hex =
          fromString (showHex (fromEnum char) "")
        in "\\u" <> mconcat (replicate (4 - length hex) (asciiChar '0')) <> hex
    else
      utf8Char char

{-# INLINABLE stringLiteral #-}
stringLiteral :: Text -> Builder
stringLiteral string =
  asciiChar '"' <> encoded string <> asciiChar '"'
  where
    encoded =
      Data.Text.foldl' (\builder -> mappend builder . stringEncodedChar) mempty
