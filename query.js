const FabricClient = require('fabric-client')
const path = require('path')

const client = new FabricClient()
const store_path = path.join(__dirname, 'hfc-key-store')
const user = {
	enrollmentID: 'admin'
}

const query = async () => {
	// Set fabric network
	const channel = client.newChannel('mychannel')
	const peer = client.newPeer('grpc://localhost:7051')
	channel.addPeer(peer)

	// Set state store
  const stateStore = await FabricClient.newDefaultKeyValueStore({ path: store_path })
  client.setStateStore(stateStore)
	const userContext = await client.getUserContext(user.enrollmentID, true)
	if (!userContext.isEnrolled()) {
		throw new Error
	}

	const request = {
		chaincodeId: 'sacc',
		fnc:'get',
		args: ['a']
	}

	// send the query proposal to the peer
	const result = await channel.queryByChaincode(request)
	console.log(`a = ${result.toString()}`)

}

query()

