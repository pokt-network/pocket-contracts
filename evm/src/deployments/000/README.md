# Initial Deployment

# Deploy Safe

```sh
DEBUG=true forge script src/deployments/000/DeploySafe.sol:DeploySafe --chain sepolia --fork-url sepolia
```

## Proxy Admin

Deploys upgradable proxy that is owned by multisig.

```sh
DEBUG=true forge script src/deployments/000/DeployProxyAdmin.sol:DeployProxyAdmin --chain sepolia --fork-url sepolia
```

## XPokt With WPOKT Lockbox

Deploys XERC20 token on the main chain (Ethereum), allows to lock WPOKT<>XPOKT
and bridge WPOKT directly using Router contract.

```sh


DEBUG=true forge script src/deployments/000/DeployXPoktWithLockbox.sol:DeployXPoktWithLockbox --chain sepolia --fork-url sepolia --account FRESH_EOA --broadcast
```

## XPokt without WPOKT

This should be deployed across the rest of EVM chains.

```sh
DEBUG=true forge script src/deployments/000/DeployXPokt.sol:DeployXPokt --chain-id 84532 --fork-url baseSepolia --account FRESH_EOA --broadcast
```

## WPOKT Router

```sh
DEBUG=true forge script src/deployments/000/DeployWPoktRouter.sol:DeployWPoktRouter --chain sepolia --fork-url sepolia --account DEPLOYER_EOA --broadcast
```
