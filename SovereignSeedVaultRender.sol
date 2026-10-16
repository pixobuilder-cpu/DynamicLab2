// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SovereignSeedVaultRender {
    using Strings for uint256;

    // Étape 1 : Génération de l'en-tête et des dégradés SVG
    function _getSvgHeader(string memory statusColor) private pure returns (string memory) {
        return string.concat(
            '<svg xmlns="http://w3.org" viewBox="0 0 800 800" width="100%" height="100%">',
            '<defs>',
            '<radialGradient id="woodBg" cx="50%" cy="50%" r="70%"><stop offset="0%" stop-color="#4a3120"/><stop offset="100%" stop-color="#180e07"/></radialGradient>',
            '<linearGradient id="seedBase" x1="20%" y1="10%" x2="80%" y2="90%"><stop offset="0%" stop-color="#f5e6be"/><stop offset="100%" stop-color="', statusColor, '"/></linearGradient>',
            '</defs>'
        );
    }

    // Étape 2 : Génération de la forme géométrique (la graine) et des textes
    function _getSvgBody(string memory statusColor, string memory statusText) private pure returns (string memory) {
        return string.concat(
            '<rect width="100%" height="100%" fill="url(#woodBg)"/>',
            '<g transform="translate(400, 430) rotate(-6)">',
            '<path d="M -125,5 C -130,-40 -65,-80 5,-72 C 60,-65 105,-38 132,-12 C 140,-3 140,3 132,10 C 105,32 55,65 -5,65 C -70,65 -115,38 -125,5 Z" fill="url(#seedBase)"/>',
            '</g>',
            '<text x="40" y="60" fill="', statusColor, '" font-family="monospace" font-size="22">SSV STATUS: ', statusText, '</text>',
            '</svg>'
        );
    }

    // Fonction principale appelée par le contrat ERC-721
    function generateURI(uint256 tokenId, bool isUnlocked) external pure returns (string memory) {
        string memory statusColor = isUnlocked ? "#00ffcc" : "#c3a372";
        string memory statusText = isUnlocked ? "UNLOCKED" : "SECURED (ZK)";

        // Concaténation des deux morceaux de SVG (propre et sans surcharge de pile)
        string memory fullSvg = string.concat(
            _getSvgHeader(statusColor),
            _getSvgBody(statusColor, statusText)
        );

        // Assemblage final des métadonnées JSON
        string memory jsonPayload = string.concat(
            '{"name": "Sovereign Seed Vault #', tokenId.toString(), 
            '", "description": "Vault anchored with Keccak-256 target hash and protected by ZK-SNARKs.", "image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(fullSvg)), '"}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(jsonPayload)));
    }
}
