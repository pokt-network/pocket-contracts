# Testnet scripts

```sh
DEBUG=true forge script scripts/testnet/SendWPoktToBase.sol:SendWPoktToBase
--chain sepolia --fork-url sepolia

DEBUG=true forge script
scripts/testnet/SendPoktToArbitrum.sol:SendPoktToArbitrum --chain sepolia
--fork-url sepolia

DEBUG=true forge script scripts/testnet/MintPoktFromWPokt.sol:SendPoktToArbitrum
--chain sepolia --fork-url sepolia
```
