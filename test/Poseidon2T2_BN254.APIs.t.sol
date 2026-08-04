// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import {Test} from "forge-std/Test.sol";
import {Poseidon2T2_BN254} from "../src/Poseidon2T2_BN254.sol";

contract T2MinimalExternalConsumer {
    function compress(uint256[2] calldata x) external pure returns (uint256) {
        return Poseidon2T2_BN254.compress(x);
    }
}

contract T2MinimalInlineConsumer {
    function compress(uint256 a, uint256 b) external pure returns (uint256) {
        return Poseidon2T2_BN254.compress(a, b);
    }
}

contract T2ExternalConsumer {
    function compress(uint256[2] calldata x) external pure returns (uint256) {
        return Poseidon2T2_BN254.compress(x);
    }

    function compressUnchecked(uint256[2] calldata x) external pure returns (uint256) {
        return Poseidon2T2_BN254.compressUnchecked(x);
    }

    function permutation(uint256[2] calldata x) external pure returns (uint256[2] memory) {
        return Poseidon2T2_BN254.permutation(x);
    }

    function chain(uint256[2] calldata x, uint256 count) external pure returns (uint256 acc) {
        uint256[2] memory state = x;
        for (uint256 i; i < count; ++i) {
            acc = Poseidon2T2_BN254.compress(state);
            state[0] = acc;
        }
    }
}

contract T2InlineConsumer {
    function compress(uint256 a, uint256 b) external pure returns (uint256) {
        return Poseidon2T2_BN254.compress(a, b);
    }

    function compressUnchecked(uint256 a, uint256 b) external pure returns (uint256) {
        return Poseidon2T2_BN254.compressUnchecked(a, b);
    }

    function permutation(uint256 a, uint256 b) external pure returns (uint256[2] memory) {
        return Poseidon2T2_BN254.permutation(a, b);
    }
}

contract Poseidon2T2APITest is Test {
    uint256 constant P = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    T2ExternalConsumer externalConsumer;
    T2InlineConsumer inlineConsumer;

    function setUp() public {
        externalConsumer = new T2ExternalConsumer();
        inlineConsumer = new T2InlineConsumer();
    }

    function testFuzz_allAPIsAgree(uint256 a, uint256 b) public view {
        a %= P;
        b %= P;
        uint256[2] memory x = [a, b];
        uint256 checked = externalConsumer.compress(x);
        assertEq(checked, externalConsumer.compressUnchecked(x));
        assertEq(checked, inlineConsumer.compress(a, b));
        assertEq(checked, inlineConsumer.compressUnchecked(a, b));

        uint256[2] memory extPerm = externalConsumer.permutation(x);
        uint256[2] memory intPerm = inlineConsumer.permutation(a, b);
        for (uint256 i; i < 2; ++i) {
            assertEq(extPerm[i], intPerm[i]);
        }
        assertEq(checked, addmod(extPerm[0], a, P));
    }

    function test_internalCheckedRejectsEveryInvalidPosition() public {
        for (uint256 lane; lane < 2; ++lane) {
            uint256[2] memory x;
            x[lane] = P;
            vm.expectRevert(Poseidon2T2_BN254.NotInPrimefield.selector);
            inlineConsumer.compress(x[0], x[1]);
            vm.expectRevert(Poseidon2T2_BN254.NotInPrimefield.selector);
            inlineConsumer.permutation(x[0], x[1]);
        }
    }

    function test_gas_externalCheckedCompression() public view {
        externalConsumer.compress([uint256(1), 2]);
    }

    function test_gas_externalUncheckedCompression() public view {
        externalConsumer.compressUnchecked([uint256(1), 2]);
    }

    function test_gas_inlineCheckedCompression() public view {
        inlineConsumer.compress(1, 2);
    }

    function test_gas_externalPermutation() public view {
        externalConsumer.permutation([uint256(1), 2]);
    }

    function test_gas_externalChain10() public view {
        externalConsumer.chain([uint256(1), 2], 10);
    }
}
