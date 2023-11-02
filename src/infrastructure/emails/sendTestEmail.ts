import Debug from "debug"
import nodemailer from "nodemailer"
import { Email } from "../../core"

export async function sendTestEmail(email: Email) {
  const debug = Debug("email-tools:sendTestEmail")
  debug(email)
  const pass = process.env.FASTMAIL_SMTP_PASSWORD
  if (!pass) throw new Error("please set FASTMAIL_SMTP_PASSWORD")
  const smtp = nodemailer.createTransport({
    host: "smtp.fastmail.com",
    port: 465,
    secure: true,
    auth: {
      user: "test@levain.codes",
      pass,
    },
  })
  await smtp.sendMail({
    to: "test@levain.codes",
    from: email.from.value,
    subject: email.subject.value,
  })
}
