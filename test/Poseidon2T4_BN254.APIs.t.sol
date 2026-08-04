// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import {Test} from "forge-std/Test.sol";
import {Poseidon2T4_BN254} from "../src/Poseidon2T4_BN254.sol";

contract T4MinimalExternalConsumer {
    function compress(uint256[4] calldata x) external pure returns (uint256) {
        return Poseidon2T4_BN254.compress(x);
    }
}

contract T4MinimalInlineConsumer {
    function compress(uint256 a, uint256 b, uint256 c, uint256 d) external pure returns (uint256) {
        return Poseidon2T4_BN254.compress(a, b, c, d);
    }
}

contract T4ExternalConsumer {
    function compress(uint256[4] calldata x) external pure returns (uint256) {
        return Poseidon2T4_BN254.compress(x);
    }

    function compressUnchecked(uint256[4] calldata x) external pure returns (uint256) {
        return Poseidon2T4_BN254.compressUnchecked(x);
    }

    function permutation(uint256[4] calldata x) external pure returns (uint256[4] memory) {
        return Poseidon2T4_BN254.permutation(x);
    }

    function chain(uint256[4] calldata x, uint256 count) external pure returns (uint256 acc) {
        uint256[4] memory state = x;
        for (uint256 i; i < count; ++i) {
            acc = Poseidon2T4_BN254.compress(state);
            state[0] = acc;
        }
    }
}

contract T4InlineConsumer {
    function compress(uint256 a, uint256 b, uint256 c, uint256 d) external pure returns (uint256) {
        return Poseidon2T4_BN254.compress(a, b, c, d);
    }

    function compressUnchecked(uint256 a, uint256 b, uint256 c, uint256 d) external pure returns (uint256) {
        return Poseidon2T4_BN254.compressUnchecked(a, b, c, d);
    }

    function permutation(uint256 a, uint256 b, uint256 c, uint256 d) external pure returns (uint256[4] memory) {
        return Poseidon2T4_BN254.permutation(a, b, c, d);
    }
}

contract Poseidon2T4APITest is Test {
    uint256 constant P = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    T4ExternalConsumer externalConsumer;
    T4InlineConsumer inlineConsumer;

    function setUp() public {
        externalConsumer = new T4ExternalConsumer();
        inlineConsumer = new T4InlineConsumer();
    }

    function testFuzz_allAPIsAgree(uint256 a, uint256 b, uint256 c, uint256 d) public view {
        a %= P;
        b %= P;
        c %= P;
        d %= P;
        uint256[4] memory x = [a, b, c, d];
        uint256 checked = externalConsumer.compress(x);
        assertEq(checked, externalConsumer.compressUnchecked(x));
        assertEq(checked, inlineConsumer.compress(a, b, c, d));
        assertEq(checked, inlineConsumer.compressUnchecked(a, b, c, d));

        uint256[4] memory extPerm = externalConsumer.permutation(x);
        uint256[4] memory intPerm = inlineConsumer.permutation(a, b, c, d);
        for (uint256 i; i < 4; ++i) {
            assertEq(extPerm[i], intPerm[i]);
        }
        assertEq(checked, addmod(extPerm[0], a, P));
    }

    function test_internalCheckedRejectsEveryInvalidPosition() public {
        for (uint256 lane; lane < 4; ++lane) {
            uint256[4] memory x;
            x[lane] = P;
            vm.expectRevert(Poseidon2T4_BN254.NotInPrimefield.selector);
            inlineConsumer.compress(x[0], x[1], x[2], x[3]);
            vm.expectRevert(Poseidon2T4_BN254.NotInPrimefield.selector);
            inlineConsumer.permutation(x[0], x[1], x[2], x[3]);
        }
    }

    function test_gas_externalCheckedCompression() public view {
        externalConsumer.compress([uint256(1), 2, 3, 4]);
    }

    function test_gas_externalUncheckedCompression() public view {
        externalConsumer.compressUnchecked([uint256(1), 2, 3, 4]);
    }

    function test_gas_inlineCheckedCompression() public view {
        inlineConsumer.compress(1, 2, 3, 4);
    }

    function test_gas_externalPermutation() public view {
        externalConsumer.permutation([uint256(1), 2, 3, 4]);
    }

    function test_gas_externalChain10() public view {
        externalConsumer.chain([uint256(1), 2, 3, 4], 10);
    }
}
