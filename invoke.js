const FabricClient = require('fabric-client')
const path = require('path')

const client = new FabricClient()
const store_path = path.join(__dirname, 'hfc-key-store')
const user = {
	enrollmentID: 'por'
}

const invoke = async () => {
  const channel = client.newChannel('mychannel')
	const peer = client.newPeer('grpc://localhost:7051')
	channel.addPeer(peer)
  var order = client.newOrderer('grpc://localhost:7050')
  channel.addOrderer(order)

  const stateStore = await FabricClient.newDefaultKeyValueStore({ path: store_path })
  client.setStateStore(stateStore)
	const userContext = await client.getUserContext(user.enrollmentID, true)
	if (!userContext.isEnrolled()) {
		throw new Error
	}

  tx_id = client.newTransactionID();
	console.log("Assigning transaction_id: ", tx_id._transaction_id)

  var request = {
		chaincodeId: 'sacc',
		fcn: 'set',
		args: ['a', '30'],
		chainId: 'mychannel',
		txId: tx_id
	}
  // Send transaction proposal
  const results = await channel.sendTransactionProposal(request)
  const proposalResponses = results[0]
  const proposal = results[1]
  let isProposalGood = false

  if (proposalResponses[0].response.status === 200) {
    isProposalGood = true
    console.log('Transaction proposal was good')
	} else {
    console.error('Transaction proposal was bad')
	}

  if(isProposalGood){
    console.log(proposalResponses[0].response.status, proposalResponses[0].response.message)

    const request = {
			proposalResponses: proposalResponses,
			proposal: proposal
		}

    const transaction_id_string = tx_id.getTransactionID()
    // Send transaction
		const sendPromise = await channel.sendTransaction(request)

    const event_hub = client.newEventHub()
		event_hub.setPeerAddr('grpc://localhost:7053')
    // Connect event hub
    event_hub.connect()
    console.log('Register transaction event')
    // Register transaction event
    const regisHub = event_hub.registerTxEvent(transaction_id_string, (tx, code) => {
				// clearTimeout(handle) ??
        
        console.log(tx, code)
        event_hub.unregisterTxEvent(transaction_id_string)
        event_hub.disconnect()
        console.log('Event disconnect')
			}, (err) => {
        console.error(err)
			})
  }
}

invoke()