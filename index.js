
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
	console.log(msg.toString());
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

var curDir = '/';
var curTarget = null;

vorpal
  .command('say <text>', 'say something in room|contact|message')
  .action((args, callback) => {
	  if (curTarget) {
		  curTarget.say(args.text);
	  }
	  callback();
  });

vorpal
  .command('select [target]', 'select (room|contact|message) target to say something.')
  .action( (args, callback) => {
	console.log(args);
	bot.Contact.find({name: args.target}).then(contact=>{
		if (contact) {
			curTarget = contact;
			callback();
			return;
		}

		bot.Room.find({topic: args.target}).then(room=>{
			if (room) {
				curTarget = room;
			}
			callback();
		},
		err=>{
			console.log(err);
			callback();
		});
	},
	err=>{
		console.log(err);
		callback();
	});
  });

vorpal
  .command('show', 'show (room|contact|message) informations')
  .option('-r, --room [name]', 'List all rooms')
  .option('-c, --contact [name]', 'List all contact')
  .option('-m, --message', 'List all message unread')
  .action( (args, callback) => {
	console.log(args);
	if (args.options.room) {
		bot.Room.findAll().then(list=>{
			list.forEach( item => {
				let topic = item.payload.topic;
				if (!topic) return;

				if (args.options.room.length > 0) {
					let patt = new RegExp(args.options.room, 'g');
					if (patt.test(topic)) {
						console.log(topic);
					}
				} else {
					console.log(item.payload.topic);
				}
			});
			callback();
		}, err=>{
			console.log(err);
			callback();
		});
	}

	if (args.options.contact) {
		bot.Contact.findAll().then(list=>{
			list.forEach( item => {
				let label = item.payload.name;
				let signature = text_truncate(item.payload.signature, 25, '!!');
				item.payload.signature && (label = label + ' -- [' + signature + ']')

				if (args.options.contact.length > 0) {
					let patt = new RegExp(args.options.contact, 'g');
					if (patt.test(item.payload.name + item.payload.signature)) {
						console.log(label)
					}
				} else {
					console.log(label);
				}
			});
			callback();
		}, err=>{
			console.log(err);
			callback();
		});
	}

	if (args.options.message) {
		bot.Message.findAll().then(list=>{
			list.forEach( item => {
				//console.log(removeCDATA(item.payload.text));
				console.log(msg.toString());
			});
			callback();
		}, err=>{
			console.log(err);
			callback();
		});
	}

  });


vorpal
  .delimiter('wechat$')
  .show();


function text_truncate(str,n,symb) {
	return (!n && !symb)? str:(n && !symb)?str.slice(0,n)+"...":str.slice(0,n-symb.length)+symb;
}

function removeCDATA(str) {
    var pattern = new RegExp(/\<!\[CDATA\[.*?\/>(.*?)\]\]\>/);
    var res = pattern.exec(str)[1];
    return res;
}

