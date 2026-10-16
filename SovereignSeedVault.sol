// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IVerifier {
    function verifyProof(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[1] calldata input
    ) external view returns (bool);
}

// Interface pour communiquer avec notre nouveau contrat de rendu
interface ISovereignSeedVaultRender {
    function generateURI(uint256 tokenId, bool isUnlocked) external pure returns (string memory);
}

contract SovereignSeedVault is ERC721 {
    struct Vault {
        bytes32 keccakTargetHash; 
        bool isUnlocked;          
    }

    IVerifier public immutable zkVerifier;
    ISovereignSeedVaultRender public renderContract; // Référence vers le render
    
    mapping(uint256 => Vault) public vaults;
    uint256 public tokenCounter;

    bytes32 public constant DEFAULT_TEST_HASH = 0x3663dc366f07a2a6b22557e03407e780775591c2d43a50bc10f545465bb6d7a4;

    constructor(address _verifierAddress, address _renderAddress) ERC721("Sovereign Seed Vault", "SSV") {
        zkVerifier = IVerifier(_verifierAddress);
        renderContract = ISovereignSeedVaultRender(_renderAddress);
    }

    // Permet de mettre à jour le design du NFT plus tard si besoin
    function setRenderContract(address _renderAddress) external {
        // Optionnel : ajouter une restriction onlyOwner ici si vous importez Ownable
        renderContract = ISovereignSeedVaultRender(_renderAddress);
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
        Vault storage vault = vaults[tokenId];
        require(!vault.isUnlocked, "Vault already unlocked");

        bool proofIsValid = zkVerifier.verifyProof(a, b, c, publicInputs);
        require(proofIsValid, "Invalid Zero-Knowledge Proof");

        vault.isUnlocked = true;
    }

    // Appel externe au contrat de rendu pour obtenir les métadonnées
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return renderContract.generateURI(tokenId, vaults[tokenId].isUnlocked);
    }
}

