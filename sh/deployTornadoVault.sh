source .env

forge script ./script/TornadoVault.s.sol:DeployTornadoVault --rpc-url ${RPC_GOERLI_URL} --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv