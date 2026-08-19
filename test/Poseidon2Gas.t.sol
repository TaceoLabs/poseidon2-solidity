// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import {Test} from "forge-std/Test.sol";
import {Poseidon2T2_BN254} from "../src/Poseidon2T2_BN254.sol";
import {Poseidon2T3_BN254} from "../src/Poseidon2T3_BN254.sol";
import {Poseidon2T4_BN254} from "../src/Poseidon2T4_BN254.sol";

// Run with:
// forge test --match-path test/Poseidon2Gas.t.sol --gas-report

contract T2LinkedGasHarness {
    function compress(uint256[2] calldata input) external pure returns (uint256) {
        return Poseidon2T2_BN254.compress(input);
    }

    function compressUnchecked(uint256[2] calldata input) external pure returns (uint256) {
        return Poseidon2T2_BN254.compressUnchecked(input);
    }

    function permutation(uint256[2] calldata input) external pure returns (uint256[2] memory) {
        return Poseidon2T2_BN254.permutation(input);
    }

    function permutationUnchecked(uint256[2] calldata input) external pure returns (uint256[2] memory) {
        return Poseidon2T2_BN254.permutationUnchecked(input);
    }

    function chain10(uint256[2] calldata input) external pure returns (uint256 acc) {
        uint256[2] memory state = input;
        for (uint256 i; i < 10; ++i) {
            acc = Poseidon2T2_BN254.compress(state);
            state[0] = acc;
        }
    }
}

contract T2InlineGasHarness {
    function compress(uint256 a, uint256 b) external pure returns (uint256) {
        return Poseidon2T2_BN254.compress(a, b);
    }

    function compressUnchecked(uint256 a, uint256 b) external pure returns (uint256) {
        return Poseidon2T2_BN254.compressUnchecked(a, b);
    }

    function permutation(uint256 a, uint256 b) external pure returns (uint256[2] memory) {
        return Poseidon2T2_BN254.permutation(a, b);
    }

    function permutationUnchecked(uint256 a, uint256 b) external pure returns (uint256[2] memory) {
        return Poseidon2T2_BN254.permutationUnchecked(a, b);
    }

    function chain10(uint256 a, uint256 b) external pure returns (uint256 acc) {
        for (uint256 i; i < 10; ++i) {
            acc = Poseidon2T2_BN254.compress(a, b);
            a = acc;
        }
    }
}

contract T3LinkedGasHarness {
    function compress(uint256[3] calldata input) external pure returns (uint256) {
        return Poseidon2T3_BN254.compress(input);
    }

    function compressUnchecked(uint256[3] calldata input) external pure returns (uint256) {
        return Poseidon2T3_BN254.compressUnchecked(input);
    }

    function permutation(uint256[3] calldata input) external pure returns (uint256[3] memory) {
        return Poseidon2T3_BN254.permutation(input);
    }

    function permutationUnchecked(uint256[3] calldata input) external pure returns (uint256[3] memory) {
        return Poseidon2T3_BN254.permutationUnchecked(input);
    }

    function chain10(uint256[3] calldata input) external pure returns (uint256 acc) {
        uint256[3] memory state = input;
        for (uint256 i; i < 10; ++i) {
            acc = Poseidon2T3_BN254.compress(state);
            state[0] = acc;
        }
    }
}

contract T3InlineGasHarness {
    function compress(uint256 a, uint256 b, uint256 c) external pure returns (uint256) {
        return Poseidon2T3_BN254.compress(a, b, c);
    }

    function compressUnchecked(uint256 a, uint256 b, uint256 c) external pure returns (uint256) {
        return Poseidon2T3_BN254.compressUnchecked(a, b, c);
    }

    function permutation(uint256 a, uint256 b, uint256 c) external pure returns (uint256[3] memory) {
        return Poseidon2T3_BN254.permutation(a, b, c);
    }

    function permutationUnchecked(uint256 a, uint256 b, uint256 c) external pure returns (uint256[3] memory) {
        return Poseidon2T3_BN254.permutationUnchecked(a, b, c);
    }

    function chain10(uint256 a, uint256 b, uint256 c) external pure returns (uint256 acc) {
        for (uint256 i; i < 10; ++i) {
            acc = Poseidon2T3_BN254.compress(a, b, c);
            a = acc;
        }
    }
}

contract T4LinkedGasHarness {
    function compress(uint256[4] calldata input) external pure returns (uint256) {
        return Poseidon2T4_BN254.compress(input);
    }

    function compressUnchecked(uint256[4] calldata input) external pure returns (uint256) {
        return Poseidon2T4_BN254.compressUnchecked(input);
    }

    function permutation(uint256[4] calldata input) external pure returns (uint256[4] memory) {
        return Poseidon2T4_BN254.permutation(input);
    }

    function permutationUnchecked(uint256[4] calldata input) external pure returns (uint256[4] memory) {
        return Poseidon2T4_BN254.permutationUnchecked(input);
    }

    function chain10(uint256[4] calldata input) external pure returns (uint256 acc) {
        uint256[4] memory state = input;
        for (uint256 i; i < 10; ++i) {
            acc = Poseidon2T4_BN254.compress(state);
            state[0] = acc;
        }
    }
}

