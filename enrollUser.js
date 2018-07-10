const FabricCAServices = require('fabric-ca-client')
const FabricClient = require('fabric-client')
const path = require('path')

const clientCA = new FabricCAServices('http://localhost:7054')
const client = new FabricClient()
const store_path = path.join(__dirname, 'hfc-key-store');
const user = {
  enrollmentID: 'admin',
  enrollmentSecret: 'adminpw',
  mspid: 'PorMSP'
}
// const user = {
// 	enrollmentID: 'por',
// 	enrollmentSecret: 'test123',
//   mspid: 'PorMSP'
// }

console.log('------------------------------------------------')
console.log(clientCA.toString())
console.log('------------------------------------------------')

const enroll = async () => {
  console.log('------------------------------------------------')
  console.log('Enroll');
  console.log('------------------------------------------------')
  // Set state store
  const stateStore = await FabricClient.newDefaultKeyValueStore({ path: store_path })
  client.setStateStore(stateStore)
  // const crypto_suite = FabricClient.newCryptoSuite();
	// const crypto_store = FabricClient.newCryptoKeyStore({path: store_path})
	// crypto_suite.setCryptoKeyStore(crypto_store)
	// client.setCryptoSuite(crypto_suite)

  // Enroll
  try {
    const enrollment = await clientCA.enroll(user)
    console.log('> Successfully enrolled')
    // Create user key store
    const userStore = await client.createUser({
      username: user.enrollmentID,
      mspid: user.mspid,
      cryptoContent: {
        privateKeyPEM: enrollment.key.toBytes(),
        signedCertPEM: enrollment.certificate
      }
    })
    // Set user context
    const userContext = await client.setUserContext(userStore)
    console.log('> User :', userContext._name)
  } catch (e) {
    console.log(e.message)
  }

}

enroll()
