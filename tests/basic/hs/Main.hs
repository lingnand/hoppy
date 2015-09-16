{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Monad ((>=>), forM_, when)
import Foreign.C (CInt)
import Foreign.Cppop.Runtime.Support (decode, decodeAndDelete, delete, encode, encodeAs, withCppObj)
import Foreign.Cppop.Test.Basic
import Foreign.Cppop.Test.Basic.HsBox
import Test.HUnit (
  Assertion,
  Test (TestCase, TestList),
  (~:),
  (@?=),
  errors,
  failures,
  runTestTT,
  )
import System.Exit (exitFailure)

main :: IO ()
main = do
  counts <- runTestTT tests
  when (errors counts /= 0 || failures counts /= 0) exitFailure

assertBox :: CInt -> IntBox -> Assertion
assertBox value box = intBox_get box >>= (@?= value)

tests :: Test
tests =
  TestList
  [ functionTests
  , objectTests
  , conversionTests
  , objectPassingTests
  ]

functionTests :: Test
functionTests =
  "functions" ~: TestList
  [ "calling a pure function" ~: piapprox @?= 4
  , "calling a non-pure function" ~: piapproxNonpure >>= (@?= 4)
  , "passing an argument" ~: do
    timesTwo 5 @?= 10
    timesTwo (-12) @?= -24
  ]

objectTests :: Test
objectTests =
  "objects" ~: TestList
  [ "creates and deletes an object" ~: do
    box <- intBox_new
    assertBox 0 box
    delete box

  , "calls an overloaded constructor" ~: do
    box <- intBox_newWithValue (-1)
    assertBox (-1) box
    delete box
  ]


conversionTests :: Test
conversionTests =
  "object conversion" ~: TestList
  [ "encode" ~: do
    box <- encode $ HsBox 3 :: IO IntBox
    assertBox 3 box
    delete box

  , "encodeAs" ~: do
    box <- encodeAs (undefined :: IntBox) $ HsBox 4
    assertBox 4 box
    delete box

  , "decode" ~: do
    box <- intBox_newWithValue 5
    hsBox <- decode box
    delete box
    hsBox @?= HsBox 5

  , "withCppObj" ~: withCppObj (HsBox 6) $ assertBox 6
  ]

objectPassingTests :: Test
objectPassingTests =
  "passing objects" ~: TestList
  [ "passing to C++" ~: TestList
    [ "by value" ~: do
      withCppObj (HsBox 1) $ \(box :: IntBox) -> getBoxValueByValue box >>= (@?= 1)
      withCppObj (HsBox 2) $ \(box :: IntBoxConst) -> getBoxValueByValue box >>= (@?= 2)
    , "by reference" ~:
      withCppObj (HsBox 3) $ \(box :: IntBox) -> getBoxValueByRef box >>= (@?= 3)
      -- Passing a const pointer to a non-const reference is disallowed.
    , "by constant reference" ~: do
      withCppObj (HsBox 5) $ \(box :: IntBox) -> getBoxValueByRefConst box >>= (@?= 5)
      withCppObj (HsBox 6) $ \(box :: IntBoxConst) -> getBoxValueByRefConst box >>= (@?= 6)
    , "by pointer" ~:
      withCppObj (HsBox 7) $ \(box :: IntBox) -> getBoxValueByPtr box >>= (@?= 7)
      -- Passing a const pointer to a non-const pointer is disallowed.
    , "by constant pointer" ~: do
      withCppObj (HsBox 9) $ \(box :: IntBox) -> getBoxValueByPtrConst box >>= (@?= 9)
      withCppObj (HsBox 10) $ \(box :: IntBoxConst) -> getBoxValueByPtrConst box >>= (@?= 10)
    ]

  , "returning from C++" ~: TestList
    [ "by value" ~:
      (makeBoxByValue 1 :: IO HsBox) >>= (@?= HsBox 1)
    , "by reference" ~:
      (makeBoxByRef 2 :: IO IntBox) >>= decodeAndDelete >>= (@?= HsBox 2)
    , "by constant reference" ~:
      (makeBoxByRefConst 3 :: IO IntBoxConst) >>= decodeAndDelete >>= (@?= HsBox 3)
    , "by pointer" ~:
      (makeBoxByPtr 4 :: IO IntBox) >>= decodeAndDelete >>= (@?= HsBox 4)
    , "by constant pointer" ~:
      (makeBoxByPtrConst 5 :: IO IntBoxConst) >>= decodeAndDelete >>= (@?= HsBox 5)
    ]

  , "passing to Haskell callbacks" ~: TestList
    [ "by value" ~:
      getBoxValueByValueCallbackDriver (\(hsBox :: HsBox) -> return $ getHsBox hsBox) 1 >>= (@?= 1)
    , "by reference" ~:
      getBoxValueByRefCallbackDriver (\(box :: IntBox) -> intBox_get box) 2 >>= (@?= 2)
    , "by constant reference" ~:
      getBoxValueByRefConstCallbackDriver (\(box :: IntBoxConst) -> intBox_get box) 3 >>= (@?= 3)
    , "by pointer" ~:
      getBoxValueByPtrCallbackDriver (\(box :: IntBox) -> intBox_get box) 4 >>= (@?= 4)
    , "by constant pointer" ~:
      getBoxValueByPtrConstCallbackDriver (\(box :: IntBoxConst) -> intBox_get box) 5 >>= (@?= 5)
    ]

  , "returning from Haskell callbacks" ~: TestList
    [ "by value" ~:
      makeBoxByValueCallbackDriver (return . HsBox) 1 >>= (@?= 1)
    , "by reference" ~:
      makeBoxByRefCallbackDriver intBox_newWithValue 2 >>= (@?= 2)  -- We must go deeper.
    , "by constant reference" ~:
      makeBoxByRefConstCallbackDriver (fmap toIntBoxConst . intBox_newWithValue) 3 >>= (@?= 3)
    , "by pointer" ~:
      makeBoxByPtrCallbackDriver intBox_newWithValue 4 >>= (@?= 4)
    , "by constant pointer" ~:
      makeBoxByPtrConstCallbackDriver (fmap toIntBoxConst . intBox_newWithValue) 5 >>= (@?= 5)
    ]
  ]
