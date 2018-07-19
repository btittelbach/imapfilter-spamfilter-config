---------------
--  Options  --
---------------

options.timeout = 120
options.close = true
options.subscribe = true
options.starttls = false
options.uid = true
options.info = true
----------------
--  Accounts  --
----------------

mailaccount1 = IMAP {
	server = 'localhost',
	username = 'username',
	password = 'password',
}

mailaccount2 = IMAP {
	server = 'localhost',
	username = 'username',
	password = 'password',
}

accounts_to_check={mailaccount1,mailaccount2}

---------------
--  Filters  --
---------------


function mark_all_seen(account)
	mailboxes, folders = account:list_subscribed("")
	table.insert(mailboxes,"INBOX")
	for mid, mailboxstring in pairs(mailboxes) do
		local mailbox=account[mailboxstring]
		local result = mailbox:is_unseen()
		mailbox:mark_seen(result)
	end
end

for acid, account in pairs(accounts_to_check) do
	mark_all_seen(account)
end
