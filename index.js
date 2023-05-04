const { ImapFlow } = require('imapflow');
const pino = require('pino');
const logger = pino({ level: process.env.LOG_LEVEL || 'fatal' })
const fs = require('fs/promises')

const client = new ImapFlow({
  host: 'imap.fastmail.com',
  port: 993,
  auth: {
    user: process.env.FASTMAIL_USER,
    pass: process.env.FASTMAIL_PASSWORD
  },
  logger
});

const main = async () => {
  await client.connect();

  const mailboxes = (await client.list({ statusQuery: { messages: true, unseen: true } }))
    .filter(mailbox => mailbox.name.startsWith('#') || mailbox.name === 'INBOX')

  const stats = mailboxes.map(mailbox =>
  ({
    name: mailbox.name,
    messages: mailbox.status.messages,
    unseen: mailbox.status.unseen
  }))

  const totals = stats.reduce((totals, 
    stat) => ({ 
      unseen: totals.unseen + stat.unseen, 
      messages: totals.messages + stat.messages }), 
      { unseen: 0, messages: 0 }
  )

  const data = {
    date: new Date(),
    totals,
    mailboxes: stats
  }
  console.log(data)
  const path = __dirname + '/data/'
  await fs.appendFile(path + "stats.ndjson", JSON.stringify(data) + "\n")

  // client.on('exists', (e) => {
  //     console.log('exists!', e)
  // })
  // client.on('expunge', (e) => {
  //     console.log('deleted!', e)
  // })
  // await client.idle()
  // for await (let message of client.fetch('1:*', { envelope: true, threadId: true, headers: true })) {
  //     console.log(message.threadId)
  //     console.log(message.headers.toString())
  //     console.log(`${message.uid}: ${message.envelope.subject}`);
  // }

  // // Select and lock a mailbox. Throws if mailbox does not exist
  // console.log('opening inbox...')
  // let lock = await client.getMailboxLock('INBOX');
  // try {
  //     // fetch latest message source
  //     // client.mailbox includes information about currently selected mailbox
  //     // "exists" value is also the largest sequence number available in the mailbox
  //     let message = await client.fetchOne(client.mailbox.exists, { source: true });
  //     // console.log(message.source.toString());

  //     // list subjects for all messages
  //     // uid value is always included in FETCH response, envelope strings are in unicode.
  //     for await (let message of client.fetch('1:*', { envelope: true })) {
  //         console.log(`${message.uid}: ${message.envelope.subject}`);
  //     }
  // } finally {
  //     // Make sure lock is released, otherwise next `getMailboxLock()` never returns
  //     lock.release();
  // }

  await client.logout();
};

main().catch(err => { console.error(err) && exit(1) });
