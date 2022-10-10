using Test
using ThreadPinning

@test ThreadPinning.interweave([1, 2, 3, 4], [5, 6, 7, 8]) ==
      [1, 5, 2, 6, 3, 7, 4, 8]
@test ThreadPinning.interweave(1:4, 5:8) == [1, 5, 2, 6, 3, 7, 4, 8]
@test ThreadPinning.interweave(1:4, 5:8, 9:12) ==
      [1, 5, 9, 2, 6, 10, 3, 7, 11, 4, 8, 12]
# different size inputs
@test_throws ArgumentError ThreadPinning.interweave([1, 2, 3, 4], [5, 6, 7, 8, 9])

@test ThreadPinning.interweave_uneven([1,2,3,4,5,6,7,8], [9,10,11,12]) == [1, 9, 2, 10, 3, 11, 4, 12, 5, 6, 7, 8]
@test ThreadPinning.interweave_uneven([1,2,3,4], [5,6,7,8,9,10,11,12]) == [1, 5, 2, 6, 3, 7, 4, 8, 9, 10, 11, 12]
