
const { Wechaty } = require('wechaty')
const vorpal = require('vorpal')()

function onScan (qrcode, status) {
  require('qrcode-terminal').generate(qrcode, { small: true })  // show qrcode on console

  const qrcodeImageUrl = [
    'https://api.qrserver.com/v1/create-qr-code/?data=',
    encodeURIComponent(qrcode),
  ].join('')

  console.log(qrcodeImageUrl)
}

function onLogin (user) {
  console.log(`${user} login`)
}

function onLogout(user) {
  console.log(`${user} logout`)
}

async function onMessage (msg) {
  console.log(msg.toString())
}

const bot = new Wechaty()

bot.on('scan',    onScan)
bot.on('login',   onLogin)
bot.on('logout',  onLogout)
bot.on('message', onMessage)

bot.start()
  .then(() => console.log('Starter Bot Started.'))
  .catch(e => console.error(e))

//-------------------------------------------------

var curDir = '/'

vorpal
  .command('lsroom', 'list the current items')
  .action( (args, callback) => {
	  bot.Room.findAll().then(list=>{
	      list.forEach( item => {
		  let topic = item.payload.topic
		  topic && console.log(item.payload.topic)
	      })
	      callback()
	  })
  })

vorpal
  .command('lscontact', 'list the current items')
  .action( (args, callback) => {
	  bot.Contact.findAll().then(list=>{
	      list.forEach( item => {
		  let label = item.payload.name
		  item.payload.signature && (label = label + ' -- [' + item.payload.signature + ']')
		  console.log(label)
	      })
	      callback()
	  })
  })

vorpal
  .command('lsmessage', 'list the current items')
  .action( (args, callback) => {
	  bot.Message.findAll().then(list=>{
	      list.forEach( item => {
		  console.log(item.payload.text)
	      })
	     callback()
	  })
  })

vorpal
  .delimiter('wechat$')
  .show();

