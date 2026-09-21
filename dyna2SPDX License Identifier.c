// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; 

import "@openzeppelin/contracts-upgradeable@4.9.3/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.9.3/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable@4.9.3/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.9.3/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts@4.9.3/utils/Base64.sol";
import "@openzeppelin/contracts@4.9.3/utils/Strings.sol";

contract DynamicLab2 is Initializable, ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    using Strings for uint256;

    enum Stage { Genesis, Evolved, Ancient, Singularity }
    
    uint64 public mintTime;
    uint64 public lastRefresh;
    uint64 private _cachedCycle;
    Stage private _cachedStage;
    bool public isMinted; 

    uint256 public constant CONSCIOUSNESS_ID = 0;
    uint256 public constant MAX_SUPPLY = 1;

    uint256[45] private __gap;

    error SupplyExhausted();
    error TokenNonexistent();
    error RefreshTooSoon();

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function mint() external {
        if (isMinted) revert SupplyExhausted(); 
        
        isMinted = true;
        mintTime = uint64(block.timestamp); 
        _cachedStage = Stage.Genesis;
        _cachedCycle = 1;

        _mint(msg.sender, CONSCIOUSNESS_ID, 1, "");
    }

    function _getStageAndCycle() internal view returns (Stage stage, uint64 cycle) {
        uint256 timeElapsed = block.timestamp - mintTime;
        
        cycle = uint64((timeElapsed / 28 days) + 1); 
        uint256 currentCycleTime = timeElapsed % 28 days;
        
        if (currentCycleTime < 7 days) {
            stage = Stage.Genesis;
        } else if (currentCycleTime < 14 days) {
            stage = Stage.Evolved;
        } else if (currentCycleTime < 21 days) {
            stage = Stage.Ancient;
        } else {
            stage = Stage.Singularity;
        }
    }

    function getStageAndCycle(uint256 tokenId) public view returns (string memory stageString, uint256 cycle) {
        if (tokenId != CONSCIOUSNESS_ID || !isMinted) revert TokenNonexistent(); 
        
        (Stage stage, uint64 cyc) = _getStageAndCycle();
        cycle = uint256(cyc);
        
        if (stage == Stage.Genesis) stageString = "Genesis";
        else if (stage == Stage.Evolved) stageString = "Evolved";
        else if (stage == Stage.Ancient) stageString = "Ancient";
        else stageString = "Singularity";
    }

    function refreshMetadata(uint256 tokenId) external {
        if (tokenId != CONSCIOUSNESS_ID || !isMinted) revert TokenNonexistent();
        
        if (block.timestamp - lastRefresh <= 1 hours) revert RefreshTooSoon();

        (Stage newStage, uint64 newCycle) = _getStageAndCycle();
        
        if (newStage == _cachedStage && newCycle == _cachedCycle) {
            return;
        }

        lastRefresh = uint64(block.timestamp);
        _cachedStage = newStage;
        _cachedCycle = newCycle;
        
        emit URI(_constructURI(newStage, newCycle), CONSCIOUSNESS_ID);
    }

    function generateSVG(Stage stage, uint64 cycle) internal pure returns (string memory) {
        string memory svgHeader = '<svg width="400" height="400" viewBox="0 0 400 400" xmlns="http://w3.org" style="background:#05050a;font-family:monospace;">'
            '<defs>'
                '<radialGradient id="bg" cx="50%" cy="50%" r="50%"><stop offset="0%" stop-color="#111126"/><stop offset="100%" stop-color="#05050a"/></radialGradient>'
                '<filter id="glow"><feGaussianBlur stdDeviation="3" result="coloredBlur"/><feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
            '</defs>'
            '<rect width="100%" height="100%" fill="url(#bg)"/>';

        string memory svgBody;

        if (stage == Stage.Genesis) {
            svgBody = '<g stroke="#3498db" stroke-width="1" fill="none" opacity="0.4">'
                '<circle cx="200" cy="180" r="40"/><circle cx="200" cy="180" r="70" stroke-dasharray="5,5"/>'
                '<circle cx="200" cy="180" r="100"/><circle cx="200" cy="180" r="130" stroke-dasharray="10,5"/>'
                '</g>'
                '<path d="M150 180 Q200 130 250 180 Q200 230 150 180 Z" fill="#3498db" opacity="0.2" filter="url(#glow)"/>'
                '<circle cx="200" cy="180" r="6" fill="#3498db" filter="url(#glow)"/>'
                '<text x="50%" y="340" font-size="14" fill="#3498db" text-anchor="middle" letter-spacing="2">STAGE 01 // GENESIS : RECEIVER</text>';
        } else if (stage == Stage.Evolved) {
            svgBody = '<g stroke="#9b59b6" stroke-width="1.5" fill="none">'
                '<path d="M120 220 L160 140 L240 140 L280 220" opacity="0.3"/><path d="M140 180 L260 180" stroke-dasharray="4,4"/>'
                '</g>'
                '<circle cx="160" cy="140" r="4" fill="#9b59b6" filter="url(#glow)"/><circle cx="240" cy="140" r="4" fill="#9b59b6" filter="url(#glow)"/>'
                '<g fill="#9b59b6" filter="url(#glow)"><circle cx="200" cy="100" r="3" opacity="0.8"/><circle cx="180" cy="80" r="2" opacity="0.6"/><circle cx="220" cy="70" r="2" opacity="0.5"/></g>'
                '<text x="50%" y="340" font-size="14" fill="#9b59b6" text-anchor="middle" letter-spacing="2">STAGE 02 // EVOLVED : DETACHED</text>';
        } else if (stage == Stage.Ancient) {
            svgBody = '<g stroke="#f1c40f" stroke-width="0.5" opacity="0.3"><path d="M50 50 L350 350 M50 350 L350 5"/><circle cx="200" cy="180" r="90"/></g>'
                '<g fill="#f1c40f" filter="url(#glow)"><rect x="195" y="90" width="10" height="180" opacity="0.3"/>'
                '<circle cx="200" cy="180" r="15"/><circle cx="110" cy="90" r="5"/><circle cx="290" cy="90" r="5"/><circle cx="110" cy="270" r="5"/><circle cx="290" cy="270" r="5"/></g>'
                '<text x="50%" y="340" font-size="14" fill="#f1c40f" text-anchor="middle" letter-spacing="2">STAGE 03 // ANCIENT : IMPRINT</text>';
        } else {
            svgBody = '<g stroke="#00f2fe" stroke-width="1.5" fill="none" filter="url(#glow)">'
                '<polygon points="200,110 260,140 200,170 140,140"/><polygon points="140,140 200,170 200,240 140,210"/><polygon points="260,140 200,170 200,240 260,210"/>'
                '</g>'
                '<circle cx="200" cy="170" r="2" fill="#ffffff" filter="url(#glow)"/>'
                '<text x="50%" y="340" font-size="14" fill="#00f2fe" text-anchor="middle" letter-spacing="2">STAGE 04 // SINGULARITY : ON-CHAIN</text>';
        }

        string memory svgFooter = string(abi.encodePacked(
            '<text x="50%" y="370" font-size="10" fill="#666677" text-anchor="middle" letter-spacing="1">CONSCIOUSNESS CYCLE: #', uint256(cycle).toString(), '</text>'
            '</svg>'
        ));

        return string(abi.encodePacked(svgHeader, svgBody, svgFooter));
    }

    function _constructURI(Stage stage, uint64 cycle) internal pure returns (string memory) {
        string memory stageString;
        if (stage == Stage.Genesis) stageString = "Genesis";
        else if (stage == Stage.Evolved) stageString = "Evolved";
        else if (stage == Stage.Ancient) stageString = "Ancient";
        else stageString = "Singularity";

        string memory svg = generateSVG(stage, cycle);

        string memory json = string(
            abi.encodePacked(
                '{"name": "Consciousness Exp #0",', 
                '"description": "Exploration dynamique de la conscience on-chain sous format ERC-1155.",',
                '"attributes": [',
                    '{"trait_type": "Stade de Conscience", "value": "', stageString, '"},',
                    '{"trait_type": "Numero de Cycle", "value": ', uint256(cycle).toString(), '}',
                '],',
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (tokenId != CONSCIOUSNESS_ID || !isMinted) revert TokenNonexistent(); 
        
        (Stage stage, uint64 cycle) = _getStageAndCycle();
        return _constructURI(stage, cycle);
    }
}
