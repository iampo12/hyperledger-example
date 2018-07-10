const FabricCAServices = require('fabric-ca-client')
const FabricClient = require('fabric-client')
const path = require('path')

const clientCA = new FabricCAServices('http://localhost:7054')
const client = new FabricClient()
const store_path = path.join(__dirname, 'hfc-key-store')

const user = {
	enrollmentID: 'por',
	enrollmentSecret: 'test123',
	affiliation: 'por.department1',
	role: 'client'
}

console.log('------------------------------------------------')
console.log(clientCA.toString())
console.log('------------------------------------------------')

const register = async () => {
	console.log('------------------------------------------------')
  console.log('Register user');
  console.log('------------------------------------------------')
	// Set state store
  const stateStore = await FabricClient.newDefaultKeyValueStore({ path: store_path })
  client.setStateStore(stateStore)
	// Get admin user
  const adminUser = await client.getUserContext('admin', true)
	if (!adminUser.isEnrolled()) {
		throw new Error
	}
	// Register user: por, affiliation: por.department1, role: client By admin
	try {
		await clientCA.register(user, adminUser)
		console.log('> Successfully registered')
		console.log('> User : ', user.enrollmentID)
	} catch (e) {
		console.log(e.message)
	}
	
}

register()
