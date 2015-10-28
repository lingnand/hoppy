-- This file is part of Hoppy.
--
-- Copyright 2015 Bryan Gardiner <bog@khumba.net>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License version 3
-- as published by the Free Software Foundation.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

{-# LANGUAGE CPP #-}

-- | Bindings for @std::set@.
module Foreign.Hoppy.Generator.Std.Set (
  Options (..),
  defaultOptions,
  Contents (..),
  instantiate,
  instantiate',
  toExports,
  ) where

#if !MIN_VERSION_base(4,8,0)
import Data.Monoid (mconcat)
#endif
import Foreign.Hoppy.Generator.Spec
import Foreign.Hoppy.Generator.Spec.ClassFeature (
  ClassFeature (Assignable, BidirectionalIterator, Comparable, Copyable),
  IteratorMutability (Constant),
  classAddFeatures,
  )

-- | Options for instantiating the set classes.
data Options = Options
  { optSetClassFeatures :: [ClassFeature]
    -- ^ Additional features to add to the @std::set@ class.  Sets are always
    -- 'Assignable', 'Comparable', and 'Copyable', but you may want to add
    -- 'Foreign.Hoppy.Generator.Spec.ClassFeature.Equatable' if your value type
    -- supports those.
  }

-- | The default options have no additional 'ClassFeature's.
defaultOptions :: Options
defaultOptions = Options []

-- | A set of instantiated set classes.
data Contents = Contents
  { c_set :: Class  -- ^ @std::set\<T>@
  , c_iterator :: Class  -- ^ @std::set\<T>::iterator@
  }

-- | @instantiate className t tReqs@ creates a set of bindings for an
-- instantiation of @std::set@ and associated types (e.g. iterators).  In the
-- result, the 'c_set' class has an external name of @className@, and the
-- iterator class is further suffixed with @\"Iterator\"@.
instantiate :: String -> Type -> Reqs -> Contents
instantiate setName t tReqs = instantiate' setName t tReqs defaultOptions

-- | 'instantiate' with additional options.
instantiate' :: String -> Type -> Reqs -> Options -> Contents
instantiate' setName t tReqs opts =
  let reqs = mconcat
             [ tReqs
             , reqInclude $ includeStd "hoppy/set.hpp"
             , reqInclude $ includeStd "set"
             ]
      iteratorName = setName ++ "Iterator"

      set =
        addUseReqs reqs $
        classAddFeatures (Assignable : Comparable : Copyable : optSetClassFeatures opts) $
        makeClass (ident1T "std" "set" [t]) (Just $ toExtName setName) []
        [ mkCtor "new" []
        ]
        [ mkMethod "begin" [] $ TObjToHeap iterator
        , mkMethod "clear" [] TVoid
        , mkConstMethod "count" [t] TSize
          -- TODO count
        , mkConstMethod "empty" [] TBool
        , mkMethod "end" [] $ TObjToHeap iterator
          -- equalRange: find is good enough.
        , mkMethod' "erase" "erase" [TObj iterator] TVoid
        , mkMethod' "erase" "eraseRange" [TObj iterator, TObj iterator] TVoid
        , mkMethod "find" [t] $ TObjToHeap iterator
        , makeFnMethod (ident2 "hoppy" "set" "insert") "insert"
          MNormal Nonpure [TRef $ TObj set, t] TBool
        , makeFnMethod (ident2 "hoppy" "set" "insertAndGetIterator") "insertAndGetIterator"
          MNormal Nonpure [TRef $ TObj set, t] $ TObjToHeap iterator
          -- lower_bound: find is good enough.
        , mkConstMethod' "max_size" "maxSize" [] TSize
        , mkConstMethod "size" [] TSize
        , mkMethod "swap" [TRef $ TObj set] TVoid
          -- upper_bound: find is good enough.
        ]

      -- Set iterators are always constant, because modifying elements in place
      -- will break the internal order of the set.
      iterator =
        addUseReqs reqs $
        classAddFeatures [BidirectionalIterator Constant $ Just t] $
        makeClass (identT' [("std", Nothing), ("set", Just [t]), ("iterator", Nothing)])
        (Just $ toExtName iteratorName) [] [] []

  in Contents
     { c_set = set
     , c_iterator = iterator
     }

-- | Converts an instantiation into a list of exports to be included in a
-- module.
toExports :: Contents -> [Export]
toExports m = map (ExportClass . ($ m)) [c_set, c_iterator]