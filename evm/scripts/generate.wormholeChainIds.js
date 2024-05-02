const fs = require('fs/promises');
const _ = require('lodash');

const testnets = [
    {name: 'baseSepolia', wormholeChainId: 10004, chainId: 84532},
    {name: 'sepolia', wormholeChainId: 10002, chainId: 11155111},
    {name: 'arbitrumSepolia', wormholeChainId: 10003, chainId: 421614},
    {name: 'optimismSepolia', wormholeChainId: 10005, chainId: 11155420},
    // {name: 'holesky', wormholeChainId: 10006, chainId: 17000},
    // {name: 'polygonSepolia', wormholeChainId: 10007, chainId: 80002},
];

const mainnets = [];

const testnetsHeader = testnets
    .map(({name, wormholeChainId, chainId}) => {
        return (
            `    /// ------------ ${_.startCase(name)} ------------\n` +
            `   uint256 public constant ${name}ChainId = ${chainId};\n` +
            `   uint16 public constant ${name}WormholeChainId = ${wormholeChainId};\n`
        );
    })
    .join('\n\r');

const testnetsConstructor = testnets
    .map(({name}) => {
        const l = testnets.length - 1;
        let i = 0;

        let str = `        uint16[] memory ${name}Targets = new uint16[](${l});\n`;

        for (const {name: n} of testnets) {
            if (n === name) {
                continue;
            }

            str += `        ${name}Targets[${i}] = ${n}WormholeChainId;\n`;
            i++;
        }

        return (
            str +
            `        chainIdToWormHoleIds[${name}ChainId] = ${name}Targets;`
        );
    })
    .join('\n\r');

const mainnetsHeader = mainnets
    .map(({name, wormholeChainId, chainId}) => {
        return (
            `    /// ------------ ${_.startCase(name)} ------------\n` +
            `   uint256 public constant ${name}ChainId = ${chainId};\n` +
            `   uint16 public constant ${name}WormholeChainId = ${wormholeChainId};\n`
        );
    })
    .join('\n\r');

const mainnetsConstructor = mainnets
    .map(({name}) => {
        const l = testnets.length - 1;
        let i = 0;

        let str = `        uint16[] memory ${name}Targets = new uint16[](${l});\n`;

        for (const {name: n} of testnets) {
            if (n === name) {
                continue;
            }

            str += `        ${name}Targets[${i}] = ${n}WormholeChainId;\n`;
            i++;
        }

        return (
            str +
            `        chainIdToWormHoleIds[${name}ChainId] = ${name}Targets;`
        );
    })
    .join('\n\r');

const contents = `//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

/// DO NOT EDIT THIS FILE MANUALLY!
/// use scripts node scripts/generate.wormholeChainIds.js to generate this file
contract WormholeChainIds {
${testnetsHeader}

${mainnetsHeader}


    /// @notice map a sending chain id to a wormhole chain ids
    mapping(uint256 => uint16[]) public chainIdToWormHoleIds;

    constructor() {
        /// ------------ TESTNETS ------------
${testnetsConstructor}

        /// ------------ MAINNETS ------------

${mainnetsConstructor}
    }
}

`;

(async () => {
    await fs.mkdir('generated', {recursive: true});

    await fs.writeFile('generated/WormholeChainIds.sol', contents);
})();