contract T4InlineGasHarness {
    function compress(uint256 a, uint256 b, uint256 c, uint256 d) external pure returns (uint256) {
        return Poseidon2T4_BN254.compress(a, b, c, d);
    }

    function compressUnchecked(uint256 a, uint256 b, uint256 c, uint256 d) external pure returns (uint256) {
        return Poseidon2T4_BN254.compressUnchecked(a, b, c, d);
    }

    function permutation(uint256 a, uint256 b, uint256 c, uint256 d) external pure returns (uint256[4] memory) {
        return Poseidon2T4_BN254.permutation(a, b, c, d);
    }

    function permutationUnchecked(uint256 a, uint256 b, uint256 c, uint256 d)
        external
        pure
        returns (uint256[4] memory)
    {
        return Poseidon2T4_BN254.permutationUnchecked(a, b, c, d);
    }

    function chain10(uint256 a, uint256 b, uint256 c, uint256 d) external pure returns (uint256 acc) {
        for (uint256 i; i < 10; ++i) {
            acc = Poseidon2T4_BN254.compress(a, b, c, d);
            a = acc;
        }
    }
}

contract Poseidon2GasTest is Test {
    T2LinkedGasHarness internal t2Linked;
    T2InlineGasHarness internal t2Inline;
    T3LinkedGasHarness internal t3Linked;
    T3InlineGasHarness internal t3Inline;
    T4LinkedGasHarness internal t4Linked;
    T4InlineGasHarness internal t4Inline;

    function setUp() public {
        t2Linked = new T2LinkedGasHarness();
        t2Inline = new T2InlineGasHarness();
        t3Linked = new T3LinkedGasHarness();
        t3Inline = new T3InlineGasHarness();
        t4Linked = new T4LinkedGasHarness();
        t4Inline = new T4InlineGasHarness();
    }

    function test_gas_T2() public view {
        uint256[2] memory input = [uint256(1), 2];

        uint256 checked = t2Linked.compress(input);
        assertEq(checked, t2Linked.compressUnchecked(input));
        assertEq(checked, t2Inline.compress(input[0], input[1]));
        assertEq(checked, t2Inline.compressUnchecked(input[0], input[1]));

        uint256[2] memory permutation = t2Linked.permutation(input);
        uint256[2] memory linkedUnchecked = t2Linked.permutationUnchecked(input);
        uint256[2] memory inlineChecked = t2Inline.permutation(input[0], input[1]);
        uint256[2] memory inlineUnchecked = t2Inline.permutationUnchecked(input[0], input[1]);
        for (uint256 i; i < 2; ++i) {
            assertEq(permutation[i], linkedUnchecked[i]);
            assertEq(permutation[i], inlineChecked[i]);
            assertEq(permutation[i], inlineUnchecked[i]);
        }

        assertEq(t2Linked.chain10(input), t2Inline.chain10(input[0], input[1]));
    }

    function test_gas_T3() public view {
        uint256[3] memory input = [uint256(1), 2, 3];

        uint256 checked = t3Linked.compress(input);
        assertEq(checked, t3Linked.compressUnchecked(input));
        assertEq(checked, t3Inline.compress(input[0], input[1], input[2]));
        assertEq(checked, t3Inline.compressUnchecked(input[0], input[1], input[2]));

        uint256[3] memory permutation = t3Linked.permutation(input);
        uint256[3] memory linkedUnchecked = t3Linked.permutationUnchecked(input);
        uint256[3] memory inlineChecked = t3Inline.permutation(input[0], input[1], input[2]);
        uint256[3] memory inlineUnchecked = t3Inline.permutationUnchecked(input[0], input[1], input[2]);
        for (uint256 i; i < 3; ++i) {
            assertEq(permutation[i], linkedUnchecked[i]);
            assertEq(permutation[i], inlineChecked[i]);
            assertEq(permutation[i], inlineUnchecked[i]);
        }

        assertEq(t3Linked.chain10(input), t3Inline.chain10(input[0], input[1], input[2]));
    }

    function test_gas_T4() public view {
        uint256[4] memory input = [uint256(1), 2, 3, 4];

        uint256 checked = t4Linked.compress(input);
        assertEq(checked, t4Linked.compressUnchecked(input));
        assertEq(checked, t4Inline.compress(input[0], input[1], input[2], input[3]));
        assertEq(checked, t4Inline.compressUnchecked(input[0], input[1], input[2], input[3]));

        uint256[4] memory permutation = t4Linked.permutation(input);
        uint256[4] memory linkedUnchecked = t4Linked.permutationUnchecked(input);
        uint256[4] memory inlineChecked = t4Inline.permutation(input[0], input[1], input[2], input[3]);
        uint256[4] memory inlineUnchecked = t4Inline.permutationUnchecked(input[0], input[1], input[2], input[3]);
        for (uint256 i; i < 4; ++i) {
            assertEq(permutation[i], linkedUnchecked[i]);
            assertEq(permutation[i], inlineChecked[i]);
            assertEq(permutation[i], inlineUnchecked[i]);
        }

        assertEq(t4Linked.chain10(input), t4Inline.chain10(input[0], input[1], input[2], input[3]));
    }
}
