{-# LANGUAGE NoImplicitPrelude #-}

module Course.Applicative(
  Applicative(..)
, sequence
, replicateA
, filtering
) where

import Course.Core
import Course.Apply
import Course.Id
import Course.List
import Course.Optional
import qualified Prelude as P

class Apply f => Applicative f where
  pure ::
    a -> f a

-- | Witness that all things with (<*>) and pure also have (<$>).
--
-- >>> (+1) <$> (Id 2)
-- Id 3
--
-- >>> (+1) <$> Nil
-- []
--
-- >>> (+1) <$> (1 :. 2 :. 3 :. Nil)
-- [2,3,4]
(<$>) ::
  Applicative f =>
  (a -> b)
  -> f a
  -> f b
(<$>) f a = (pure f) <*> a
  

-- | Insert into the Id monad.
--
-- prop> pure x == Id x
instance Applicative Id where
  pure = Id


-- | Insert into a List.
--
-- prop> pure x == x :. Nil
instance Applicative List where
  pure x = x :. Nil
--  pure = flip (:.) Nil
--  pure = (:.) Nil


-- | Insert into an Optional.
--
-- prop> pure x == Full x
instance Applicative Optional where
  pure = Full


-- | Insert into a constant function.
--
-- prop> pure x y == x
instance Applicative ((->) t) where
  pure = const
--  pure x _ = x


-- | Sequences a list of structures to a structure of list.
--
-- >>> sequence (Id 7 :. Id 8 :. Id 9 :. Nil)
-- Id [7,8,9]
--
-- >>> sequence ((1 :. 2 :. 3 :. Nil) :. (1 :. 2 :. Nil) :. Nil)
-- [[1,1],[1,2],[2,1],[2,2],[3,1],[3,2]]
--
-- >>> sequence (Full 7 :. Empty :. Nil)
-- Empty
--
-- >>> sequence (Full 7 :. Full 8 :. Nil)
-- Full [7,8]
--
-- >>> sequence ((*10) :. (+2) :. Nil) 6
-- [60,8]
sequence ::
  Applicative f =>
  List (f a)
  -> f (List a)

{-
  Applicative f => (a -> b) -> f a -> f b
-}

sequence = foldRight (lift2 (:.)) (pure Nil)


-- | Replicate an effect a given number of times.
--
-- >>> replicateA 4 (Id "hi")
-- Id ["hi","hi","hi","hi"]
--
-- >>> replicateA 4 (Full "hi")
-- Full ["hi","hi","hi","hi"]
--
-- >>> replicateA 4 Empty
-- Empty
--
-- >>> replicateA 4 (*2) 5
-- [10,10,10,10]
replicateA ::
  Applicative f =>
  Int
  -> f a
  -> f (List a)
replicateA n x = sequence (replicate n x)


-- | Filter a list with a predicate that produces an effect.
--
-- >>> filtering (Id . even) (4 :. 5 :. 6 :. Nil)
-- Id [4,6]
--
-- >>> filtering (\a -> if a > 13 then Empty else Full (a <= 7)) (4 :. 5 :. 6 :. Nil)
-- Full [4,5,6]
--
-- >>> filtering (\a -> if a > 13 then Empty else Full (a <= 7)) (4 :. 5 :. 6 :. 7 :. 8 :. 9 :. Nil)
-- Full [4,5,6,7]
--
-- >>> filtering (\a -> if a > 13 then Empty else Full (a <= 7)) (4 :. 5 :. 6 :. 13 :. 14 :. Nil)
-- Empty
--
-- >>> filtering (>) (4 :. 5 :. 6 :. 7 :. 8 :. 9 :. 10 :. 11 :. 12 :. Nil) 8
-- [9,10,11,12]
filtering ::
  Applicative f =>
  (a -> f Bool)
  -> List a
  -> f (List a)
--filtering a = lift2 (filter a)
--filtering _ Nil = pure Nil
--filtering a b c = filter (lift2 b) a c
--filtering a b c = foldRight (filter <* a) (pure Nil) b

filtering _ Nil = pure Nil
filtering p (h:.t) =
	lift2 (if' (h :.) id) (p h) (filtering p t)

filtering' p = foldRight (\h -> lift2 (if' id ((:.) h)) (p h)) (pure Nil)


if' ::
	x
	-> x
	-> Bool
	-> x
if' f t p = if p then f else t

data Hole = Hole

-----------------------
-- SUPPORT LIBRARIES --
-----------------------

instance Applicative IO where
  pure =
    P.return

instance Applicative [] where
  pure =
    P.return

instance Applicative P.Maybe where
  pure =
    P.return
