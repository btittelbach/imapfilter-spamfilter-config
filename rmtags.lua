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


function clear_all_flags(account)
	mailboxes, folders = account:list_subscribed("")
	table.insert(mailboxes,"INBOX")
	for mid, mailboxstring in pairs(mailboxes) do
		local mailbox=account[mailboxstring]
		local result = mailbox:has_flag("spam") + mailbox:has_flag("isspam") + mailbox:has_flag("isham") + mailbox:has_flag("ham") + mailbox:has_flag("spam-learned")  + mailbox:has_flag("$Junk") + mailbox:has_flag("$NotJunk") + mailbox:has_flag("$notjunk") + mailbox:has_flag("nonjunk") + mailbox:has_flag("JunkRecorded") + mailbox:has_flag('Junk') + mailbox:has_flag('NonJunk')
		mailbox:remove_flags({'spam','isspam','isham','ham','spam-learned','$Junk','$NotJunk','$notjunk','nonjunk','JunkRecorded','NonJunk','Junk'},result)
	end
end

for acid, account in pairs(accounts_to_check) do
	clear_all_flags(account)
end
