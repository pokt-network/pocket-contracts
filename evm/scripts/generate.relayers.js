const fs = require('fs/promises');
const _ = require('lodash');
const {
    getWormholeRelayerAddress,
} = require('@certusone/wormhole-sdk/lib/cjs/relayer/consts');
const {evmChainIds} = require('./networks');

const {orderObjectKeys} = require('./orderObjectKeys');

// fix Error [ERR_UNSUPPORTED_DIR_IMPORT]:

(async () => {
    const filename = 'addresses/Addresses.json';

    const jsonString = await fs.readFile(filename, 'utf8');

    const parsedData = JSON.parse(jsonString);

    const wormholeBridgeRelayersTestnet = Object.entries(
        evmChainIds.TESTNET,
    ).map(([network, chainId]) => {
        return {
            addr: getWormholeRelayerAddress(network, 'TESTNET'),
            chainId: chainId,
            name: 'WORMHOLE_BRIDGE_RELAYER',
            isContract: true,
        };
    });

    const wormholeBridgeRelayersMainnet = Object.entries(
        evmChainIds.MAINNET,
    ).map(([network, chainId]) => {
        return {
            addr: getWormholeRelayerAddress(network, 'MAINNET'),
            chainId: chainId,
            name: 'WORMHOLE_BRIDGE_RELAYER',
            isContract: true,
        };
    });

    const nextData = [
        ...parsedData,
        ...wormholeBridgeRelayersTestnet,
        ...wormholeBridgeRelayersMainnet,
    ];

    const uniqueData = _.uniqWith(nextData, _.isEqual);

    const orderedData = orderObjectKeys(uniqueData);

    console.log(JSON.stringify(orderedData, null, 2));

    await fs.writeFile(filename, JSON.stringify(orderedData, null, 2));
})();
