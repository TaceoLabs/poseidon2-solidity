// SPDX-License-Identifier: MIT
pragma solidity >=0.8.8;

import {Test} from "forge-std/Test.sol";
import {Poseidon2T3_BN254} from "../src/Poseidon2T3_BN254.sol";

// Known-Answer-Tests (KATs) for the Poseidon2 permutation over BN254, state size 3.
// Reference vectors: https://github.com/TaceoLabs/noir-poseidon/blob/main/poseidon2/src/bn254/permutation.nr
contract Poseidon2T3_BN254_KAT_Test is Test {
    uint256 constant PRIME = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    function _check(uint256[3] memory input, uint256[3] memory expected) internal pure {
        uint256[3] memory got = Poseidon2T3_BN254.permutation(input);
        assertEq(got[0], expected[0]);
        assertEq(got[1], expected[1]);
        assertEq(got[2], expected[2]);
    }

    function _checkCompress(uint256[3] memory input, uint256 expected) internal pure {
        uint256 got = Poseidon2T3_BN254.compress(input);
        assertEq(got, expected);
    }

    function test_permutation_matches_kats() public pure {
        _check(
            [uint256(0), 1, 2],
            [
                0x0bb61d24daca55eebcb1929a82650f328134334da98ea4f847f760054f4a3033,
                0x303b6f7c86d043bfcbcc80214f26a30277a15d3f74ca654992defe7ff8d03570,
                0x1ed25194542b12eef8617361c3ba7c52e660b145994427cc86296242cf766ec8
            ]
        );
        _check(
            [
                0x2c6422c33190d036a17bd4281738ad60a6b4544c1020da1c0c84880a0ddc71c4,
                0x245cd98e5af9a6ebb35945b092c7e877ab9549c8919940250956a0bfedb457ab,
                0x0b43c424171231016dfe2072518b825a18c759383dba4e09a47bcd8b1a55da21
            ],
            [
                0x0b6f503d74ca8c80934b48d8d9e41c239ea6bcee17f658d416a0b72fd7daf1b8,
                0x2845997bb81ad9d29f0b7ba57550cb7160b6930c70c92287207c7b5f65b2814b,
                0x0a97e625f336a7c5e51bb2881e3b4e224f6e2e01ae5d698fa19446dbc407ac3f
            ]
        );
        _check(
            [
                0x124ce2326b4a95fe09743697c1e5c9ac9f6940cab7221decfd0162a8873c63ea,
                0x167148c1014f9f1ae03bb93892ec0164c6f65f779b526c3499d7ac374e84af86,
                0x18c0badc1c5aa472c434c254786f8e1aa8b519a7ec017dfd20bc1e5dfb820caa
            ],
            [
                0x2791fa7cca97f87cc3de6ce004bccf28e3cb631e4fd31d50b38fc79b7e43dbbf,
                0x22e42774e15a97e78d378b0225379ecbcb76060beef46e10e4b630bbd256003b,
                0x2e56288af3d63be34692074d7db4ce2f9eda91f7a55ba60d7661d8c2bfca9580
            ]
        );
        _check(
            [
                0x034f5155557b5e85db4fba5c254882f8658baa03376a38d37ff03fef1f850cfd,
                0x23975b943c4070c2bc98ec66b4a9e1f0ca1c812b38317bdbfac98aa748b5b059,
                0x03f9ef0d827a433a679060b654b556daa963c9658f628a3522dee7e839ab3615
            ],
            [
                0x0014a5e7728d210b90ef439df76561371be410051332852cea084ef73271ccbd,
                0x05c0808fa8657cb6091ee49fd5a0b32de2affeab6bed761043044982b3d7e3f5,
                0x2f6cc98fa05d79737a559115be171d2863e65080353c281b2104bb17b01f9c49
            ]
        );
        _check(
            [
                0x184561698ba999c39dcd5effd2f073e95345fb74f023ba25e162995a206ba79e,
                0x294e74e9b2f87eb7f5e00a350a22ff02e22397c278d48cecae04a4a83085a9ce,
                0x2840b008f9dd0379037622060b97bbe9fb5ffcf3e765c0a7feb5be13405ad2d8
            ],
            [
                0x13b47f0963b7751e01c8ff9775b02df2b185d8a968edfded67d518fe00a13104,
                0x287fc57d4458c6853c98a361b93fbfa6176e346bd75bbb11773b00356d496b6c,
                0x200f5d2604826c715b6b0b731a5365d9bc24cba1fbeec033e3e0a434a6505251
            ]
        );
        _check(
            [
                0x1c3c047ca883688ca6b6ddec715eef99a40282a4dc1d1b33910f59f30074e8f4,
                0x0a3aed04e3acb73a0f74d42f0d304f1afeefc00859a77d956120638d9007fbc5,
                0x07d9e5a9a2ac225871d7616f13a7a0185731fa679d931762ce1ef7767a3e63df
            ],
            [
                0x0df5bd217aa8e906435455b0151adae8dccb5f1fef23c0bd36a15f78f7b90ea7,
                0x2f6ae610ef9f92d6bce4540aaecfd2f0e93bad0671f544f0c16bd8546de44928,
                0x1b74956ba343323130615d776a667187f72ade7bc295c7750551170721f5253f
            ]
        );
        _check(
            [
                0x1e7cb866b31dc33c91585591e7c82530ef2a25c3feef3273b1c4fc382790ab2b,
                0x2781a330739b20aff560c61207ac9a3dd0f74b78dd9d4ec97a3db650c4d05ae6,
                0x275dc90993858ee8bcee5a94d1010f30c9731a49eb799e3aa0dfe94c73d1d28a
            ],
            [
                0x1c8317bbb73ba936b89bb337d1a91a48639602b721e0400e0b9d5799f64c3dd7,
                0x1a4887a3b86e801f5602aabf3d247a4fd508ecf6eb5d1e54d53eaeef7235b123,
                0x1a1298a0b4d732d42c85649ac7167073350be052dedbc334d05cdbb2e636b72c
            ]
        );
        _check(
            [
                0x276d519f50629d7ab7b0362da8e532da858c989c37765d77e56d570ef67037d1,
                0x2b7cd64f3fdb10e2006a924c051cd3ea53dfa82e75993bad8d0eb4ca8f3756b4,
                0x07dc1f509cb68ec98ce1c9d18a89fa75a28a300ea58769a5fdc5ae19b4459c24
            ],
            [
                0x2ad18eae7534d3d0efe05e897a4daebc441027e39256c1b647350f4a1969ed22,
                0x089f6c4f52414101923991f94065e403aa9ddb7af3381c74b595650460d883ef,
                0x1cfdc65275dc88f45a862bb5618c586c52a548a7ad33fa6240cb06cc79988278
            ]
        );
        _check(
            [
                0x0c6c15f4368f09bdaa7e7f4bc63d65d597eafe75764d82cb4d774e1982fce517,
                0x2e250d17689425c849b6d94bf822783c14086e5b5a145f6bd67d61d227e5dfa5,
                0x18693f449496390c0d6daa3f03170629b987b27c832c9e2aa586e3e36c6eac8e
            ],
            [
                0x0d35a94d34a9fe5527a72ddb2a6654bfde040cb5ed436944146971939790429b,
                0x0bf853441574d5367ebfb250538322e16bda7cd1ed8097a7924f937c3bdb6807,
                0x1e9ece2f587bdcc047d4f18419934d2d53f5e1aeef8ae5ac7a66bea8eea657b2
            ]
        );
        _check(
            [
                0x2fb3cd143630e3dd1a1eda75a9e8e698ee7a3a877ec6ecd7a77de97a1e0b6657,
                0x0c525ee6e5674c991dd70bd04a00bc62119d0ae97a1f1ec89cbdd34ac139edb4,
                0x2b6d256970b78cda94586db4eb7db119b10ee087b9ba107afe8c64e7b34625b1
            ],
            [
                0x131f70df273c7fe22667903a3aaeecfd8a873067c836159ffeb6b7e9f9ff347c,
                0x2c3734764e1decc2f5edef11beeaa1e7319594a4fdd850ac34370fe616f07fc8,
                0x06aaada4c2611fd916e1e0e7c31625e60d3e0b3ff972de980a3327350896ba2a
            ]
        );
        // Regression: [310, 311, 312] drives the state entering External round 4 (right
        // after the internal linear layer) past 5*PRIME, which overflows uint256 under the
        // unchecked `+=` this library used to use for round constants there.
        _check(
            [uint256(310), 311, 312],
            [
                0x1ad53986365bb9d45d44edda36bf86d05f3595b32aa4b3a27068d7def79b6cf1,
                0x09bddde0c03106bf48fb89b85b2af0aec60f6ed71d2eec68a4c8813cdb501c6a,
                0x1f031e63f0924ede1d8a68515456bfd99c90a4a6ce94bd08c171b12d1d83d629
            ]
        );
    }

    function test_compress_matches_kats() public pure {
        _checkCompress(
            [
                uint256(898806166821139162552132088403958488384503106165081617184346559456501738999),
                5965168078856614482694323653344381108309427800607037671123008596071823952253,
                276435419372390923140774542356582007830246927446975692596430793358221695016
            ],
            1113727409077897104878085522198678951849017209223827130117214728715352275349
        );
        _checkCompress(
            [
                uint256(12710238119547309612863709727473716702972319496509605773733619420762152019579),
                14135801400893409576315774471147878949081073261637979192128159187083529907135,
                21337135158674327236728592405871036705875634814572747351511340337045940525968
            ],
            20691891632189950624583506135333870795662584312510730531504404514774015659334
        );
        _checkCompress(
            [
                uint256(16339428823292574804745935930070783199652394243525987959414222240816866408325),
                7109187480894965133618624585668630960197300833042347356011804664553636235319,
                14583971128928339471517567553021449586027080470182053147253572849812962828241
            ],
            19793572575808393672662618160424563934042576953735616030088478545794518623490
        );
        _checkCompress(
            [
                uint256(21646811676817898132510494584649901702499441291448897826058837398383594384719),
                11361313256799398903048865465307455043351175008483980425272374037791420407346,
                13998436862115569580955940465290635313275821204715300401304838496822242916692
            ],
            8072803621730610593007307422927976476450257808651058569650007704098476548772
        );
        _checkCompress(
            [
                uint256(2974874314227548584172094818610285496235929311124719685091766960350012035322),
                1202439950413388189233301382973536667372317980260133733541574701087100096365,
                3178122023618696639505749272555686182718501295432799105127543713502713128801
            ],
            7293332937728812397772964433169904230520095333048113715740753242658476932953
        );
        _checkCompress(
            [
                uint256(20202370782719704569359011554556325814475397758375888237065138694016752030457),
                153264606504159944176939057613169404299141083627800492954834131022902673417,
                12789145694519103676963340173084370724312490663414549810164040076333019456583
            ],
            3362486580229522538799277556040482765961061030537107867002343455729603987462
        );
        _checkCompress(
            [
                uint256(20399969695300505324417844362714831676779095579913345823030293208258230169492),
                6974962387165250366974035317381980075449880846539719269322291173945170102495,
                3320761290816655513321038096835025719111788123828452838561804937325958488354
            ],
            4429807201098186459977909657182727103923090686011124338961112485675761048245
        );
        _checkCompress(
            [
                uint256(9959590937169867230828283363686813660545727352338018289514714696251758863494),
                9836017942942987572447314695871056999759412254272627610142095155699243079751,
                13591457579615877440569403476715590137572026777059601900630763849498373911409
            ],
            1973517536769231210338068806783539887658357765370473403831946003426814882419
        );
        _checkCompress(
            [
                uint256(13805514442279361935476660246206551185163839551731816843535991440823474938017),
                9477673091236985984033372016417728123029934660402488223373326947470787569620,
                3076171464720111369841843215271980970600465337897492289163425248125402438140
            ],
            8210845798978049518938877136885309163559676259266066517097061866167219232600
        );
        _checkCompress(
            [
                uint256(14162058550201621825776702370852711800617951426395475677190421424242021422478),
                1095675247981304679343439500107479468854926740507895759981147339224963674871,
                6738737067045032723828630739841085012781991901332047405189382728229463894667
            ],
            5787001487355732923639148997484489819089051873100263591351379770645205057736
        );
    }

    function test_compress_reverts_when_input_not_in_field() public {
        vm.expectRevert(Poseidon2T3_BN254.NotInPrimefield.selector);
        Poseidon2T3_BN254.compress([PRIME, uint256(0), uint256(0)]);

        vm.expectRevert(Poseidon2T3_BN254.NotInPrimefield.selector);
        Poseidon2T3_BN254.compress([uint256(0), PRIME, uint256(0)]);

        vm.expectRevert(Poseidon2T3_BN254.NotInPrimefield.selector);
        Poseidon2T3_BN254.compress([uint256(0), uint256(0), PRIME]);

        // Boundary: PRIME - 1 is in-field and must not revert.
        Poseidon2T3_BN254.compress([PRIME - 1, PRIME - 1, PRIME - 1]);
    }

    function test_permutation_reverts_when_input_not_in_field() public {
        vm.expectRevert(Poseidon2T3_BN254.NotInPrimefield.selector);
        Poseidon2T3_BN254.permutation([PRIME, uint256(0), uint256(0)]);

        vm.expectRevert(Poseidon2T3_BN254.NotInPrimefield.selector);
        Poseidon2T3_BN254.permutation([uint256(0), PRIME, uint256(0)]);

        vm.expectRevert(Poseidon2T3_BN254.NotInPrimefield.selector);
        Poseidon2T3_BN254.permutation([uint256(0), uint256(0), PRIME]);

        // Boundary: PRIME - 1 is in-field and must not revert.
        Poseidon2T3_BN254.permutation([PRIME - 1, PRIME - 1, PRIME - 1]);
    }

    function test_unchecked_variants_match_kats() public pure {
        uint256[3] memory input1 = [
            uint256(898806166821139162552132088403958488384503106165081617184346559456501738999),
            5965168078856614482694323653344381108309427800607037671123008596071823952253,
            276435419372390923140774542356582007830246927446975692596430793358221695016
        ];
        assertEq(
            Poseidon2T3_BN254.compressUnchecked(input1),
            1113727409077897104878085522198678951849017209223827130117214728715352275349
        );

        uint256[3] memory permInput = [uint256(0), 1, 2];
        uint256[3] memory permGot = Poseidon2T3_BN254.permutationUnchecked(permInput);
        assertEq(permGot[0], 0x0bb61d24daca55eebcb1929a82650f328134334da98ea4f847f760054f4a3033);
        assertEq(permGot[1], 0x303b6f7c86d043bfcbcc80214f26a30277a15d3f74ca654992defe7ff8d03570);
        assertEq(permGot[2], 0x1ed25194542b12eef8617361c3ba7c52e660b145994427cc86296242cf766ec8);
    }
}
