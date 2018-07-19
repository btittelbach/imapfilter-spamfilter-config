---------------
--  Options  --
---------------

options.timeout = 60
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

-- Spam Training from a special folder "SpamTrain" where the user can drop spam to be learned
-- spamtrain_folder = mailaccount1.SpamTrain
-- spamtrained_folder = mailaccount1.Trash

---------------
--  Filters  --
---------------

-- The simplest filter that is possible. Matches all messages in the mailbox.
all = {}

-- neu doesn't really work, since recent can be unset before we connect ?
neu = {
	'unseen',
--	'recent',
}

tobespamscanned = function(mailbox)
	return mailbox:is_unseen() * mailbox:is_newer(4) * mailbox:is_smaller(250000) - mailbox:has_flag('spam-scanned')
	end

train_as_ham_filter =	function (mailbox)
	return mailbox:is_newer(30) * mailbox:is_smaller(250000) * mailbox:is_undeleted() * mailbox:has_flag('NonJunk') - mailbox:has_flag('spamlearned')
	end
-- the smaller is needed because if the msg is larger 250kb, spamc will break the pipe which will kill imapfilter

train_as_spam_filter =  function(mailbox)
	return mailbox:is_newer(30) * mailbox:is_smaller(250000) * mailbox:is_undeleted() * mailbox:has_flag('Junk') - mailbox:has_flag('spamlearned')
	end


-- Spam Training
function train_as_ham(mailbox)
	local results = train_as_ham_filter(mailbox)
	local text = mailbox:fetch_message(results)
	if text ~= nil then
	    for msgid, msgtxt in pairs(text) do
		pipe_to('hamclearn.sh', msgtxt)
	    end
	end
	mailbox:add_flags({'spamlearned'}, results)
end

function train_as_spam(mailbox, trash, spambox)
	local results = train_as_spam_filter(mailbox)
	local text = mailbox:fetch_message(results)
	local justlearned = {}
	local alreadylearned = {}
	if text ~= nil then
	    for msgid, msgtxt in pairs(text) do
		--print(string.format("spam: %d",msgid))
		if (pipe_to('~/spamclearn.sh', msgtxt) == 5) then
		    table.insert(justlearned, {mailbox, msgid})
		else
		    table.insert(alreadylearned, {mailbox, msgid})
		end
	    end
	end
	mailbox:add_flags({'spamlearned'}, results)
	mailbox:mark_seen(results)
	mailbox:move_messages(spambox,justlearned)
	mailbox:move_messages(trash,alreadylearned)
end
	
--SpamScan
function spamscan(mailbox,trash)
	local results = tobespamscanned(mailbox) 
	if results == nil then
		print(string.format("Error connecting "));
		return
	end
	local text = mailbox:fetch_message(results)
	if text ~= nil then
		local isspam = {}
		local nospam = {}
		for msgid, msgtxt in pairs(text) do
			--print(string.format("Checking %s@%s, MsgId %d for Spam", folder, servercomment, msgid))
			if (pipe_to('spamc -c', msgtxt) == 1) then
				table.insert(isspam, {mailbox,msgid})
				--print(string.format("spam: %d",msgid))
			else
				table.insert(nospam, {mailbox,msgid})
				--print(string.format("nospam: %d",msgid))
			end
		end
		mailbox:add_flags({'spam-scanned'},results)
		mailbox:add_flags({'Junk'},isspam)
		mailbox:move_messages(trash,isspam)
	end
end


--
----------------
--  Commands  --
----------------

-- Spam Training from a special folder where the user can drop spam to be learned

if spamtrain_folder ~= nil then
	local spamtrain_smaller = spamtrain_folder:is_undeleted() * spamtrain_folder:is_smaller(250000)
	local spamtrain_larger =  spamtrain_folder:is_undeleted() * spamtrain_folder:is_larger(249999)
	spamtrain_folder:delete_messages(spamtrain_larger)
	local text = spamtrain_folder:fetch_message(spamtrain_smaller)
	local results = {}
	local alreadylearned = {}
	print('Training SpamFilter with Messages in .SpamTrain')
	if text ~= nil then
	    for msgid, msgtxt in pairs(text) do
	        if (pipe_to('~/spamclearn.sh', msgtxt) == 5) then
	            --print('into results:',msgid)
	            table.insert(results, {spamtrain_folder,msgid})
	        else
	            --print('into alreadylearned:',msgid)
	            table.insert(alreadylearned, {spamtrain_folder,msgid})
	        end
	    end
	end
	--local results_set=Set(results)
	spamtrain_folder:mark_seen(results)
	spamtrain_folder:move_messages(spamtrained_folder,results)
	spamtrain_folder:delete_messages(alreadylearned)
	results = {}
	alreadylearned = {}
	print("done")
end

print("Training SpamFilter with Junk/NonJunk Flags from Thunderbird/AppleMail")
for acid, account in pairs(accounts_to_check) do
  --print(string.format('In Account %d',acid))
  mailboxes, folders = account:list_subscribed("")
  --mailboxes is nil if connection can't be established
  if mailboxes ~= nil then
    table.insert(mailboxes,"INBOX")
    for mid, mailbox in pairs(mailboxes) do
      if (mailbox ~= "Trash" and mailbox ~= "Sent Mail" and mailbox ~= "Sent" and mailbox ~= "Sent Messages" and mailbox ~= "Drafts" and mailbox ~= "Templates" and mailbox ~= "SpamTrain" and mailbox ~= "SpamTrain/Trained" and mailbox ~= "Junk" and mailbox ~= "spam" and mailbox ~= "Spam") then
        if (mailbox ~= "Trash") then
          --print(string.format('Training Ham with Messages in %s',mailbox))
          train_as_ham(account[mailbox])
        end
        if (mailbox ~= "Spam") then
          --print(string.format('Training Spam with Messages in %s',mailbox))
          train_as_spam(account[mailbox],account.Trash,account.Spam)
        end
      end
    end
  end
end
print("done")


print("Scanning for Spam")
for acid, account in pairs(accounts_to_check) do
	spamscan(account,account.Spam)
end
