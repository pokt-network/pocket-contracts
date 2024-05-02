const {NETWORKS} = require('./_networks.js');

exports.evmChainIds = {
    // Mainnets
    MAINNET: {
        ethereum: NETWORKS.MAINNET.ethereum.chain_id,
        bsc: NETWORKS.MAINNET.bsc.chain_id,
        polygon: NETWORKS.MAINNET.polygon.chain_id,
        avalanche: NETWORKS.MAINNET.avalanche.chain_id,
        // oasis: NETWORKS.MAINNET.oasis.chain_id,
        // aurora: NETWORKS.MAINNET.aurora.chain_id,
        fantom: NETWORKS.MAINNET.fantom.chain_id,
        karura: NETWORKS.MAINNET.karura.chain_id,
        acala: NETWORKS.MAINNET.acala.chain_id,
        klaytn: NETWORKS.MAINNET.klaytn.chain_id,
        celo: NETWORKS.MAINNET.celo.chain_id,
        moonbeam: NETWORKS.MAINNET.moonbeam.chain_id,
        // neon: NETWORKS.MAINNET.neon.chain_id,
        arbitrum: NETWORKS.MAINNET.arbitrum.chain_id,
        optimism: NETWORKS.MAINNET.optimism.chain_id,
        // gnosis: NETWORKS.MAINNET.gnosis.chain_id,
        base: NETWORKS.MAINNET.base.chain_id,
        // rootstock: NETWORKS.MAINNET.rootstock.chain_id,
        // scroll: NETWORKS.MAINNET.scroll.chain_id,
        // mantle: NETWORKS.MAINNET.mantle.chain_id,
        // blast: NETWORKS.MAINNET.blast.chain_id,
        // xlayer: NETWORKS.MAINNET.xlayer.chain_id,
        // linea: NETWORKS.MAINNET.linea.chain_id,
        // berachain: NETWORKS.MAINNET.berachain.chain_id,
        // seievm: NETWORKS.MAINNET.seievm.chain_id,
    },

    TESTNET: {
        // Testnets
        sepolia: NETWORKS.TESTNET.sepolia.chain_id,
        arbitrum_sepolia: NETWORKS.TESTNET.arbitrum_sepolia.chain_id,
        base_sepolia: NETWORKS.TESTNET.base_sepolia.chain_id,
        optimism_sepolia: NETWORKS.TESTNET.optimism_sepolia.chain_id,
        // holesky: NETWORKS.TESTNET.holesky.chain_id,
        // polygon_sepolia: NETWORKS.TESTNET.polygon_sepolia.chain_id,
    },
};
