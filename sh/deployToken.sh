source .env

forge script ./script/MockToken.s.sol:DeployMockToken --rpc-url ${RPC_GOERLI_URL} --private-key ${PRIVATE_KEY} --broadcast --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv