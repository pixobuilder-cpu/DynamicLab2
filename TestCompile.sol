// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IVerifier {
    function verifyProof(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[1] calldata input
    ) external view returns (bool);
}

contract SovereignSeedVault is ERC721 {
    using Strings for uint256;

    struct Vault {
        bytes32 keccakTargetHash; 
        bool isUnlocked;          
    }

    IVerifier public immutable zkVerifier;
    mapping(uint256 => Vault) public vaults;
    uint256 public tokenCounter;

    bytes32 public constant DEFAULT_TEST_HASH = 0x3663dc366f07a2a6b22557e03407e780775591c2d43a50bc10f545465bb6d7a4;

    constructor(address _verifierAddress) ERC721("Sovereign Seed Vault", "SSV") {
        require(_verifierAddress != address(0), "Invalid verifier address");
        zkVerifier = IVerifier(_verifierAddress);
    }

    function mintDefaultVault() external {
        uint256 tokenId = tokenCounter++;
        _safeMint(msg.sender, tokenId);

        vaults[tokenId] = Vault({
            keccakTargetHash: DEFAULT_TEST_HASH,
            isUnlocked: false
        });
    }

    function unlockVaultWithZK(
        uint256 tokenId,
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[1] calldata publicInputs
    ) external {
        // Correction de sécurité implicite : On s'assure d'abord que le token existe
        _requireOwned(tokenId); 

        Vault storage vault = vaults[tokenId];
        require(!vault.isUnlocked, "Vault already unlocked");

        bool proofIsValid = zkVerifier.verifyProof(a, b, c, publicInputs);
        require(proofIsValid, "Invalid Zero-Knowledge Proof");

        vault.isUnlocked = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // En v5, _requireOwned lève un revert automatique si le token n'existe pas
        _requireOwned(tokenId); 
        
        Vault memory vault = vaults[tokenId];

        string memory statusColor = vault.isUnlocked ? "#00ffcc" : "#c3a372";
        string memory statusText = vault.isUnlocked ? "UNLOCKED" : "SECURED (ZK)";

        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://w3.org" viewBox="0 0 800 800" width="100%" height="100%">',
            '<defs>',
            '<radialGradient id="woodBg" cx="50%" cy="50%" r="70%"><stop offset="0%" stop-color="#4a3120"/><stop offset="100%" stop-color="#180e07"/></radialGradient>',
            '<linearGradient id="seedBase" x1="20%" y1="10%" x2="80%" y2="90%"><stop offset="0%" stop-color="#f5e6be"/><stop offset="100%" stop-color="', statusColor, '"/></linearGradient>',
            '</defs>',
            '<rect width="100%" height="100%" fill="url(#woodBg)"/>',
            '<g transform="translate(400, 430) rotate(-6)">',
            '<path d="M -125,5 C -130,-40 -65,-80 5,-72 C 60,-65 105,-38 132,-12 C 140,-3 140,3 132,10 C 105,32 55,65 -5,65 C -70,65 -115,38 -125,5 Z" fill="url(#seedBase)"/>',
            '</g>',
            '<text x="40" y="60" fill="', statusColor, '" font-family="monospace" font-size="22">SSV STATUS: ', statusText, '</text>',
            '</svg>'
        ));

        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Sovereign Seed Vault #', tokenId.toString(), 
            '", "description": "Vault anchored with Keccak-256 target hash and protected by ZK-SNARKs.", "image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(svg)), '"}'
        ))));

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
